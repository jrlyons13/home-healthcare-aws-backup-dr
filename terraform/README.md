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

## Future phases

- **Phase 3:** AWS Backup vaults, Vault Lock, cross-region copy (new environment or extend phase2)
- **Phase 4:** EventBridge + Lambda verifier
