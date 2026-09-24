"""Phase 5 team deck — frozen snapshot through E2E simulation (do not overwrite for Phase 6)."""

from __future__ import annotations

import sys
from pathlib import Path

_PRESENTATIONS = Path(__file__).resolve().parent.parent
if str(_PRESENTATIONS) not in sys.path:
    sys.path.insert(0, str(_PRESENTATIONS))

from theme import build_presentation  # noqa: E402

OUTPUT = Path(__file__).parent / "Home-Healthcare-AWS-Backup-DR-Phase5-Team-Deck.pptx"
FOOTER_LEFT = "HOME HEALTHCARE AWS BACKUP/DR • PHASE 5 TEAM REVIEW"

SLIDES: list[dict] = [
    {
        "layout": "hero",
        "title": "Home Healthcare Backup, Restore & DR on AWS",
        "subtitle": "HIPAA-aligned lab -> GitHub + Terraform + live demo",
        "notes": "Open with synthetic-data disclaimer. Goal: show phases 0-5 and demo AWS/GitHub.",
    },
    {
        "layout": "cards",
        "title": "Agenda",
        "subtitle": "45-60 minutes -> story, demo, Q&A",
        "cards": [
            {"label": "CONTEXT", "body": "Why DR matters for home healthcare and how HIPAA technical safeguards map to AWS.", "accent": "teal"},
            {"label": "ARCHITECTURE", "body": "Walk phases 1-5: data, encryption, backup, restore verification, audit docs.", "accent": "teal"},
            {"label": "LIVE DEMO", "body": "GitHub repo tour + AWS console + phase5-e2e-simulation.ps1 (PASS).", "accent": "orange"},
        ],
        "notes": "Timing: ~15 min slides, ~25 min demo, ~10 min Q&A.",
    },
    {
        "layout": "cards",
        "title": "Business context",
        "subtitle": "Home healthcare ePHI -> availability + integrity",
        "cards": [
            {"label": "THE DATA", "body": "Visit records, care plans, billing — all ePHI requiring protection.", "accent": "teal"},
            {"label": "THE RISK", "body": "Ransomware, accidental deletion, regional outages threaten continuity.", "accent": "teal"},
            {"label": "THE GOAL", "body": "Provable backup, immutable DR copies, tested restore, audit evidence.", "accent": "orange"},
        ],
        "notes": "BAA required for real PHI in production; not in scope for this lab.",
    },
    {
        "layout": "bullets",
        "title": "Lab scope & disclaimer",
        "subtitle": "Synthetic data only — portfolio-grade reference architecture",
        "bullets": [
            "Synthetic patient IDs (SYN-*) — no real PHI in GitHub or S3",
            "Regions: primary us-east-1, DR copy us-west-2",
            "IaC: Terraform remote state, incremental GitHub commits per phase",
            "Phases 0-5 complete | Phase 6 (AWS Config) planned next",
        ],
        "notes": "Production gaps: MFA, Audit Manager, multi-account, Config pack.",
    },
    {
        "layout": "cards",
        "title": "Architecture pipeline",
        "subtitle": "Incremental validation at every phase",
        "cards": [
            {"label": "INGEST", "body": "Phase 1-2: Synthetic ePHI + manifest hashes -> encrypted S3 (SSE-KMS).", "accent": "teal"},
            {"label": "PROTECT", "body": "Phase 3: AWS Backup, cross-region copy, Vault Lock (WORM).", "accent": "teal"},
            {"label": "PROVE", "body": "Phase 4-5: Restore -> Lambda verify -> E2E audit PASS.", "accent": "orange"},
        ],
        "notes": "Use README ASCII diagram if helpful.",
    },
    {
        "layout": "bullets",
        "title": "Key AWS resources",
        "subtitle": "Console bookmarks for live demo",
        "bullets": [
            "S3: home-healthcare-dr-ephi-376873818584",
            "KMS: alias/home-healthcare-dr-ephi",
            "Vaults: home-healthcare-dr-primary (east), home-healthcare-dr-copy (west)",
            "Lambda: home-healthcare-dr-verify-restore | Trail: home-healthcare-dr-trail",
        ],
        "notes": "Verify names in Terraform outputs if account was rebuilt.",
    },
    {
        "layout": "bullets",
        "title": "GitHub repository",
        "subtitle": "github.com/jrlyons13/home-healthcare-aws-backup-dr",
        "bullets": [
            "docs/evidence/ — phase validation logs (PASS criteria)",
            "terraform/environments/ — phase2, phase3, phase4 stacks",
            "scripts/ — upload, backup, restore, E2E simulation",
            "Commit style: feat(phaseN) for traceability",
        ],
        "notes": "DEMO: README, ROADMAP, phase3/4 evidence files.",
    },
    {
        "layout": "cards",
        "title": "Phase 1 — Synthetic data",
        "subtitle": "Local pipeline -> integrity baseline",
        "cards": [
            {"label": "GENERATE", "body": "Python + JSON Schema; home-health visit fields.", "accent": "teal"},
            {"label": "MANIFEST", "body": "MD5/SHA-256 per object for restore verification.", "accent": "teal"},
            {"label": "VALIDATE", "body": "validate.py -> VERIFICATION_RESULT=PASS (10/10).", "accent": "orange"},
        ],
        "notes": "Show samples/SYN-000001.json on GitHub.",
    },
    {
        "layout": "cards",
        "title": "Phase 2 — Encrypted storage",
        "subtitle": "us-east-1 foundation",
        "cards": [
            {"label": "KMS CMK", "body": "Customer managed key, rotation enabled, S3 + Backup policies.", "accent": "teal"},
            {"label": "S3 HARDENING", "body": "Versioning, Block Public Access, HTTPS-only policy.", "accent": "teal"},
            {"label": "AUDIT", "body": "CloudTrail S3 data events + Terraform remote state.", "accent": "orange"},
        ],
        "notes": "DEMO: head-object shows aws:kms.",
    },
    {
        "layout": "cards",
        "title": "Phase 3 — Backup & DR",
        "subtitle": "Immutable copies in us-west-2",
        "cards": [
            {"label": "BACKUP ROLE", "body": "Terraform-created IAM role with S3 backup policies.", "accent": "teal"},
            {"label": "CROSS-REGION", "body": "Daily plan + copy to home-healthcare-dr-copy vault.", "accent": "teal"},
            {"label": "VAULT LOCK", "body": "Delete recovery point -> AccessDenied (WORM).", "accent": "orange"},
        ],
        "notes": "DEMO both regions in AWS Backup console.",
    },
    {
        "layout": "cards",
        "title": "Phase 4 — Restore verify",
        "subtitle": "EventBridge -> Lambda automation",
        "cards": [
            {"label": "RESTORE", "body": "AWS Backup restores to patients/ keys (versioned).", "accent": "teal"},
            {"label": "TRIGGER", "body": "EventBridge on restore status=COMPLETED.", "accent": "teal"},
            {"label": "VERIFY", "body": "CloudWatch: VERIFICATION_RESULT=PASS records=10.", "accent": "orange"},
        ],
        "notes": "DEMO Lambda, rule, log group.",
    },
    {
        "layout": "cards",
        "title": "Phase 5 — Audit package",
        "subtitle": "Portfolio + compliance mapping",
        "cards": [
            {"label": "HIPAA MATRIX", "body": "docs/HIPAA-CONTROL-MATRIX.md maps §164.312 controls.", "accent": "teal"},
            {"label": "RTO / RPO", "body": "24h RPO / 4h RTO design targets documented.", "accent": "teal"},
            {"label": "E2E PASS", "body": "phase5-e2e-simulation.ps1 -> all checks green.", "accent": "orange"},
        ],
        "notes": "Run E2E script live if possible.",
    },
    {
        "layout": "bullets",
        "title": "HIPAA technical safeguards",
        "subtitle": "Demonstrated controls (not full organizational compliance)",
        "bullets": [
            "Access control — IAM, KMS, bucket policies",
            "Audit controls — CloudTrail, CloudWatch Logs",
            "Integrity — manifest hashes + Lambda verifier",
            "Transmission security — TLS-only (aws:SecureTransport)",
            "Contingency — backup, cross-region copy, Vault Lock",
        ],
        "notes": "Organizational HIPAA still needs policies, training, BAA, risk analysis.",
    },
    {
        "layout": "cards",
        "title": "RTO / RPO targets",
        "subtitle": "Lab design vs observed restore test",
        "cards": [
            {"label": "RPO 24H", "body": "Daily backup schedule 06:00 UTC.", "accent": "teal"},
            {"label": "RTO 4H", "body": "Operational target; ~4 min restore for 10 files in lab.", "accent": "teal"},
            {"label": "PHASE 7", "body": "Future: automated RTO/RPO monitoring + alarms.", "accent": "orange"},
        ],
        "notes": "See docs/RTO-RPO.md.",
    },
    {
        "layout": "cards",
        "title": "Live demo — GitHub",
        "subtitle": "5 minutes -> evidence & IaC",
        "cards": [
            {"label": "STEP 1", "body": "README architecture + completed phase table.", "accent": "teal"},
            {"label": "STEP 2", "body": "docs/evidence phase3 + phase4 validation.", "accent": "teal"},
            {"label": "STEP 3", "body": "terraform/ + lambda/verify_restore.py.", "accent": "orange"},
        ],
        "notes": "git log --oneline for commit history.",
    },
    {
        "layout": "cards",
        "title": "Live demo — AWS Console",
        "subtitle": "15 minutes -> east + west regions",
        "cards": [
            {"label": "STORAGE", "body": "S3 encryption + KMS key rotation.", "accent": "teal"},
            {"label": "BACKUP", "body": "Recovery points in primary + copy vaults.", "accent": "teal"},
            {"label": "VERIFY", "body": "Lambda logs: VERIFICATION_RESULT=PASS.", "accent": "orange"},
        ],
        "notes": "See TEAM-DEMO-WALKTHROUGH.md in this folder for click paths.",
    },
    {
        "layout": "cards",
        "title": "Live demo — CLI",
        "subtitle": "Quick proof close",
        "cards": [
            {"label": "CD", "body": "scripts/", "accent": "teal"},
            {"label": "RUN", "body": ".\\phase5-e2e-simulation.ps1", "accent": "teal"},
            {"label": "EXPECT", "body": "E2E_DR_SIMULATION=PASS", "accent": "orange"},
        ],
        "notes": "Fallback: docs/evidence/phase5-e2e-simulation.md",
    },
    {
        "layout": "bullets",
        "title": "Results & evidence",
        "subtitle": "All phases validated",
        "bullets": [
            "Cross-region recovery points confirmed",
            "Vault Lock deletion denied (WORM)",
            "Post-restore integrity: 10/10 PASS",
            "Documented evidence in docs/evidence/",
        ],
        "notes": "Confidence: backup, copy, restore, prove integrity.",
    },
    {
        "layout": "cards",
        "title": "What's next",
        "subtitle": "Phase 6 & 7 roadmap",
        "cards": [
            {"label": "PHASE 6", "body": "AWS Config HIPAA conformance pack — continuous compliance.", "accent": "teal"},
            {"label": "PHASE 7", "body": "RTO/RPO alarms + custom Config rules.", "accent": "teal"},
            {"label": "PROD", "body": "MFA, Audit Manager, multi-account hardening.", "accent": "orange"},
        ],
        "notes": "Ask team priority: Config vs operational monitoring.",
    },
    {
        "layout": "hero",
        "title": "Questions?",
        "subtitle": "github.com/jrlyons13/home-healthcare-aws-backup-dr",
        "notes": "Thank team. Share deck + walkthrough doc.",
    },
]


def main() -> None:
    build_presentation(SLIDES, OUTPUT, footer_left=FOOTER_LEFT)
    print(f"Wrote {OUTPUT} ({len(SLIDES)} slides, themed)")


if __name__ == "__main__":
    main()
