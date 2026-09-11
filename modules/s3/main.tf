resource "aws_s3_bucket" "this" {
  for_each = var.buckets

  bucket        = each.key
  force_destroy = try(each.value.force_destroy, false)
  tags          = try(each.value.tags, {})
}

resource "aws_s3_bucket_versioning" "this" {
  for_each = var.buckets

  bucket = aws_s3_bucket.this[each.key].id
  versioning_configuration {
    status = try(each.value.versioning, false) ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  for_each = var.buckets

  bucket = aws_s3_bucket.this[each.key].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = try(each.value.sse_algorithm, "AES256")
      kms_master_key_id = try(each.value.sse_algorithm, "AES256") == "aws:kms" ? try(each.value.kms_key_id, null) : null
    }
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  for_each = var.buckets

  bucket                  = aws_s3_bucket.this[each.key].id
  block_public_acls       = try(each.value.block_public_access, true)
  block_public_policy     = try(each.value.block_public_access, true)
  ignore_public_acls      = try(each.value.block_public_access, true)
  restrict_public_buckets = try(each.value.block_public_access, true)
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  for_each = { for k, v in var.buckets : k => v if length(try(v.lifecycle_rules, [])) > 0 }

  bucket = aws_s3_bucket.this[each.key].id

  dynamic "rule" {
    for_each = each.value.lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.enabled ? "Enabled" : "Disabled"

      filter {
        prefix = try(rule.value.prefix, "")
      }

      dynamic "expiration" {
        for_each = try(rule.value.expiration_days, null) != null ? [1] : []
        content {
          days = rule.value.expiration_days
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = try(rule.value.noncurrent_expiration_days, null) != null ? [1] : []
        content {
          noncurrent_days = rule.value.noncurrent_expiration_days
        }
      }
    }
  }
}
