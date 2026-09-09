variable "project_name" {
  type = string
}

variable "description" {
  type    = string
  default = "Customer managed key for home healthcare ePHI data encryption"
}

variable "deletion_window_in_days" {
  type    = number
  default = 7
}

variable "enable_key_rotation" {
  type    = bool
  default = true
}

variable "alias_name" {
  type = string
}
