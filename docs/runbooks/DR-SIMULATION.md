# DR Simulation Runbook

End-to-end disaster recovery exercise for the home healthcare ePHI **lab** bucket. Uses **synthetic data only**.

## Scenario

**Event:** Primary S3 bucket objects are unavailable (simulated ransomware, accidental deletion, or regional impairment).

**Goal:** Recover synthetic patient records from AWS Backup, verify integrity, document timeline for audit/portfolio.

## Architecture reference

```text
[S3 ePHI bucket — us-east-1]
        │ backup
        ▼
[Primary vault — us-east-1] ──copy──► [Copy vault + Vault Lock — us-west-2]
        │
        │ restore
        ▼
[S3 bucket — original keys: patients/, manifest.json]
        │
        │ EventBridge (restore COMPLETED)
        ▼
[Lambda verify_restore] ──► CloudWatch VERIFICATION_RESULT=PASS
```

## Prerequisites

- AWS CLI authenticated to lab account
- Recovery point exists in primary or copy vault
- Phase 2–4 infrastructure deployed

## Lab resource names

| Resource | Value |
|----------|-------|
| Bucket | `home-healthcare-dr-ephi-376873818584` |
| Primary vault | `home-healthcare-dr-primary` (us-east-1) |
| Copy vault | `home-healthcare-dr-copy` (us-west-2) |
| Backup role | `arn:aws:iam::376873818584:role/home-healthcare-dr-backup-role` |
| Lambda | `home-healthcare-dr-verify-restore` |

---

## Simulation steps

### 1. Establish baseline (optional)

```powershell
aws s3 ls s3://home-healthcare-dr-ephi-376873818584/patients/ --region us-east-1
aws backup list-recovery-points-by-backup-vault `
  --region us-east-1 `
  --backup-vault-name home-healthcare-dr-primary
```

Record recovery point ARN and timestamp.

### 2. Simulate failure (choose one)

**Option A — Document only (non-destructive):**  
Record current object count and note: *“In production, objects would be unavailable; for lab we proceed directly to restore.”*

**Option B — Delete single object (versioning protects):**

```powershell
aws s3 rm s3://home-healthcare-dr-ephi-376873818584/patients/SYN-000001.json --region us-east-1
```

S3 versioning retains prior versions; restore still validates full manifest.

### 3. Restore from backup

```powershell
cd scripts
.\phase4-trigger-restore.ps1 `
  -RecoveryPointArn "<recovery-point-arn>" `
  -DestinationBucketName "home-healthcare-dr-ephi-376873818584" `
  -BackupRoleArn "arn:aws:iam::376873818584:role/home-healthcare-dr-backup-role"
```

Metadata includes `RestoreACLs=false` (required for BucketOwnerEnforced).

### 4. Verify automated integrity check

EventBridge should invoke Lambda automatically. Confirm:

```powershell
.\phase4-validate.ps1 `
  -LogGroupName "/aws/lambda/home-healthcare-dr-verify-restore" `
  -BucketName "home-healthcare-dr-ephi-376873818584"
```

Expected: `VERIFICATION_RESULT=PASS`

### 5. Full stack health check

```powershell
.\phase5-e2e-simulation.ps1
```

### 6. Capture evidence

- Save CLI output to `docs/evidence/phase5-e2e-simulation.md`
- Screenshot AWS Backup recovery point + CloudWatch log line (portfolio)

---

## Escalation (production pattern)

| Step | Action |
|------|--------|
| 1 | Incident commander declares DR |
| 2 | Identify last clean recovery point (RPO check) |
| 3 | Restore to isolated prefix/bucket |
| 4 | Lambda or manual manifest verification |
| 5 | Cut over after PASS; document in ticket system |

---

## Related documents

- [RTO/RPO objectives](../RTO-RPO.md)
- [HIPAA control matrix](../HIPAA-CONTROL-MATRIX.md)
- [Backup and replication](./backup-and-replication.md)
