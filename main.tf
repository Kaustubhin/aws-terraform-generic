locals {
  # yamldecode() also parses JSON (JSON is a valid YAML subset), so one
  # function handles both resources.yaml and resources.json.
  config = yamldecode(file("${path.module}/${var.config_file}"))

  # ---------------------------------------------------------------------
  # expand_block(block):
  #   - If a block has a `for_each` list, fan it out into one entry per
  #     item in that list — genuine Terraform for_each semantics, keyed
  #     by a value YOU choose (not a running count/index), e.g.
  #     for_each = [1,2,3] or for_each = ["blue","green"] — sharing every
  #     other attribute, with optional per-key tweaks via `overrides`
  #     (keyed by the same value as a string, e.g. overrides = { "3" = {...} }).
  #     Because the key comes from your list rather than position, adding
  #     or removing one entry only touches that one resource — nothing
  #     else gets renumbered, replaced, or recreated (the classic problem
  #     with `count` + list-index-based resources).
  #   - Otherwise, treat the block as a single fully-specified resource
  #     (must have its own `name`) and pass it through unchanged.
  #
  #   Implementation note: this always runs ONE for-loop over a list of
  #   keys, rather than a ternary that picks between two differently
  #   shaped lists ([for key in block.for_each : ...] vs [block]).
  #   Terraform statically infers a single type for both branches of a
  #   `? :` expression, so branching between a variable-length generated
  #   tuple and a fixed 1-element tuple fails with a "must have
  #   consistent types" error. Branching on a plain list of strings
  #   avoids that: both sides are list(string), which unify cleanly.
  # ---------------------------------------------------------------------
  ec2_expanded = flatten([
    for block in try(local.config.ec2_instances, []) : [
      for key in (
        contains(keys(block), "for_each") ?
        [for k in block.for_each : tostring(k)] :
        [tostring(block.name)]
      ) : merge(
        { for k, v in block : k => v if !contains(["for_each", "name_prefix", "overrides", "name"], k) },
        { name = contains(keys(block), "for_each") ? "${lookup(block, "name_prefix", "ec2")}-${key}" : block.name },
        lookup(try(block.overrides, {}), key, {})
      )
    ]
  ])

  s3_expanded = flatten([
    for block in try(local.config.s3_buckets, []) : [
      for key in (
        contains(keys(block), "for_each") ?
        [for k in block.for_each : tostring(k)] :
        [tostring(block.name)]
      ) : merge(
        { for k, v in block : k => v if !contains(["for_each", "name_prefix", "overrides", "name"], k) },
        { name = contains(keys(block), "for_each") ? "${lookup(block, "name_prefix", "bucket")}-${key}" : block.name },
        lookup(try(block.overrides, {}), key, {})
      )
    ]
  ])

  eks_expanded = flatten([
    for block in try(local.config.eks_clusters, []) : [
      for key in (
        contains(keys(block), "for_each") ?
        [for k in block.for_each : tostring(k)] :
        [tostring(block.name)]
      ) : merge(
        { for k, v in block : k => v if !contains(["for_each", "name_prefix", "overrides", "name"], k) },
        { name = contains(keys(block), "for_each") ? "${lookup(block, "name_prefix", "cluster")}-${key}" : block.name },
        lookup(try(block.overrides, {}), key, {})
      )
    ]
  ])

  ec2_instances = { for i in local.ec2_expanded : i.name => i }
  s3_buckets    = { for b in local.s3_expanded : b.name => b }
  eks_clusters  = { for e in local.eks_expanded : e.name => e }
}

module "ec2" {
  source    = "./modules/ec2"
  instances = local.ec2_instances
}

module "s3" {
  source  = "./modules/s3"
  buckets = local.s3_buckets
}

module "eks" {
  source   = "./modules/eks"
  clusters = local.eks_clusters
}
