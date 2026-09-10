# Home Healthcare AWS Backup / Restore / DR Lab

HIPAA-aligned backup, restore, and disaster recovery patterns for a home healthcare workload, implemented incrementally on AWS with Terraform.

> **Lab disclaimer:** This repository uses **synthetic patient data only**. It demonstrates security and DR controls suitable for ePHI environments but is not a complete organizational business continuity program.

[![GitHub](https://img.shields.io/badge/GitHub-jrlyons13%2Fhome--healthcare--aws--backup--dr-blue)](https://github.com/jrlyons13/home-healthcare-aws-backup-dr)

## Architecture

```text
┌─────────────────────────────────────────────────────────────────────────┐
│                         us-east-1 (Primary)                             │
│  ┌──────────────┐   SSE-KMS    ┌─────────────────────────────────────┐  │
│  │ Phase 1      │─────────────►│ S3: home-healthcare-dr-ephi-*       │  │
│  │ Synthetic    │   upload     │  patients/*.json  manifest.json     │  │
│  │ ePHI + hash  │              └──────────────┬──────────────────────┘  │
│  └──────────────┘                             │ AWS Backup              │
│                                               ▼                         │
│                              ┌────────────────────────────┐             │
│                              │ Vault: home-healthcare-dr- │             │
│                              │        primary             │             │
│                              └─────────────┬──────────────┘             │
│  CloudTrail ──► S3 data events           │ copy                        │
│  EventBridge ◄── restore COMPLETED         │                             │
│       │                                    │                             │
│       ▼                                    │                             │
│  Lambda: verify_restore                    │                             │
│  (manifest hash + integrity)               │                             │
└────────────────────────────────────────────┼─────────────────────────────┘
                                             │
                                             ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         us-west-2 (DR)                                  │
│  ┌────────────────────────────┐                                         │
│  │ Vault: home-healthcare-dr- │  Vault Lock (WORM / Compliance-style)  │
│  │        copy                │  Recovery points immutable             │
│  └────────────────────────────┘                                         │
└─────────────────────────────────────────────────────────────────────────┘
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
| 4 | Complete | EventBridge + Lambda restore verification |
| 5 | Complete | End-to-end audit & portfolio capture |

See [docs/ROADMAP.md](docs/ROADMAP.md) for validation gates per phase.

## Key documentation

| Document | Purpose |
|----------|---------|
| [HIPAA Control Matrix](docs/HIPAA-CONTROL-MATRIX.md) | §164.312 technical safeguards ↔ AWS controls |
| [RTO / RPO](docs/RTO-RPO.md) | Recovery objectives and how the lab meets them |
| [DR Simulation Runbook](docs/runbooks/DR-SIMULATION.md) | Step-by-step DR exercise |
| [Backup & Replication](docs/runbooks/backup-and-replication.md) | On-demand backup and copy |
| [Evidence](docs/evidence/) | Phase validation logs |

## Repository structure

```text
home-healthcare-aws-backup-dr/
├── docs/                    # ROADMAP, HIPAA matrix, RTO/RPO, evidence
├── phase1-synthetic-data/   # Generator + JSON Schema
├── terraform/               # bootstrap, phase2–4 environments
├── lambda/                    # verify_restore.py
└── scripts/                 # Upload, backup, restore, validate, E2E
```

## Prerequisites

- Python 3.11+
- Terraform 1.5+
- AWS CLI v2
- GitHub CLI (`gh`) for repo management

## Quick start (full lab)

### Phase 1 — Synthetic data

```powershell
cd phase1-synthetic-data
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
python generate_patients.py --count 10 --output ./output --seed 42
python validate.py --output ./output
```

### Phase 2–4 — Infrastructure

See [terraform/README.md](terraform/README.md). Deploy bootstrap → phase2 → phase3 → phase4 in order.

### Phase 5 — E2E audit

```powershell
cd scripts
.\phase5-e2e-simulation.ps1
```

Expected: `E2E_DR_SIMULATION=PASS`

## Optional future phases

| Phase | Focus |
|-------|--------|
| 6 | AWS Config HIPAA conformance pack |
| 7 | Continuous RTO/RPO monitoring |

## License

MIT — see [LICENSE](LICENSE).
