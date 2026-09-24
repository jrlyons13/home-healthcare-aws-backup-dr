# Phase 6: AWS Config HIPAA Conformance Pack — Validation

**Date:** 2026-09-22

## Objective

Enable AWS Config in `us-east-1`, deliver snapshots to a dedicated S3 bucket, and deploy the **Operational Best Practices for HIPAA Security** conformance pack for continuous configuration compliance monitoring (audit readiness).

## Deploy order (Terraform)

1. Config delivery S3 bucket (encrypted, blocked public access)
2. IAM role for `config.amazonaws.com`
3. Configuration recorder + delivery channel (recording enabled)
4. HIPAA Security conformance pack (template uploaded to lab Config bucket)

## Resources

| Resource | Value |
|----------|-------|
| Config S3 bucket | `home-healthcare-dr-config-376873818584` |
| Configuration recorder | `home-healthcare-dr-config-recorder` |
| Delivery channel | `home-healthcare-dr-config-delivery` |
| Conformance pack | `home-healthcare-dr-hipaa-security` |
| Template | `s3://home-healthcare-dr-config-376873818584/conformance-packs/Operational-Best-Practices-for-HIPAA-Security.yaml` |
| ePHI bucket (compliance target) | `home-healthcare-dr-ephi-376873818584` |

## Commands run

```powershell
cd terraform/environments/phase6
terraform init "-backend-config=backend.hcl"
terraform apply

cd ..\..\..\scripts
.\phase6-validate.ps1
```

## Results

```text
[1] Configuration recorder: recording=True lastStatus=SUCCESS — PASS
[2] Delivery channel -> home-healthcare-dr-config-376873818584 — PASS
[3] Conformance pack home-healthcare-dr-hipaa-security — PASS
[4] Conformance pack status CREATE_COMPLETE — PASS
[6] ePHI bucket: 2+ COMPLIANT (public read/write prohibited), 0 NON_COMPLIANT on bucket

CONFIG_PHASE6=PASS
```

Console: AWS Config → Conformance packs → `home-healthcare-dr-hipaa-security`; ePHI bucket compliance visible on resource.

## Notes

- Account-wide HIPAA pack reports many non-compliant rules in a lab account (expected).
- Phase 5 E2E script and evidence unchanged.
- Conformance pack template must live in the **lab** Config S3 bucket (AWS rejects the public schema-bucket URI for `PutConformancePack`).

## Status

- [x] Terraform apply successful
- [x] `CONFIG_PHASE6=PASS`
- [x] Evidence recorded
