variable "project_name" {
  type    = string
  default = "home-healthcare-dr"
}

variable "primary_region" {
  type    = string
  default = "us-east-1"
}

variable "dr_region" {
  type    = string
  default = "us-west-2"
}

variable "state_bucket_name" {
  description = "Terraform remote state bucket from bootstrap."
  type        = string
  default     = "home-healthcare-dr-tfstate-376873818584"
}

variable "primary_vault_name" {
  type    = string
  default = "home-healthcare-dr-primary"
}

variable "copy_vault_name" {
  type    = string
  default = "home-healthcare-dr-copy"
}

variable "backup_schedule_cron" {
  type    = string
  default = "cron(0 6 * * ? *)"
}

variable "primary_retention_days" {
  type    = number
  default = 35
}

variable "copy_retention_days" {
  type    = number
  default = 90
}

variable "vault_lock_min_retention_days" {
  type    = number
  default = 7
}

variable "vault_lock_max_retention_days" {
  type    = number
  default = 365
}

variable "vault_lock_changeable_for_days" {
  description = "Cooling period before Vault Lock becomes immutable (minimum 3)."
  type        = number
  default     = 3
}
