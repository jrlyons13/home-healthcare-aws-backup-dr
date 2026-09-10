# RTO / RPO Objectives (Lab)

> **Scope:** Synthetic ePHI lab environment. These targets document design intent for portfolio and runbooks; they are not organizational SLAs.

## Definitions

| Term | Meaning | Lab target |
|------|---------|------------|
| **RPO** (Recovery Point Objective) | Maximum acceptable data loss measured in time | **24 hours** |
| **RTO** (Recovery Time Objective) | Maximum acceptable time to restore service | **4 hours** |

## How the lab meets RPO

| Control | Implementation | Evidence |
|---------|----------------|----------|
| Daily scheduled backup | AWS Backup plan `home-healthcare-dr-ephi-plan` — `cron(0 6 * * ? *)` UTC | Phase 3 Terraform |
| On-demand backup | `scripts/phase3-trigger-backup.ps1` | `docs/evidence/phase3-validation.md` |
| Cross-region copy | Copy action to `home-healthcare-dr-copy` (us-west-2), 90-day retention | Phase 3 validation |
| Immutable copies | Vault Lock on copy vault (min 7 / max 365 days) | Phase 3 delete-denied test |
| Integrity baseline | Phase 1 `manifest.json` with MD5/SHA-256 | Phase 1 + S3 upload |

**Observed RPO (first S3 backup):** ~26 minutes from job start to recovery point (on-demand test). Scheduled daily backups tighten the window to ≤24h by design.

## How the lab meets RTO

| Step | Activity | Lab observed |
|------|----------|--------------|
| 1 | Detect / declare event | Manual runbook (DR-SIMULATION.md) |
| 2 | Identify recovery point | AWS Backup console or CLI | Minutes |
| 3 | Start restore job | `phase4-trigger-restore.ps1` | ~4–5 min (10 objects) |
| 4 | Automated verification | EventBridge → Lambda | Seconds after restore |
| 5 | Confirm PASS | CloudWatch `VERIFICATION_RESULT=PASS` | Phase 4 evidence |

**Observed restore duration (Phase 4):** ~4 minutes for 10 synthetic records. Full RTO budget includes decision time, communication, and scale — the **4-hour RTO** is an operational target for a production home-health workload, not this micro-dataset.

## DR regions

| Role | Region | Vault |
|------|--------|-------|
| Primary | `us-east-1` | `home-healthcare-dr-primary` |
| DR copy | `us-west-2` | `home-healthcare-dr-copy` |

## Future automation (Phase 7 — optional)

Continuous RTO/RPO validation (custom Config rules, CloudWatch alarms on stale recovery points, scheduled restore drills) is planned as an optional extension — see `docs/ROADMAP.md`.
