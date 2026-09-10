# Phase 4: Automated Restore Verification — Validation

**Date:** 2026-09-09

## Objective

Deploy Lambda + EventBridge to automatically verify restored S3 objects against the baseline `manifest.json` (hashes + basic synthetic ePHI checks).

## Architecture

```text
AWS Backup restore job (S3) → COMPLETED
        │
        ▼
EventBridge rule: home-healthcare-dr-restore-completed
        │
        ▼
Lambda: home-healthcare-dr-verify-restore
        │
        └── CloudWatch: VERIFICATION_RESULT=PASS|FAIL
```

## Restore target note

AWS Backup S3 restore does **not** support a custom prefix. Restored objects return to their **original keys** (`patients/`, `manifest.json`). S3 **versioning** on the bucket retains prior versions. Lambda verifies objects at manifest keys (e.g. `patients/SYN-000001.json`).

## Resources

| Resource | Value |
|----------|-------|
| Lambda | `home-healthcare-dr-verify-restore` |
| EventBridge rule | `home-healthcare-dr-restore-completed` |
| Log group | `/aws/lambda/home-healthcare-dr-verify-restore` |
| IAM role | `home-healthcare-dr-verify-restore-lambda` |

## Commands run

```powershell
cd scripts
.\build-lambda.ps1

cd ..\terraform\environments\phase4
terraform init "-backend-config=backend.hcl"
terraform apply

.\phase4-trigger-restore.ps1 `
  -RecoveryPointArn "arn:aws:backup:us-east-1:376873818584:recovery-point:home-healthcare-dr-ephi-376873818584-20260909222511-dac673e1" `
  -DestinationBucketName "home-healthcare-dr-ephi-376873818584" `
  -BackupRoleArn "arn:aws:iam::376873818584:role/home-healthcare-dr-backup-role"

.\phase4-validate.ps1 `
  -LogGroupName "/aws/lambda/home-healthcare-dr-verify-restore" `
  -BucketName "home-healthcare-dr-ephi-376873818584"
```

## Results

```text
RestoreJobId: 1f7ad028-c1ea-49a8-add7-c509784f2f3b
Restore state: COMPLETED

Lambda invoke: {"result": "PASS"}

=== Phase 4 Validation ===
[1] Restored patient objects: PASS (10)
[2] CloudWatch VERIFICATION_RESULT=PASS records=10

VERIFICATION_RESULT=PASS
```

## Implementation notes

- EventBridge pattern uses `detail.status` (not `state`) for restore job events.
- Restore metadata includes `RestoreACLs=false` (bucket uses BucketOwnerEnforced).
- Lambda uses hash verification + basic field checks (no jsonschema bundle — avoids Lambda Linux packaging issues).

## Checklist

- [x] Lambda deployed via Terraform
- [x] EventBridge triggers on S3 restore COMPLETED
- [x] Restore job completes to original object keys
- [x] CloudWatch logs show `VERIFICATION_RESULT=PASS`
- [x] 10/10 manifest hashes verified

## Next step

Phase 5 — End-to-end DR simulation, HIPAA control matrix, and portfolio artifacts.
