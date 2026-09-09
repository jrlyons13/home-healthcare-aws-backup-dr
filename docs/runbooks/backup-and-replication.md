# Backup and Cross-Region Replication Runbook

## Architecture

```text
S3 bucket (us-east-1)
    │
    │ AWS Backup job
    ▼
Primary vault: home-healthcare-dr-primary (us-east-1)
    │
    │ copy job / plan copy_action
    ▼
Copy vault: home-healthcare-dr-copy (us-west-2)
    └── Vault Lock (Compliance-style, 3-day cooling period)
```

## Prerequisites

- Phase 2 S3 bucket with versioning enabled
- Phase 3 Terraform applied (IAM role, vaults, backup plan)
- AWS CLI configured for `us-east-1` and `us-west-2`

## On-demand backup + copy

```powershell
cd scripts
.\phase3-trigger-backup.ps1 `
  -PrimaryVaultName "home-healthcare-dr-primary" `
  -CopyVaultArn "arn:aws:backup:us-west-2:ACCOUNT_ID:backup-vault:home-healthcare-dr-copy" `
  -BucketArn "arn:aws:s3:::home-healthcare-dr-ephi-ACCOUNT_ID" `
  -BackupRoleArn "arn:aws:iam::ACCOUNT_ID:role/home-healthcare-dr-backup-role"
```

## Validate

```powershell
.\phase3-validate.ps1 `
  -PrimaryVaultName "home-healthcare-dr-primary" `
  -CopyVaultName "home-healthcare-dr-copy"
```

## Scheduled backups

The backup plan runs daily at 06:00 UTC (`cron(0 6 * * ? *)`) and copies recovery points to `us-west-2` with 90-day retention.

## Vault Lock notes

- **Cooling period:** 3 days before lock configuration becomes immutable
- **Min retention:** 7 days on copy vault recovery points
- Delete tests may return `AccessDeniedException` only after lock/retention rules apply

## Troubleshooting

| Symptom | Check |
|---------|--------|
| Backup job fails IAM | `aws iam list-attached-role-policies --role-name home-healthcare-dr-backup-role` |
| KMS error | KMS key policy includes `backup.amazonaws.com` (Phase 3) |
| S3 not eligible | Bucket versioning enabled; S3 opted in under AWS Backup settings |
| Copy job fails | Copy vault exists in `us-west-2`; DR KMS key present |
