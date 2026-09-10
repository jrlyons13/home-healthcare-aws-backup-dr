output "lambda_function_name" {
  value = aws_lambda_function.verify_restore.function_name
}

output "lambda_function_arn" {
  value = aws_lambda_function.verify_restore.arn
}

output "eventbridge_rule_name" {
  value = aws_cloudwatch_event_rule.restore_completed.name
}

output "verify_prefix" {
  value = var.verify_prefix != "" ? var.verify_prefix : "patients/ (original keys)"
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.lambda_verifier.name
}

output "ephi_bucket_name" {
  value = local.bucket_name
}
