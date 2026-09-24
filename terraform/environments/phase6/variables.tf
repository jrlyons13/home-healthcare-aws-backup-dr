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

variable "conformance_pack_name" {
  description = "AWS Config conformance pack resource name (must be unique per region)."
  type        = string
  default     = "home-healthcare-dr-hipaa-security"
}

variable "conformance_pack_template" {
  description = "AWS-managed HIPAA Security conformance pack template file name (without path)."
  type        = string
  default     = "Operational-Best-Practices-for-HIPAA-Security"
}
