# Lambda: Restore Integrity Verifier

`verify_restore.py` runs when EventBridge detects an AWS Backup **S3 restore job completed**. It validates objects under `restore-sandbox/` against the baseline `manifest.json` at the bucket root (JSON Schema + MD5/SHA-256).

## Build package (before Terraform apply)

```powershell
cd scripts
.\build-lambda.ps1
```

Output: `lambda/dist/verify_restore.zip`

## Environment variables (set by Terraform)

| Variable | Example |
|----------|---------|
| `BUCKET_NAME` | `home-healthcare-dr-ephi-376873818584` |
| `SANDBOX_PREFIX` | `restore-sandbox` |
| `MANIFEST_KEY` | `manifest.json` |

## Log output

```text
VERIFICATION_RESULT=PASS
```

or

```text
VERIFICATION_RESULT=FAIL
```
