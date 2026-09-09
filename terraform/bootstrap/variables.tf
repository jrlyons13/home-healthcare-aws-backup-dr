variable "project_name" {
  description = "Short project name used in resource naming."
  type        = string
  default     = "home-healthcare-dr"
}

variable "aws_region" {
  description = "AWS region for the Terraform state backend."
  type        = string
  default     = "us-east-1"
}
