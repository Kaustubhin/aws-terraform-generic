resource "aws_instance" "this" {
  for_each = var.instances

  ami                         = each.value.ami
  instance_type               = each.value.instance_type
  subnet_id                   = each.value.subnet_id
  vpc_security_group_ids      = try(each.value.vpc_security_group_ids, [])
  key_name                    = try(each.value.key_name, null)
  iam_instance_profile        = try(each.value.iam_instance_profile, null)
  associate_public_ip_address = try(each.value.associate_public_ip_address, false)
  user_data                   = try(each.value.user_data, null)

  root_block_device {
    volume_size = try(each.value.root_volume_size, 8)
    volume_type = try(each.value.root_volume_type, "gp3")
    encrypted   = true
  }

  metadata_options {
    http_tokens   = "required" # enforce IMDSv2
    http_endpoint = "enabled"
  }

  tags = merge(try(each.value.tags, {}), {
    Name = each.key
  })
}
