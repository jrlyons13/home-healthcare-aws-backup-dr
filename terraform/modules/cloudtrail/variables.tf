variable "project_name" {
  type = string
}

variable "trail_name" {
  type = string
}

variable "s3_bucket_name" {
  type = string
}

variable "kms_key_arn" {
  type        = string
  default     = null
  description = "Optional KMS key for CloudTrail log bucket encryption."
}

variable "data_event_bucket_arns" {
  type        = list(string)
  description = "S3 bucket ARNs to monitor with data events."
  default     = []
}
