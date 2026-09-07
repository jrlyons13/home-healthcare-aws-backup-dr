# Phase 1: Synthetic Patient Data Pipeline

Generates **synthetic only** home healthcare ePHI records for the backup/DR lab. No real patient data is used.

## Quick start

```powershell
cd phase1-synthetic-data
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt

python generate_patients.py --count 10 --output ./output --seed 42
python validate.py --output ./output
```

Expected output:

```text
Schema validation: PASS (10/10 records)
Manifest hash check: PASS
VERIFICATION_RESULT=PASS
```

## View the data

**In Cursor/VS Code:** open `output/patients/SYN-000001.json`

**In PowerShell:**

```powershell
Get-Content .\output\patients\SYN-000001.json | ConvertFrom-Json | ConvertTo-Json -Depth 10
Get-Content .\output\manifest.json | ConvertFrom-Json | ConvertTo-Json -Depth 5
```

**Sample records in repo:** see `samples/` (safe to browse on GitHub without running the generator).

## Files

| File | Purpose |
|------|---------|
| `generate_patients.py` | Creates JSON records + `manifest.json` with MD5/SHA-256 |
| `validate.py` | JSON Schema + manifest hash verification |
| `patient_record.schema.json` | Formal schema (Draft 2020-12) |
| `samples/` | Two example records committed for GitHub preview |
| `output/` | Local generated data (gitignored) |

## Record fields

Each record includes synthetic demographics, visit details, clinical data (ICD-10, care plan, medications), and metadata with `SYNTHETIC_EPHI_LAB_DATA_ONLY`.

Patient IDs use the `SYN-######` prefix; NPIs use the synthetic `999xxxxxxx` range.

See [docs/ROADMAP.md](../docs/ROADMAP.md) for Phase 1 validation gates.
