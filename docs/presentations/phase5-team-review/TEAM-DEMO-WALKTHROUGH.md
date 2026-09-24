# Team Demo Walkthrough — Step-by-Step (Phase 5)

Use this guide with **Home-Healthcare-AWS-Backup-DR-Phase5-Team-Deck.pptx** (speaker notes in PowerPoint: View → Notes).

**Snapshot:** Phases 0–5 complete (E2E simulation PASS). This folder stays unchanged when Phase 6 materials are added.

**Duration:** ~45–60 minutes (20 slides + live demo)

**Before the meeting**

- [ ] AWS console login (us-east-1 and us-west-2)
- [ ] AWS CLI configured (`aws sts get-caller-identity`)
- [ ] GitHub: https://github.com/jrlyons13/home-healthcare-aws-backup-dr
- [ ] Terminal open at `...\home-healthcare-aws-backup-dr\scripts`
- [ ] Optional: second monitor for CLI while sharing console

---

## Part A — Story (slides 1–14) ~15 min

Follow the deck narrative. Hit these talking points:

1. **Home healthcare + HIPAA** — availability and integrity of ePHI
2. **Synthetic lab only** — no real patient data
3. **Five phases** — each validated before the next
4. **Outcome** — backup, immutable DR copy, restore, automated verification

---

## Part B — GitHub tour (slide 15) ~5 min

| Step | Action | What to say |
|------|--------|-------------|
| 1 | Open repo README | Architecture diagram; all phases **Complete** |
| 2 | Open `docs/ROADMAP.md` | Incremental roadmap; Phase 6/7 optional |
| 3 | Open `docs/evidence/phase3-validation.md` | Vault Lock delete denied |
| 4 | Open `docs/evidence/phase4-validation.md` | Lambda `VERIFICATION_RESULT=PASS` |
| 5 | Open `docs/HIPAA-CONTROL-MATRIX.md` | Maps controls to §164.312 |
| 6 | Browse `terraform/environments/` | IaC: phase2, phase3, phase4 separate state |
| 7 | Open `lambda/verify_restore.py` | Post-restore hash check logic |
| 8 | `git log --oneline -10` (local clone) | Phase-by-phase commit history |

---

## Part C — AWS Console (slide 16) ~15 min

### C1. S3 — primary data bucket

1. **Console:** S3 → `home-healthcare-dr-ephi-376873818584`
2. **Objects:** `patients/` (10 JSON files), `manifest.json`
3. **Properties → Bucket versioning:** Enabled
4. **Properties → Default encryption:** SSE-KMS, key `home-healthcare-dr-ephi`
5. **Permissions → Block Public Access:** All on

**CLI (optional):**

```powershell
aws s3 ls s3://home-healthcare-dr-ephi-376873818584/patients/ --region us-east-1
aws s3api head-object --bucket home-healthcare-dr-ephi-376873818584 --key patients/SYN-000001.json --region us-east-1
```

Point out `ServerSideEncryption: aws:kms`.

---

### C2. KMS

1. **Console:** KMS → Customer managed keys → `alias/home-healthcare-dr-ephi`
2. Show **Key rotation:** Enabled
3. **Key policy:** S3, Backup, account root (high level — don’t read entire JSON)

---

### C3. CloudTrail

1. **Console:** CloudTrail → Trails → `home-healthcare-dr-trail`
2. **Log file validation:** Enabled
3. **Event selectors:** S3 data events on ePHI bucket

---

### C4. AWS Backup — primary region (us-east-1)

1. **Region:** N. Virginia (us-east-1)
2. **Backup → Backup vaults** → `home-healthcare-dr-primary`
3. **Recovery points:** Show at least one S3 recovery point
4. **Backup plans** → `home-healthcare-dr-ephi-plan` → daily schedule + copy action

---

### C5. AWS Backup — DR region (us-west-2)

1. **Switch region** to Oregon (us-west-2)
2. **Backup vaults** → `home-healthcare-dr-copy`
3. **Recovery points:** Copied recovery point from east
4. **Vault Lock:** Mention min retention 7 days, delete test showed lock message (Phase 3 evidence)

---

### C6. Lambda + EventBridge (us-east-1)

1. **Lambda** → `home-healthcare-dr-verify-restore`
2. **Configuration → Environment variables:** BUCKET_NAME, MANIFEST_KEY
3. **EventBridge → Rules** → `home-healthcare-dr-restore-completed`
4. **Targets:** Lambda function
5. **CloudWatch → Log groups** → `/aws/lambda/home-healthcare-dr-verify-restore`
6. Open latest log stream → find `VERIFICATION_RESULT=PASS records=10`

---

## Part D — CLI E2E audit (slide 17) ~5 min

```powershell
cd C:\Users\jlyons\Projects\home-healthcare-aws-backup-dr\scripts
.\phase5-e2e-simulation.ps1
```

**Expected:**

```text
E2E_DR_SIMULATION=PASS
```

If live demo fails (credentials/network), show pre-recorded output in `docs/evidence/phase5-e2e-simulation.md`.

---

## Part E — Optional “deep dive” demos (if time)

| Demo | Command / action | Risk |
|------|------------------|------|
| List DR recovery points | `aws backup list-recovery-points-by-backup-vault --region us-west-2 --backup-vault-name home-healthcare-dr-copy` | Read-only |
| Invoke Lambda test | See Phase 4 evidence (restore already validated) | Low |
| New restore job | `phase4-trigger-restore.ps1` | ~4 min wait; overwrites versions |

**Skip in short meetings:** full restore job (takes several minutes).

---

## Part F — Q&A prep (common questions)

| Question | Short answer |
|----------|--------------|
| Is this HIPAA compliant? | Demonstrates **technical safeguards**; full compliance needs policies, BAA, risk analysis, MFA, etc. |
| Real PHI? | **No** — synthetic `SYN-*` records only |
| RPO/RTO? | Design targets 24h / 4h; see `docs/RTO-RPO.md` |
| Why Vault Lock? | WORM — ransomware/insider can’t delete backups before retention |
| Why Lambda after restore? | Proves restored data matches manifest (integrity) |
| What’s Phase 6? | AWS Config HIPAA conformance pack for continuous config checks |

---

## Part G — After the meeting

- Share `.pptx` and link to GitHub repo
- Point team to `docs/runbooks/DR-SIMULATION.md` for hands-on practice
- Capture feedback on Phase 6 priority (Config vs RTO/RPO monitoring)
