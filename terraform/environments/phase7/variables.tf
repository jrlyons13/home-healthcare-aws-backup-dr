variable "project_name" {
  type    = string
  default = "home-healthcare-dr"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "dr_region" {
  type    = string
  default = "us-west-2"
}

variable "state_bucket_name" {
  type    = string
  default = "home-healthcare-dr-tfstate-376873818584"
}

variable "max_age_hours" {
  description = "Maximum age (hours) of the latest COMPLETED S3 recovery point."
  type        = number
  default     = 26
}

variable "lambda_zip_path" {
  type    = string
  default = "../../../lambda/dist/rpo_freshness_config.zip"
}

variable "primary_rpo_rule_name" {
  type    = string
  default = "home-healthcare-dr-primary-rpo-freshness"
}

variable "copy_rpo_rule_name" {
  type    = string
  default = "home-healthcare-dr-copy-rpo-freshness"
}
