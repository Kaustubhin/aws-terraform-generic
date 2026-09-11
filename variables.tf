variable "aws_region" {
  type        = string
  description = "AWS region to deploy into"
  default     = "us-east-1"
}

variable "config_file" {
  type        = string
  description = "Path to the resource definition file (.yaml, .yml, or .json)"
  default     = "resources.yaml"
}
