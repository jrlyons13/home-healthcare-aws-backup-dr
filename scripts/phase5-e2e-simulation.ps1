# Phase 5: End-to-end DR readiness and validation summary.
param(
    [string]$BucketName = "home-healthcare-dr-ephi-376873818584",
    [string]$PrimaryVault = "home-healthcare-dr-primary",
    [string]$CopyVault = "home-healthcare-dr-copy",
    [string]$PrimaryRegion = "us-east-1",
    [string]$DrRegion = "us-west-2",
    [string]$KmsKeyArn = "arn:aws:kms:us-east-1:376873818584:key/5e861884-e3a6-473e-9af9-299abb2160e5",
    [string]$LambdaName = "home-healthcare-dr-verify-restore",
    [string]$LogGroup = "/aws/lambda/home-healthcare-dr-verify-restore"
)

$ErrorActionPreference = "Continue"
$pass = $true
$started = Get-Date

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Phase 5: E2E DR Simulation / Audit" -ForegroundColor Cyan
Write-Host " Started: $started" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

function Test-Step {
    param([string]$Name, [scriptblock]$Check)
    Write-Host "`n[$Name]" -ForegroundColor Yellow
    try {
        $result = & $Check
        if ($result) {
            Write-Host "  PASS" -ForegroundColor Green
            return $true
        }
        Write-Host "  FAIL" -ForegroundColor Red
        return $false
    } catch {
        Write-Host "  FAIL: $_" -ForegroundColor Red
        return $false
    }
}

if (-not (Test-Step "Phase 2: S3 encryption (SSE-KMS)" {
        $h = aws s3api head-object --bucket $BucketName --key "patients/SYN-000001.json" --region $PrimaryRegion | ConvertFrom-Json
        $h.ServerSideEncryption -eq "aws:kms"
    })) { $pass = $false }

if (-not (Test-Step "Phase 2: CloudTrail trail active" {
        $t = aws cloudtrail describe-trails --region $PrimaryRegion --trail-name-list home-healthcare-dr-trail | ConvertFrom-Json
        $t.trailList.Count -ge 1
    })) { $pass = $false }

if (-not (Test-Step "Phase 3: Primary vault recovery points" {
        $r = aws backup list-recovery-points-by-backup-vault --region $PrimaryRegion --backup-vault-name $PrimaryVault | ConvertFrom-Json
        $r.RecoveryPoints.Count -gt 0
    })) { $pass = $false }

if (-not (Test-Step "Phase 3: Copy vault recovery points (DR)" {
        $r = aws backup list-recovery-points-by-backup-vault --region $DrRegion --backup-vault-name $CopyVault | ConvertFrom-Json
        $r.RecoveryPoints.Count -gt 0
    })) { $pass = $false }

if (-not (Test-Step "Phase 4: Lambda function deployed" {
        aws lambda get-function --region $PrimaryRegion --function-name $LambdaName 2>$null | Out-Null
        $LASTEXITCODE -eq 0
    })) { $pass = $false }

if (-not (Test-Step "Phase 4: Recent VERIFICATION_RESULT=PASS in logs" {
        $stream = aws logs describe-log-streams --region $PrimaryRegion --log-group-name $LogGroup `
            --order-by LastEventTime --descending --limit 1 `
            --query "logStreams[0].logStreamName" --output text
        if (-not $stream -or $stream -eq "None") { return $false }
        $events = aws logs get-log-events --region $PrimaryRegion --log-group-name $LogGroup `
            --log-stream-name $stream --limit 20 --no-start-from-head --output json | ConvertFrom-Json
        @($events.events | Where-Object { $_.message -match "VERIFICATION_RESULT=PASS" }).Count -gt 0
    })) { $pass = $false }

if (-not (Test-Step "Phase 1: Manifest present in S3" {
        aws s3api head-object --bucket $BucketName --key "manifest.json" --region $PrimaryRegion 2>$null | Out-Null
        $LASTEXITCODE -eq 0
    })) { $pass = $false }

$finished = Get-Date
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " Completed: $finished" -ForegroundColor Cyan
Write-Host " Duration:  $($finished - $started)" -ForegroundColor Cyan

if ($pass) {
    Write-Host " E2E_DR_SIMULATION=PASS" -ForegroundColor Green
    exit 0
} else {
    Write-Host " E2E_DR_SIMULATION=FAIL" -ForegroundColor Red
    exit 1
}
