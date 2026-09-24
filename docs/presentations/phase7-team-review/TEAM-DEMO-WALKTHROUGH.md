# Team Demo Walkthrough — Step-by-Step (Phase 6)

Use this guide with **Home-Healthcare-AWS-Backup-DR-Phase6-Team-Deck.pptx** (speaker notes: View → Notes).

**Scope:** Phases 0–6 including AWS Config HIPAA conformance pack (`CONFIG_PHASE6=PASS`).

**Duration:** ~50–65 minutes (21 slides + live demo)

**Before the meeting**

- [ ] AWS console login (us-east-1; us-west-2 optional for DR recap)
- [ ] AWS CLI configured (`aws sts get-caller-identity`)
- [ ] GitHub: https://github.com/jrlyons13/home-healthcare-aws-backup-dr
- [ ] Terminal at `...\home-healthcare-aws-backup-dr\scripts`

---

## Part A — Story (slides 1–15) ~18 min

1. **Home healthcare + HIPAA** — availability, integrity, audit evidence
2. **Synthetic lab only**
3. **Phases 0–6** — incremental validation; Phase 6 adds continuous config compliance
4. **Outcomes** — DR path proven (Phase 5) + Config monitoring (Phase 6)

---

## Part B — GitHub tour ~5 min

| Step | Action | What to say |
|------|--------|-------------|
| 1 | README phase table | Phases 0–6 **Complete** |
| 2 | `docs/evidence/phase6-validation.md` | `CONFIG_PHASE6=PASS` |
| 3 | `terraform/environments/phase6/` | Recorder, delivery bucket, conformance pack |
| 4 | `docs/HIPAA-CONTROL-MATRIX.md` | Config pack mapped to audit readiness |
| 5 | `scripts/phase6-validate.ps1` | Automated validation gates |

---

## Part C — AWS Config (primary demo) ~15 min

### C1. Conformance pack

1. **Region:** us-east-1
2. **AWS Config → Conformance packs**
3. Open **`home-healthcare-dr-hipaa-security`**
4. Show status **CREATE_COMPLETE** and compliance summary (many account-wide non-compliant findings are **expected** in a lab)

### C2. ePHI bucket compliance

1. **AWS Config → Resources** (or compliance dashboard)
2. Resource type **AWS::S3::Bucket** → **`home-healthcare-dr-ephi-376873818584`**
3. Highlight **COMPLIANT** rules (e.g. public read/write prohibited)
4. Tie back to Phase 2 hardening (encryption, BPA, HTTPS policy)

### C3. Recorder and delivery (optional deep dive)

1. **Settings → Recorders** → `home-healthcare-dr-config-recorder` (recording)
2. **Delivery channel** → S3 `home-healthcare-dr-config-376873818584`

---

## Part D — CLI validation ~5 min

```powershell
cd C:\Users\jlyons\Projects\home-healthcare-aws-backup-dr\scripts
.\phase6-validate.ps1
```

Expected: **`CONFIG_PHASE6=PASS`**

If execution policy blocks scripts:

```powershell
powershell -ExecutionPolicy Bypass -File .\phase6-validate.ps1
```

---

## Part E — Optional DR recap (short) ~10 min

If audience wants backup/restore proof, use Phase 5 paths:

- S3 ePHI bucket encryption, Backup vaults east/west, Lambda `VERIFICATION_RESULT=PASS`
- `.\phase5-e2e-simulation.ps1` → `E2E_DR_SIMULATION=PASS`

See [../phase5-team-review/TEAM-DEMO-WALKTHROUGH.md](../phase5-team-review/TEAM-DEMO-WALKTHROUGH.md) for full DR console click paths.

---

## Part F — Q&A prep

| Question | Short answer |
|----------|--------------|
| Why so many non-compliant Config rules? | HIPAA pack is **account-wide**; lab skips IAM password policy, unused services, etc. |
| Does Config replace Phase 5 testing? | **No** — backup/restore/E2E still prove DR; Config adds **ongoing** posture checks. |
| Phase 7? | RTO/RPO monitoring, custom Config rules, alarms. |

---

## Part G — After the meeting

- Share Phase **6** deck for Config story; Phase **5** deck for DR-only audiences
- Link `docs/evidence/phase6-validation.md`
