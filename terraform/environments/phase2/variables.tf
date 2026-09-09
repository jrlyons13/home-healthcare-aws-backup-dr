variable "project_name" {
  type    = string
  default = "home-healthcare-dr"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "attach_operator_policy_to_current_user" {
  description = "Attach the ePHI operator IAM policy to the current IAM user (lab convenience)."
  type        = bool
  default     = true
}
