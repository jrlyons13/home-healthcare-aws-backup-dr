output "backup_role_arn" {
  value = module.backup_service_role.role_arn
}

output "primary_vault_name" {
  value = module.primary_vault.vault_name
}

output "primary_vault_arn" {
  value = module.primary_vault.vault_arn
}

output "copy_vault_name" {
  value = module.copy_vault.vault_name
}

output "copy_vault_arn" {
  value = module.copy_vault.vault_arn
}

output "backup_plan_id" {
  value = aws_backup_plan.ephi.id
}

output "ephi_bucket_arn" {
  value = local.ephi_bucket_arn
}

output "dr_kms_key_arn" {
  value = aws_kms_key.dr_backup.arn
}
