output "lambda_function_name" {
  value = aws_lambda_function.rpo_freshness.function_name
}

output "primary_rpo_config_rule_name" {
  value = aws_config_config_rule.primary_rpo.name
}

output "copy_rpo_config_rule_name" {
  value = aws_config_config_rule.copy_rpo.name
}

output "max_age_hours" {
  value = var.max_age_hours
}

output "ephi_bucket_name" {
  value = local.ephi_bucket_name
}

output "validate_command" {
  value = ".\\phase7-validate.ps1 -PrimaryRuleName ${aws_config_config_rule.primary_rpo.name} -CopyRuleName ${aws_config_config_rule.copy_rpo.name} -EphiBucketName ${local.ephi_bucket_name}"
}
