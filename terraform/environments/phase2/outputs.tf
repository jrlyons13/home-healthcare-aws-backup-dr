output "ephi_bucket_name" {
  description = "Primary S3 bucket for synthetic ePHI data."
  value       = module.ephi_bucket.bucket_id
}

output "ephi_bucket_arn" {
  value = module.ephi_bucket.bucket_arn
}

output "kms_key_arn" {
  value = module.ephi_kms.key_arn
}

output "kms_alias" {
  value = module.ephi_kms.alias_name
}

output "cloudtrail_arn" {
  value = module.audit_trail.trail_arn
}

output "cloudtrail_bucket_name" {
  value = module.audit_trail.trail_bucket_name
}

output "operator_policy_arn" {
  value = aws_iam_policy.ephi_operator.arn
}
