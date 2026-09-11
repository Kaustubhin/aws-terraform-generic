output "ids" {
  description = "Map of bucket name => bucket ID"
  value       = { for k, v in aws_s3_bucket.this : k => v.id }
}

output "arns" {
  description = "Map of bucket name => bucket ARN"
  value       = { for k, v in aws_s3_bucket.this : k => v.arn }
}

output "bucket_domain_names" {
  description = "Map of bucket name => bucket domain name"
  value       = { for k, v in aws_s3_bucket.this : k => v.bucket_domain_name }
}
