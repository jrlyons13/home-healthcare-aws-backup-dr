variable "vault_name" {
  type = string
}

variable "kms_key_arn" {
  type    = string
  default = null
}

variable "enable_vault_lock" {
  type    = bool
  default = false
}

variable "min_retention_days" {
  type    = number
  default = 7
}

variable "max_retention_days" {
  type    = number
  default = 365
}

variable "changeable_for_days" {
  type    = number
  default = 3
}
