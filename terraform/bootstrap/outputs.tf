output "state_bucket_name" {
  description = "S3 bucket for Terraform remote state."
  value       = aws_s3_bucket.terraform_state.id
}

output "state_lock_table_name" {
  description = "DynamoDB table for Terraform state locking."
  value       = aws_dynamodb_table.terraform_lock.name
}

output "aws_region" {
  description = "Region where the state backend lives."
  value       = var.aws_region
}
