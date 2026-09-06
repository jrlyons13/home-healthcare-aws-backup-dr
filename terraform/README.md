# Terraform

AWS infrastructure for Phases 2–4:

- **Phase 2:** S3, KMS, IAM, CloudTrail, remote state backend
- **Phase 3:** AWS Backup vaults, backup plan, Vault Lock, cross-region copy
- **Phase 4:** EventBridge, Lambda, SNS

Modules will live under `modules/`. Environment-specific variables use `terraform.tfvars` (gitignored); see `terraform.tfvars.example` when added in Phase 2.
