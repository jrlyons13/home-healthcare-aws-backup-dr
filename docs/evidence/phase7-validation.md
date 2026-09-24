# Phase 7: RPO Freshness Config Rules — Validation

**Date:** 2026-09-24

## Objective

Deploy two **custom AWS Config rules** (6-hour periodic) that verify the latest **COMPLETED** S3 recovery point for the ePHI bucket is no older than **26 hours** in the primary vault (`us-east-1`) and DR copy vault (`us-west-2`).

## Resources

| Resource | Value |
|----------|-------|
| Lambda | `home-healthcare-dr-rpo-freshness-config` |
| Primary rule | `home-healthcare-dr-primary-rpo-freshness` |
| Copy rule | `home-healthcare-dr-copy-rpo-freshness` |
| Max age | 26 hours |
| ePHI bucket | `home-healthcare-dr-ephi-376873818584` |

## Commands run

```powershell
cd scripts
.\build-lambda.ps1

cd ..\terraform\environments\phase7
terraform init "-backend-config=backend.hcl"
terraform apply

# Console: AWS Config -> Rules -> Evaluate (both rules)
cd ..\..\..\scripts
.\phase7-validate.ps1
```

## Results

```text
[1] home-healthcare-dr-primary-rpo-freshness
  Compliance: COMPLIANT
  Annotation: Latest point 22.1h old (max 26.0h)

[2] home-healthcare-dr-copy-rpo-freshness
  Compliance: COMPLIANT
  Annotation: Latest point 22.1h old (max 26.0h)

PHASE7_RPO_MONITOR=PASS
```

## Status

- [x] Terraform apply successful
- [x] `PHASE7_RPO_MONITOR=PASS`
- [x] Evidence recorded
