# Generic Terraform Modules (EC2 / S3 / EKS) driven by YAML/JSON

Define however many EC2 instances, S3 buckets, and EKS clusters you want in
one data file (`resources.yaml` or `.json`). The root config decodes it and
fans it out to the modules with `for_each` — no copy-pasting `resource`
blocks per environment.

## How the modules work internally

Each module (`ec2`, `s3`, `eks`) takes **one map variable** — `instances`,
`buckets`, or `clusters` — keyed by resource name, and loops over it
internally with `for_each`. The root config's only job is to build that map
from your YAML/JSON file; it calls each module exactly once:

```hcl
module "ec2" {
  source    = "./modules/ec2"
  instances = local.ec2_instances     # map: "web-1" => { ami = ..., ... }
}
```

Inside `modules/ec2/main.tf`:

```hcl
resource "aws_instance" "this" {
  for_each = var.instances
  ami      = each.value.ami
  ...
  tags = merge(try(each.value.tags, {}), { Name = each.key })
}
```

This keeps the root config trivial (build data, call module once per
resource type) and keeps all the resource logic — defaults, encryption
settings, IMDSv2 enforcement, etc. — inside the module where it belongs.
Each module's outputs are maps too, e.g. `module.ec2.ids["web-1"]`.

## Layout

```
.
├── main.tf              # decodes config_file, builds maps, calls each module once
├── variables.tf          # aws_region, config_file
├── outputs.tf
├── providers.tf
├── resources.yaml         # <- your live config (edit this to add/remove resources)
├── resources.json         # same data as resources.yaml, JSON format
└── modules/
    ├── ec2/   (main.tf, variables.tf, outputs.tf)
    ├── s3/    (main.tf, variables.tf, outputs.tf)
    └── eks/   (main.tf, variables.tf, outputs.tf)
```

`yamldecode()` also parses JSON (JSON is a valid YAML subset), so the same
code path handles both formats — just point `config_file` at whichever one
you're using. `resources.yaml` and `resources.json` in this project hold
the same data in each format; pick one as your source of truth rather than
maintaining both by hand. Every field the modules don't strictly require is
wrapped in `try(..., default)`, so your config entries only need to set
what differs from the default — see each module's `variables.tf`
description for the full list of defaults.

## Usage

`resources.yaml` already contains your current environment (3 EC2 instances,
3 S3 buckets, 2 EKS clusters). Edit it directly to add/remove/change
resources, then:

```bash
terraform init
terraform plan
terraform apply
```

If you'd rather work from JSON, `resources.json` has the same data — point
`config_file` at it instead: `terraform apply -var="config_file=resources.json"`.

To target a different environment, keep a config file per env
(e.g. `envs/dev.yaml`, `envs/prod.yaml`) and pass it in:

```bash
terraform apply -var="config_file=envs/prod.yaml"
```

Or use separate `terraform workspace`s / backends per env, each pointing
at its own config file via a `.tfvars` file.

## Creating many similar resources at once (10 EC2, 15 S3, 3 EKS, ...)

Writing out 10 near-identical EC2 blocks by hand gets old fast. Instead,
give a block a `for_each` list — the keys you want, not a bare count — plus
a `name_prefix`; it expands into one resource per key, all sharing the same
attributes:

```yaml
ec2_instances:
  - name_prefix: web
    for_each: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]   # -> web-1 .. web-10
    ami: ami-0abcdef1234567890
    instance_type: t3.micro
    subnet_id: subnet-0123456789abcdef0
```

`for_each` keys don't have to be numbers — strings work too, which is
often clearer for a handful of named resources:

```yaml
eks_clusters:
  - name_prefix: cluster
    for_each: [dev, staging, prod]               # -> cluster-dev, cluster-staging, cluster-prod
    kubernetes_version: "1.29"
    ...
```

**Why keys instead of `count: N`:** with plain `count`, deleting or
reordering one item shifts every index after it, and Terraform proposes
destroying/recreating all of them. Here each generated resource is keyed by
the value you supplied (`web-3`, `cluster-prod`, ...) in a map, exactly like
using `for_each` directly on a `resource` block — so removing `web-3` from
the list only destroys `web-3`; `web-4` through `web-10` are untouched.

**Overriding specific instances:** most fan-outs need one or two exceptions
(a bigger instance size, an extra flag). Use `overrides`, keyed by the same
value as `for_each`, to merge extra attributes onto just that one instance:

```yaml
ec2_instances:
  - name_prefix: web
    for_each: [1, 2, 3]
    instance_type: t3.micro
    ami: ami-0abcdef1234567890
    subnet_id: subnet-0123456789abcdef0
    overrides:
      "3":
        instance_type: t3.large   # web-3 only; web-1 and web-2 stay t3.micro
```

You can freely mix fan-out blocks and single explicit blocks (with their own
`name`) in the same list.

## Adding a resource

- **Fan-out block:** just add another key to its `for_each` list.
- **One-off block:** append an entry with its own `name` under the right
  top-level key.

Either way, no `.tf` changes needed — just re-run `terraform plan`.

## Removing a resource

- **Fan-out block:** remove that key from the `for_each` list (and its
  `overrides` entry, if any).
- **One-off block:** delete its entry from the file.

Because every generated resource is keyed by name in a map, Terraform plans
a destroy for just that one resource — nothing else in the block gets
renumbered or recreated.

## Extending to another resource type (e.g. RDS, ALB)

1. Add a `modules/<type>/` folder whose `main.tf` takes one map variable
   (e.g. `var.<type>s`) and loops over it with `for_each`, the same way
   `modules/ec2`, `modules/s3`, and `modules/eks` do.
2. Add a `<type>s: [...]` block to the YAML schema (with optional
   `for_each`/`name_prefix`/`overrides` support if you want fan-out there too).
3. In root `main.tf`, add an `expanded`/keyed-map local for it (copy the
   `ec2_expanded` pattern) and a single `module "<type>" { source = "./modules/<type>"; <type>s = local.<type>s }` call.

## Notes / things to adapt before production use

- The EC2 and EKS modules assume the security groups, subnets, and IAM
  roles they reference already exist (pass their IDs/ARNs in via the
  config file) — network and IAM aren't provisioned here.
- S3 bucket names must be globally unique across all of AWS — the example
  file uses placeholder suffixes; change them.
- Consider a remote backend (S3 + DynamoDB lock table, or Terraform Cloud)
  once you're running this for real environments rather than local state.
- For secrets (DB passwords, etc.) don't put them in the YAML file in
  plaintext — reference AWS Secrets Manager/SSM ARNs instead and resolve
  them with a `data` source.
