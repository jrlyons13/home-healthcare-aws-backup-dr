# Phase 3: Backup Vault, Vault Lock & Cross-Region Replication — Validation

**Date:** 2026-09-09

## Objective

Deploy AWS Backup with IAM/KMS prerequisites first, create primary and DR vaults, enable Vault Lock on the copy vault, and validate backup + cross-region replication.

## Deploy order (Terraform)

1. IAM backup service role + managed S3/backup policies
2. S3 opt-in (primary + DR regions)
3. KMS key policy update (primary CMK + DR region CMK)
4. Primary vault (`us-east-1`) + copy vault with Vault Lock (`us-west-2`)
5. Backup plan with cross-region `copy_action`

## Resources

| Resource | Value |
|----------|-------|
| Backup IAM role | `home-healthcare-dr-backup-role` |
| Primary vault | `home-healthcare-dr-primary` (us-east-1) |
| Copy vault | `home-healthcare-dr-copy` (us-west-2) |
| Vault Lock | min 7 / max 365 days, 3-day cooling period |
| Backup plan | `home-healthcare-dr-ephi-plan` |
| DR KMS key | `arn:aws:kms:us-west-2:376873818584:key/c71317a4-3a13-4b1a-9194-460e86849135` |

## Commands run

```powershell
cd terraform/environments/phase3
terraform init "-backend-config=backend.hcl"
terraform apply

cd ..\..\..\scripts
.\phase3-trigger-backup.ps1 `
  -PrimaryVaultName "home-healthcare-dr-primary" `
  -CopyVaultArn "arn:aws:backup:us-west-2:376873818584:backup-vault:home-healthcare-dr-copy" `
  -BucketArn "arn:aws:s3:::home-healthcare-dr-ephi-376873818584" `
  -BackupRoleArn "arn:aws:iam::376873818584:role/home-healthcare-dr-backup-role"

.\phase3-validate.ps1 `
  -PrimaryVaultName "home-healthcare-dr-primary" `
  -CopyVaultName "home-healthcare-dr-copy"
```

## Results

```text
BackupJobId: ac9b5d51-4702-484d-a86b-2b669495c7ff
Backup state: COMPLETED (~26 minutes for first S3 backup)

CopyJobId: 65534a0b-15e7-4af5-9ba2-b3a075aa5eb0
Copy state: COMPLETED

=== Phase 3 Validation ===
[1] Primary vault recovery points: PASS (1)
[2] Copy vault recovery points: PASS (1)
[3] Vault Lock delete denial: PASS
    InvalidRequestException: RecoveryPoint cannot be deleted or updated (Backup vault configured with Lock)
[4] Backup IAM role: PASS

VERIFICATION_RESULT=PASS
```

## Notes

- **First S3 backup** can take 20–30+ minutes; subsequent jobs are faster.
- **Copy job retention** must fall within Vault Lock min/max (90 days used; script updated with `--lifecycle DeleteAfterDays=90`).
- **Terraform apply succeeded on first run** — IAM, KMS, vaults, and plan created without retry.

## Checklist

- [x] Backup service role created by Terraform with S3 backup/restore policies
- [x] KMS policies allow `backup.amazonaws.com`
- [x] Primary vault recovery point created
- [x] Cross-region copy recovery point in `us-west-2`
- [x] Vault Lock blocks recovery point deletion
- [x] Runbook: `docs/runbooks/backup-and-replication.md`

## Next step

Phase 4 — EventBridge + Lambda restore integrity verification.
