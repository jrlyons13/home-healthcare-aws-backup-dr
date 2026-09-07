# Phase 1: Synthetic Patient Data Pipeline — Validation

**Date:** 2026-09-07

## Objective

Generate synthetic home healthcare ePHI records locally, validate JSON Schema integrity, and confirm MD5/SHA-256 manifest hashes.

## Commands run

```powershell
cd phase1-synthetic-data
pip install -r requirements.txt
python generate_patients.py --count 10 --output ./output --seed 42
python validate.py --output ./output
```

## Results

```text
Generated 10 records in ...\phase1-synthetic-data\output
Manifest: ...\phase1-synthetic-data\output\manifest.json
Manifest SHA-256: 9df40218c8df3c5a134d3625b265749be3cb63ef271011ae0d0e2c024d63dd0a
Schema validation: PASS (10/10 records)
Manifest hash check: PASS
VERIFICATION_RESULT=PASS
```

## Checklist

- [x] `generate_patients.py` creates JSON records under `output/patients/`
- [x] `patient_record.schema.json` validates all generated records
- [x] `manifest.json` includes per-object MD5 and SHA-256 hashes
- [x] `validate.py` confirms schema + hash integrity
- [x] Sample records committed under `samples/` for GitHub preview
- [x] Full generated dataset remains gitignored in `output/`

## Data inspection

| Method | Path / command |
|--------|----------------|
| Browse on GitHub | `phase1-synthetic-data/samples/SYN-000001.json` |
| Local JSON files | `phase1-synthetic-data/output/patients/SYN-*.json` |
| Manifest | `phase1-synthetic-data/output/manifest.json` |
| Pretty-print (PowerShell) | `Get-Content .\output\patients\SYN-000001.json \| ConvertFrom-Json \| ConvertTo-Json -Depth 10` |

## Notes

- All patient IDs use `SYN-######` prefix; NPIs use synthetic `999xxxxxxx` range
- `metadata.synthetic_data_notice` = `SYNTHETIC_EPHI_LAB_DATA_ONLY`
- Manifest will be uploaded to S3 in Phase 2 for Phase 4 restore verification

## Next step

Phase 2 — Core S3 & KMS infrastructure (Terraform).
