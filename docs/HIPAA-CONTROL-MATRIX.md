# HIPAA Technical Safeguards ↔ AWS Controls (Lab Mapping)

> **Disclaimer:** This matrix maps **technical controls implemented in this lab** to HIPAA Security Rule themes (45 CFR §164.312). It does not constitute a complete HIPAA compliance program. Organizational requirements (policies, risk analysis, training, BAA, physical safeguards) are out of scope.

## Summary

| HIPAA theme (§164.312) | Lab status | Primary AWS implementation |
|------------------------|------------|---------------------------|
| Access control | Implemented | IAM least-privilege, S3 bucket policies, KMS key policies |
| Audit controls | Implemented | CloudTrail (management + S3 data events), CloudWatch Logs |
| Integrity | Implemented | Manifest hashes, Lambda post-restore verification |
| Person/entity authentication | Partial (lab) | IAM users/roles; MFA recommended for production |
| Transmission security | Implemented | TLS enforced (`aws:SecureTransport`), SSE-KMS at rest |

---

## Control matrix

| ID | HIPAA reference | Requirement (summary) | AWS / repo control | Phase | Evidence |
|----|-----------------|----------------------|-------------------|-------|----------|
| AC-1 | §164.312(a)(1) | Unique user identification | IAM user `h.abdulkhaliq`; dedicated backup & operator roles | 2–4 | IAM policies in Terraform |
| AC-2 | §164.312(a)(1) | Emergency access procedure | Documented in `docs/runbooks/DR-SIMULATION.md` | 5 | Runbook |
| AC-3 | §164.312(a)(2)(i) | Access authorization | `home-healthcare-dr-ephi-operator` policy; backup role scoped to Backup API | 2–3 | Terraform |
| AC-4 | §164.312(a)(2)(ii) | Access establishment/modification | Infrastructure as Code (Terraform); git history | 2–4 | GitHub |
| AC-5 | §164.312(a)(2)(iii) | Workforce termination | *Production:* disable IAM access; *Lab:* N/A | — | — |
| AC-6 | §164.312(a)(2)(iv) | Automatic logoff | *Production:* session policies; *Lab:* N/A | — | — |
| AC-7 | §164.312(a)(1) | Encryption/decryption | CMK `alias/home-healthcare-dr-ephi`; SSE-KMS default on bucket | 2 | Phase 2 validation |
| AU-1 | §164.312(b) | Audit logging | CloudTrail `home-healthcare-dr-trail` with S3 data events | 2 | Phase 2 validation |
| AU-2 | §164.312(b) | Log review | CloudWatch Logs for Lambda verifier; CloudTrail log bucket | 4 | Phase 4 validation |
| AU-3 | §164.312(b) | Audit integrity | CloudTrail log file validation enabled | 2 | Terraform |
| IN-1 | §164.312(c)(1) | Mechanism to authenticate ePHI | Phase 1 manifest MD5/SHA-256; `validate.py` | 1 | Phase 1 evidence |
| IN-2 | §164.312(c)(1) | ePHI integrity | Lambda `verify_restore` on restore completion | 4 | Phase 4 evidence |
| IN-3 | §164.312(c)(2) | Mechanism to encrypt ePHI | SSE-KMS on S3; KMS key rotation enabled | 2 | Phase 2 validation |
| TS-1 | §164.312(e)(1) | Integrity controls in transit | S3 bucket policy denies non-HTTPS | 2 | Phase 2 validation |
| TS-2 | §164.312(e)(2)(ii) | Encryption in transit | TLS via `aws:SecureTransport` condition | 2 | Phase 2 validation |
| DR-1 | §164.308(a)(7)(ii)(B) | Data backup plan | AWS Backup plan + cross-region copy | 3 | Phase 3 evidence |
| DR-2 | §164.308(a)(7)(ii)(B) | Restore testing | Phase 4 restore + Phase 5 E2E simulation | 4–5 | Phase 5 evidence |
| DR-3 | Contingency | Immutable backups | Vault Lock on copy vault (us-west-2) | 3 | Delete denied test |

---

## Data handling in this lab

| Rule | Implementation |
|------|----------------|
| No real PHI | Synthetic data only; `SYNTHETIC_EPHI_LAB_DATA_ONLY` in metadata |
| Minimum necessary | Single lab bucket; scoped IAM policies |
| Disposal | Teardown runbook: delete recovery points after retention (Vault Lock limits apply) |

---

## Gaps for production (not in lab scope)

- AWS BAA executed for production accounts holding real ePHI
- MFA on privileged IAM users
- AWS Config HIPAA conformance pack (optional Phase 6)
- Continuous RTO/RPO monitoring (optional Phase 7)
- AWS Audit Manager assessment workflow
- Network segmentation (VPC endpoints, PrivateLink) if applicable
