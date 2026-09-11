variable "buckets" {
  description = <<-EOT
    Map of S3 buckets to create, keyed by the bucket name (must be
    globally unique in AWS). Each value may set:
      versioning           (default false)
      force_destroy        (default false)
      block_public_access  (default true)
      sse_algorithm        (default "AES256")
      kms_key_id           (default null, used when sse_algorithm = "aws:kms")
      lifecycle_rules      (default [])
      tags                 (default {})
  EOT
  type = any
}
