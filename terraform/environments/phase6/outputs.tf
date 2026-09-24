output "config_bucket_name" {
  description = "S3 bucket receiving AWS Config snapshots."
  value       = aws_s3_bucket.config.id
}

output "configuration_recorder_name" {
  value = aws_config_configuration_recorder.this.name
}

output "conformance_pack_name" {
  value = aws_config_conformance_pack.hipaa.name
}

output "conformance_pack_template_s3_uri" {
  value = local.conformance_pack_template_s3_uri
}

output "ephi_bucket_name" {
  description = "Primary ePHI bucket (from Phase 2) used in compliance validation."
  value       = data.terraform_remote_state.phase2.outputs.ephi_bucket_name
}

output "validate_command" {
  description = "Run from repo scripts/ after apply (wait ~10 min for first evaluations)."
  value       = ".\\phase6-validate.ps1 -ConfigBucketName ${aws_s3_bucket.config.id} -RecorderName ${aws_config_configuration_recorder.this.name} -ConformancePackName ${aws_config_conformance_pack.hipaa.name} -EphiBucketName ${data.terraform_remote_state.phase2.outputs.ephi_bucket_name}"
}
