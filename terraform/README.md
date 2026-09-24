# Terraform

AWS infrastructure for the home healthcare backup/DR lab.

## Layout

```text
terraform/
├── bootstrap/              # Remote state backend (apply once, local state)
├── environments/
│   └── phase2/             # S3 + KMS + CloudTrail (us-east-1)
└── modules/
    ├── kms/
    ├── s3-data-bucket/
    └── cloudtrail/
```

## Phase 2 — deploy order

### 1. Bootstrap remote state (one time)

```powershell
cd terraform/bootstrap
terraform init
terraform apply
```

Note the outputs: `state_bucket_name`, `state_lock_table_name`.

### 2. Configure Phase 2 backend

Copy `environments/phase2/backend.hcl.example` to `backend.hcl` and replace `ACCOUNT_ID` with your AWS account ID (or use bootstrap output bucket name).

```powershell
cd ..\environments\phase2
copy backend.hcl.example backend.hcl
# Edit backend.hcl with your account ID
terraform init -backend-config=backend.hcl
terraform apply
```

`backend.hcl` is gitignored.

### 3. Upload synthetic data

```powershell
cd ..\..\..\scripts
.\phase2-upload.ps1 -BucketName "<ephi_bucket_name from terraform output>"
```

### 4. Validate

```powershell
.\phase2-validate.ps1 -BucketName "<bucket>" -KmsKeyArn "<kms_key_arn from output>"
```

## Phase 3 — Backup vaults, Vault Lock, cross-region copy

```powershell
cd terraform/environments/phase3
copy backend.hcl.example backend.hcl   # set ACCOUNT_ID
terraform init "-backend-config=backend.hcl"
terraform apply

cd ..\..\..\scripts
.\phase3-trigger-backup.ps1 -PrimaryVaultName "..." -CopyVaultArn "..." -BucketArn "..." -BackupRoleArn "..."
.\phase3-validate.ps1 -PrimaryVaultName "home-healthcare-dr-primary" -CopyVaultName "home-healthcare-dr-copy"
```

Deploy order inside Phase 3 Terraform: IAM role → KMS policies → vaults → backup plan.

## Phase 4 — Lambda restore verification

```powershell
cd scripts
.\build-lambda.ps1
cd ..\terraform\environments\phase4
terraform init "-backend-config=backend.hcl"
terraform apply
```

## Phase 6 — AWS Config + HIPAA conformance pack

```powershell
cd terraform/environments/phase6
copy backend.hcl.example backend.hcl
terraform init "-backend-config=backend.hcl"
terraform apply
```

After apply, wait **10–20 minutes** for Config to evaluate resources, then:

```powershell
cd ..\..\..\scripts
.\phase6-validate.ps1
# Or: terraform -chdir=../environments/phase6 output -raw validate_command
```

**Prerequisite:** Phase 2 applied (remote state for ePHI bucket name). Only one Config recorder per region per account.

## Phase 7 — RPO freshness Config rules

```powershell
cd scripts
.\build-lambda.ps1
cd ..\terraform\environments\phase7
copy backend.hcl.example backend.hcl
terraform init "-backend-config=backend.hcl"
terraform apply
```

Trigger an on-demand evaluation, then validate:

```powershell
aws configservice start-config-rules-evaluation --region us-east-1 --config-rule-names home-healthcare-dr-primary-rpo-freshness home-healthcare-dr-copy-rpo-freshness
cd ..\..\..\scripts
.\phase7-validate.ps1
```

**Prerequisites:** Phases 2–3 (vaults + recovery points), Phase 6 (Config recorder).
