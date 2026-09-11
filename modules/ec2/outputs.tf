output "ids" {
  description = "Map of instance name => instance ID"
  value       = { for k, v in aws_instance.this : k => v.id }
}

output "arns" {
  description = "Map of instance name => instance ARN"
  value       = { for k, v in aws_instance.this : k => v.arn }
}

output "private_ips" {
  description = "Map of instance name => private IP"
  value       = { for k, v in aws_instance.this : k => v.private_ip }
}

output "public_ips" {
  description = "Map of instance name => public IP"
  value       = { for k, v in aws_instance.this : k => v.public_ip }
}
