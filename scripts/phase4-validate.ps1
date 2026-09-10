# Validate Phase 4 Lambda verification logs and sandbox objects.
param(
    [Parameter(Mandatory = $true)]
    [string]$LogGroupName,

    [Parameter(Mandatory = $true)]
    [string]$BucketName,

    [string]$PatientsPrefix = "patients",
    [string]$Region = "us-east-1",
    [int]$LookbackMinutes = 30
)

$ErrorActionPreference = "Continue"
$pass = $true

Write-Host "=== Phase 4 Validation ===" -ForegroundColor Cyan

Write-Host "`n[1] Restored patient objects present"
$patientObjects = aws s3 ls "s3://$BucketName/$PatientsPrefix/" --region $Region 2>&1
if ($LASTEXITCODE -eq 0 -and $patientObjects) {
    $count = ($patientObjects | Measure-Object -Line).Lines
    Write-Host "  PASS: $count object(s) under $PatientsPrefix/" -ForegroundColor Green
} else {
    Write-Host "  FAIL: No objects under $PatientsPrefix/" -ForegroundColor Red
    $pass = $false
}

Write-Host "`n[2] CloudWatch logs for VERIFICATION_RESULT"
$startMs = [int64]([DateTimeOffset]::UtcNow.AddMinutes(-1 * $LookbackMinutes).ToUnixTimeMilliseconds())
$logs = aws logs filter-log-events `
    --region $Region `
    --log-group-name $LogGroupName `
    --start-time $startMs `
    --filter-pattern "VERIFICATION_RESULT" `
    --output json 2>&1 | ConvertFrom-Json

if ($logs.events.Count -gt 0) {
    $latest = $logs.events[-1].message
    Write-Host "  Latest: $latest"
    if ($latest -match "VERIFICATION_RESULT=PASS") {
        Write-Host "  PASS" -ForegroundColor Green
    } else {
        Write-Host "  FAIL: Expected PASS" -ForegroundColor Red
        $pass = $false
    }
} else {
    Write-Host "  FAIL: No VERIFICATION_RESULT log lines found (wait a minute after restore)" -ForegroundColor Red
    $pass = $false
}

if ($pass) {
    Write-Host "`nVERIFICATION_RESULT=PASS" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nVERIFICATION_RESULT=FAIL" -ForegroundColor Red
    exit 1
}
