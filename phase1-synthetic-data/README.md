# Phase 1: Synthetic Patient Data Pipeline

This directory will contain:

- `generate_patients.py` — generates synthetic home healthcare ePHI records
- `patient_record.schema.json` — formal JSON Schema for validation
- `manifest.json` — per-object MD5/SHA-256 hashes (generated locally)

Generated output is written to `output/` (gitignored). See [docs/ROADMAP.md](../docs/ROADMAP.md).
