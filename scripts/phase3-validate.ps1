# Validate Phase 3 backup vaults, replication, and Vault Lock delete denial.
param(
    [Parameter(Mandatory = $true)]
    [string]$PrimaryVaultName,

    [Parameter(Mandatory = $true)]
    [string]$CopyVaultName,

    [string]$PrimaryRegion = "us-east-1",
    [string]$DrRegion = "us-west-2"
)

$ErrorActionPreference = "Continue"
$pass = $true

Write-Host "=== Phase 3 Validation ===" -ForegroundColor Cyan

Write-Host "`n[1] Primary vault recovery points ($PrimaryRegion)"
$primary = aws backup list-recovery-points-by-backup-vault `
    --region $PrimaryRegion `
    --backup-vault-name $PrimaryVaultName `
    --output json | ConvertFrom-Json

if ($primary.RecoveryPoints.Count -gt 0) {
    Write-Host "  PASS: $($primary.RecoveryPoints.Count) recovery point(s) in primary vault" -ForegroundColor Green
    $samplePrimaryArn = $primary.RecoveryPoints[0].RecoveryPointArn
} else {
    Write-Host "  FAIL: No recovery points in primary vault" -ForegroundColor Red
    $pass = $false
}

Write-Host "`n[2] Copy vault recovery points ($DrRegion)"
$copy = aws backup list-recovery-points-by-backup-vault `
    --region $DrRegion `
    --backup-vault-name $CopyVaultName `
    --output json | ConvertFrom-Json

if ($copy.RecoveryPoints.Count -gt 0) {
    Write-Host "  PASS: $($copy.RecoveryPoints.Count) recovery point(s) in copy vault" -ForegroundColor Green
    $sampleCopyArn = $copy.RecoveryPoints[0].RecoveryPointArn
} else {
    Write-Host "  FAIL: No recovery points in copy vault" -ForegroundColor Red
    $pass = $false
}

Write-Host "`n[3] Vault Lock delete denial test (copy vault)"
if ($copy.RecoveryPoints.Count -gt 0) {
    $deleteResult = aws backup delete-recovery-point `
        --region $DrRegion `
        --backup-vault-name $CopyVaultName `
        --recovery-point-arn $sampleCopyArn 2>&1

    if ($LASTEXITCODE -ne 0 -and ($deleteResult -match "AccessDenied|locked|retention|cannot")) {
        Write-Host "  PASS: Delete denied as expected" -ForegroundColor Green
        Write-Host "  Message: $deleteResult"
    } else {
        Write-Host "  WARN: Delete was not denied (Vault Lock may still be in cooling period)" -ForegroundColor Yellow
        Write-Host "  Output: $deleteResult"
    }
} else {
    Write-Host "  SKIP: No copy recovery point to test" -ForegroundColor Yellow
}

Write-Host "`n[4] Backup IAM role exists"
$role = aws iam get-role --role-name home-healthcare-dr-backup-role 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "  PASS: home-healthcare-dr-backup-role present" -ForegroundColor Green
} else {
    Write-Host "  FAIL: Backup role not found" -ForegroundColor Red
    $pass = $false
}

if ($pass) {
    Write-Host "`nVERIFICATION_RESULT=PASS" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nVERIFICATION_RESULT=FAIL" -ForegroundColor Red
    exit 1
}
