output "cluster_ids" {
  description = "Map of cluster name => cluster ID"
  value       = { for k, v in aws_eks_cluster.this : k => v.id }
}

output "cluster_arns" {
  description = "Map of cluster name => cluster ARN"
  value       = { for k, v in aws_eks_cluster.this : k => v.arn }
}

output "cluster_endpoints" {
  description = "Map of cluster name => API endpoint"
  value       = { for k, v in aws_eks_cluster.this : k => v.endpoint }
}

output "cluster_certificate_authority_data" {
  description = "Map of cluster name => base64 CA data"
  value       = { for k, v in aws_eks_cluster.this : k => v.certificate_authority[0].data }
}

output "node_group_ids" {
  description = "Map of cluster name => node group ID"
  value       = { for k, v in aws_eks_node_group.this : k => v.id }
}
