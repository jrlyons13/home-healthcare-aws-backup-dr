output "role_arn" {
  value = aws_iam_role.backup.arn
}

output "role_name" {
  value = aws_iam_role.backup.name
}
