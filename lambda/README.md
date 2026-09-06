# Lambda: Restore Integrity Verifier

Phase 4 adds `verify_restore.py` — triggered by EventBridge on AWS Backup restore completion to validate restored objects against the Phase 1 manifest (JSON Schema + checksums).
