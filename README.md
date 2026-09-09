# Home Healthcare AWS Backup / Restore / DR Lab

HIPAA-aligned backup, restore, and disaster recovery patterns for a home healthcare workload, implemented incrementally on AWS with Terraform.

> **Lab disclaimer:** This repository uses **synthetic patient data only**. It demonstrates security and DR controls suitable for ePHI environments but is not a complete organizational business continuity program.

## Architecture (target state)

```text
Phase 1: Synthetic data + schema + manifest (local)
    │
    ▼
Phase 2: S3 + KMS + IAM + CloudTrail + Terraform state (us-east-1)
    │
    ▼
Phase 3: AWS Backup plan → primary vault (east) → copy vault + Vault Lock (west)
    │
    ▼
Phase 4: Restore to sandbox → EventBridge → Lambda verify vs manifest
    │
    ▼
Phase 5: E2E DR simulation + HIPAA matrix + runbook + portfolio artifacts
```

## Regions

| Role | Region |
|------|--------|
| Primary | `us-east-1` |
| DR copy | `us-west-2` |

## Phases

| Phase | Status | Description |
|-------|--------|-------------|
| 0 | Complete | GitHub repo bootstrap |
| 1 | Complete | Synthetic ePHI data pipeline |
| 2 | Complete | Core S3 & KMS infrastructure (Terraform) |
| 3 | Complete | Backup vault, Vault Lock & cross-region replication |
| 4 | Pending | EventBridge + Lambda restore verification |
| 5 | Pending | End-to-end audit & portfolio capture |

See [docs/ROADMAP.md](docs/ROADMAP.md) for validation gates and deliverables per phase.

## Repository structure

```text
home-healthcare-aws-backup-dr/
├── .github/workflows/       # CI (Checkov, etc.) — added in later phases
├── docs/
│   ├── ROADMAP.md
│   ├── evidence/            # Phase validation logs and CLI output
│   └── runbooks/            # Operational procedures
├── phase1-synthetic-data/   # Synthetic ePHI generator
├── terraform/               # AWS infrastructure
└── lambda/                  # Restore integrity verifier
```

## Prerequisites

- Python 3.11+
- Terraform 1.5+
- AWS CLI v2 (configured profile)
- GitHub CLI (`gh`) authenticated as `jrlyons13`

## Getting started

### Phase 1 — Generate and validate synthetic data

```powershell
cd phase1-synthetic-data
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
python generate_patients.py --count 10 --output ./output --seed 42
python validate.py --output ./output
```

Browse sample records on GitHub under `phase1-synthetic-data/samples/`, or open generated files in `phase1-synthetic-data/output/patients/`.

### Phase 2 — Deploy encrypted S3 + KMS

See [terraform/README.md](terraform/README.md) for bootstrap and apply steps.

```powershell
cd scripts
.\phase2-upload.ps1 -BucketName "<ephi_bucket_name>"
.\phase2-validate.ps1 -BucketName "<bucket>" -KmsKeyArn "<kms_key_arn>"
```

### Phase 3 — Backup vaults + Vault Lock + cross-region copy

```powershell
cd terraform/environments/phase3
terraform init "-backend-config=backend.hcl"
terraform apply

cd ..\..\..\scripts
.\phase3-trigger-backup.ps1 -PrimaryVaultName "..." -CopyVaultArn "..." -BucketArn "..." -BackupRoleArn "..."
.\phase3-validate.ps1 -PrimaryVaultName "home-healthcare-dr-primary" -CopyVaultName "home-healthcare-dr-copy"
```

## License

MIT — see [LICENSE](LICENSE).
