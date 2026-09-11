variable "instances" {
  description = <<-EOT
    Map of EC2 instances to create, keyed by a unique instance name
    (that key becomes the `Name` tag). Each value may set:
      ami                          (required)
      instance_type                (required)
      subnet_id                    (required)
      vpc_security_group_ids       (default [])
      key_name                     (default null)
      iam_instance_profile         (default null)
      associate_public_ip_address  (default false)
      root_volume_size             (default 8)
      root_volume_type             (default "gp3")
      user_data                    (default null)
      tags                         (default {})
  EOT
  type = any
}
