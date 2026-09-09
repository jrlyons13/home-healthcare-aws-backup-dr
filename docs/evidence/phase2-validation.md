# Phase 2: Core S3 & KMS Infrastructure — Validation

**Date:** 2026-09-09  
**Region:** `us-east-1`

## Objective

Deploy encrypted S3 storage with a customer managed KMS key, remote Terraform state, CloudTrail S3 data events, and upload Phase 1 synthetic records.

## Infrastructure deployed

| Resource | Name / ARN |
|----------|------------|
| Terraform state bucket | `home-healthcare-dr-tfstate-376873818584` |
| Terraform lock table | `home-healthcare-dr-tflock` |
| ePHI data bucket | `home-healthcare-dr-ephi-376873818584` |
| KMS CMK alias | `alias/home-healthcare-dr-ephi` |
| CloudTrail | `home-healthcare-dr-trail` |
| CloudTrail log bucket | `home-healthcare-dr-cloudtrail-376873818584` |

## Commands run

```powershell
# Bootstrap remote state
cd terraform/bootstrap
terraform init
terraform apply

# Phase 2 stack (remote backend)
cd ..\environments\phase2
terraform init "-backend-config=backend.hcl"
terraform apply

# Upload + validate
cd ..\..\..\scripts
.\phase2-upload.ps1 -BucketName "home-healthcare-dr-ephi-376873818584"
.\phase2-validate.ps1 -BucketName "home-healthcare-dr-ephi-376873818584" `
  -KmsKeyArn "arn:aws:kms:us-east-1:376873818584:key/5e861884-e3a6-473e-9af9-299abb2160e5"
```

## Validation results

```text
=== Phase 2 Validation ===

[1] head-object (SSE-KMS check)
  ServerSideEncryption: aws:kms
  SSEKMSKeyId:          arn:aws:kms:us-east-1:376873818584:key/5e861884-e3a6-473e-9af9-299abb2160e5
  PASS

[2] HTTPS-only policy (insecure transport should fail)
  PASS: HTTP/insecure upload denied

[3] CloudTrail S3 data events
  Trail configured with data resource on ePHI bucket objects
  Note: PutObject events may take up to ~15 minutes to appear in lookup-events

VERIFICATION_RESULT=PASS
```

## Checklist

- [x] Remote Terraform state (S3 + DynamoDB lock)
- [x] KMS CMK with automatic rotation enabled
- [x] S3 versioning, Block Public Access, BucketOwnerEnforced
- [x] Default encryption SSE-KMS with CMK
- [x] Bucket policy denies insecure transport (`aws:SecureTransport`)
- [x] Bucket policy denies unencrypted object uploads
- [x] CloudTrail with S3 data events on ePHI bucket
- [x] Phase 1 synthetic records + manifest uploaded with `--sse aws:kms`
- [x] IAM operator policy attached for lab uploads

## Manual verification (optional)

```powershell
aws s3api head-object --bucket home-healthcare-dr-ephi-376873818584 --key patients/SYN-000001.json
aws s3 ls s3://home-healthcare-dr-ephi-376873818584/ --recursive
aws cloudtrail get-event-selectors --trail-name home-healthcare-dr-trail --region us-east-1
```

## Next step

Phase 3 — AWS Backup vault, Vault Lock (Compliance mode), and cross-region copy to `us-west-2`.
