variable "project_name" {
  type    = string
  default = "home-healthcare-dr"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "state_bucket_name" {
  type    = string
  default = "home-healthcare-dr-tfstate-376873818584"
}

variable "verify_prefix" {
  description = "S3 prefix for restored objects. Empty = original keys (patients/) per AWS Backup S3 restore behavior."
  type        = string
  default     = ""
}

variable "manifest_key" {
  type    = string
  default = "manifest.json"
}

variable "lambda_zip_path" {
  description = "Path to the pre-built Lambda deployment package."
  type        = string
  default     = "../../../lambda/dist/verify_restore.zip"
}
