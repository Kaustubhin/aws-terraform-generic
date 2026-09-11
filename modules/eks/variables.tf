variable "clusters" {
  description = <<-EOT
    Map of EKS clusters to create, keyed by the cluster name. Each value
    may set:
      cluster_role_arn         (required)
      subnet_ids               (required)
      node_role_arn            (required)
      kubernetes_version       (default "1.29")
      endpoint_public_access   (default true)
      endpoint_private_access  (default true)
      node_group_name          (default "<cluster name>-ng")
      node_instance_types      (default ["t3.medium"])
      capacity_type             (default "ON_DEMAND")
      desired_size              (default 2)
      min_size                  (default 1)
      max_size                  (default 3)
      tags                      (default {})
  EOT
  type = any
}
