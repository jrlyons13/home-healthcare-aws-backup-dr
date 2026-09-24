# Lambda functions

## `verify_restore.py` (Phase 4)

Runs when EventBridge detects an AWS Backup **S3 restore job completed**. Validates restored objects against `manifest.json` (MD5/SHA-256).

## `rpo_freshness_config.py` (Phase 7)

AWS Config **custom rule** evaluator: latest **COMPLETED** S3 recovery point in a vault must be within **26 hours** (RPO monitoring).

## Build packages (before Terraform apply)

```powershell
cd scripts
.\build-lambda.ps1
```

Output: `lambda/dist/verify_restore.zip`, `lambda/dist/rpo_freshness_config.zip`

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
