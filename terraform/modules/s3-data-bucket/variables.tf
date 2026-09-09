variable "project_name" {
  type = string
}

variable "bucket_name" {
  type = string
}

variable "kms_key_arn" {
  type = string
}

variable "allowed_upload_principals" {
  description = "IAM principal ARNs allowed to upload objects."
  type        = list(string)
  default     = []
}
