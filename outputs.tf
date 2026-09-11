output "ec2_instances" {
  description = "EC2 instance name => id/private_ip/public_ip"
  value = {
    for k, id in module.ec2.ids : k => {
      id         = id
      private_ip = module.ec2.private_ips[k]
      public_ip  = module.ec2.public_ips[k]
    }
  }
}

output "s3_buckets" {
  description = "S3 bucket name => id/arn"
  value = {
    for k, id in module.s3.ids : k => {
      id  = id
      arn = module.s3.arns[k]
    }
  }
}

output "eks_clusters" {
  description = "EKS cluster name => id/endpoint"
  value = {
    for k, id in module.eks.cluster_ids : k => {
      cluster_id       = id
      cluster_endpoint = module.eks.cluster_endpoints[k]
    }
  }
}
