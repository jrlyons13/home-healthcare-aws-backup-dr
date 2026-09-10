# 5-Phase Incremental Roadmap

Building and validating phase-by-phase ensures each security boundary is verified before adding complexity.

```text
[Phase 0: GitHub bootstrap] ──► [Phase 1: Synthetic data]
                                        │
                                        ▼
                               [Phase 2: S3 + KMS + Terraform]
                                        │
                                        ▼
                               [Phase 3: Backup + Vault Lock + CRR]
                                        │
                                        ▼
                               [Phase 4: Lambda verification]
                                        │
                                        ▼
                               [Phase 5: E2E audit + portfolio docs]
```

## Phase 0: GitHub Bootstrap

**Goal:** Initialize repository structure, documentation, and remote on GitHub.

**Deliverables:**
- `.gitignore`, `README.md`, folder scaffolding
- `docs/ROADMAP.md`
- GitHub remote under `jrlyons13`

**Validation:** Repo visible on GitHub; clone works; README renders roadmap.

---

## Phase 1: Synthetic Patient Data Pipeline

**Goal:** Local Python script generates realistic synthetic ePHI records in JSON format with formal schema validation and a hash manifest.

**Deliverables:**
- `generate_patients.py`
- `patient_record.schema.json`
- `manifest.json` (per-object MD5/SHA-256)
- `docs/evidence/phase1-validation.md`

**Validation:**
- JSON Schema validation passes
- Manifest hashes match generated files
- No real PHI; synthetic IDs prefixed (e.g. `SYN-`)

**GitHub:** Commit generator + schema; exclude large generated datasets (regenerate locally).

---

## Phase 2: Core S3 & KMS Infrastructure (Terraform)

**Goal:** Deploy primary S3 bucket in `us-east-1` with KMS CMK, versioning, Block Public Access, default SSE-KMS, HTTPS-only bucket policy, CloudTrail S3 data events, and secure Terraform remote state.

**Deliverables:**
- `terraform/` modules for S3, KMS, IAM, CloudTrail
- Upload synthetic records + manifest from Phase 1
- `docs/evidence/phase2-validation.md`
- Optional: `.github/workflows/terraform-checkov.yml`

**Validation:**
- `head-object` shows SSE-KMS with CMK ARN
- Unencrypted HTTP PUT denied
- CloudTrail logs upload events

---

## Phase 3: Secondary Vault, Vault Lock & Cross-Region Replication

**Goal:** AWS Backup plan protecting the Phase 2 S3 bucket; primary vault in `us-east-1`; copy vault in `us-west-2` with Vault Lock (Compliance mode).

**Deliverables:**
- Terraform for backup vaults, backup plan, copy action
- `docs/runbooks/backup-and-replication.md`
- `docs/evidence/phase3-validation.md`

**Validation:**
- On-demand backup job completes
- Recovery point replicates to `us-west-2`
- Force delete on copy vault recovery point → `AccessDeniedException`

**Notes:**
- AWS Backup for S3 requires advanced/cross-region features
- Vault Lock has a mandatory cooling period before full enforcement

---

## Phase 4: Serverless Integrity Verification & EventBridge Automation

**Goal:** EventBridge triggers Lambda on restore completion; verifier compares restored objects against Phase 1 manifest (schema + hashes).

**Deliverables:**
- `lambda/verify_restore.py`
- Terraform for EventBridge, IAM, SNS (optional alerting)
- `docs/evidence/phase4-validation.md`

**Validation:**
- Restore to sandbox prefix triggers Lambda automatically
- CloudWatch logs show `VERIFICATION_RESULT=PASS`
- Intentional corrupt file → `VERIFICATION_RESULT=FAIL`

---

## Phase 5: End-to-End Audit & Portfolio Capture

**Goal:** Full DR simulation with compliance documentation and portfolio artifacts.

**Deliverables:**
- `docs/HIPAA-CONTROL-MATRIX.md`
- `docs/RTO-RPO.md`
- `docs/runbooks/DR-SIMULATION.md`
- `docs/evidence/phase5-e2e-simulation.md`
- Polished README with architecture diagram
- `scripts/phase5-e2e-simulation.ps1`

**Validation:**
- `E2E_DR_SIMULATION=PASS` (cross-phase health audit)
- HIPAA safeguard mapping complete
- Restore → verify path documented (Phases 3–4 evidence)

**Status:** Complete

---

## Optional future phases (not started)

### Phase 6: AWS Config HIPAA Conformance Pack

- Deploy Config conformance pack (Operational Best Practices for HIPAA Security)
- Continuous configuration compliance monitoring
- Evidence integration for audit readiness

### Phase 7: RTO/RPO Operational Monitoring

- Custom Config rules (e.g. recovery point freshness vs RPO)
- CloudWatch alarms on backup/restore/copy failures
- Scheduled restore drill metrics

---

## Commit convention

```text
chore: initialize repo and phase roadmap
feat(phase1): add synthetic ePHI generator and JSON schema
feat(phase2): deploy encrypted S3 bucket with KMS and CloudTrail
feat(phase3): add cross-region backup vault with Vault Lock
feat(phase4): add EventBridge-triggered restore verification Lambda
docs(phase5): add E2E DR simulation evidence and HIPAA control matrix
```
