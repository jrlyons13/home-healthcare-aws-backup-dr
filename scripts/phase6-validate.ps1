# Phase 6: AWS Config recorder + HIPAA conformance pack validation.
param(
    [string]$Region = "us-east-1",
    [string]$ConfigBucketName = "home-healthcare-dr-config-376873818584",
    [string]$RecorderName = "home-healthcare-dr-config-recorder",
    [string]$ConformancePackName = "home-healthcare-dr-hipaa-security",
    [string]$EphiBucketName = "home-healthcare-dr-ephi-376873818584",
    [int]$MinEphiCompliantRules = 2,
    [switch]$SkipEphiComplianceCheck
)

$ErrorActionPreference = "Continue"
$pass = $true

Write-Host "=== Phase 6 Validation ===" -ForegroundColor Cyan
Write-Host "Region: $Region"
Write-Host "Note: First Config evaluations can take 10-20 minutes after terraform apply.`n"

Write-Host "[1] Configuration recorder exists and is recording"
$status = aws configservice describe-configuration-recorder-status `
    --region $Region `
    --configuration-recorder-names $RecorderName `
    --output json 2>&1 | ConvertFrom-Json

if ($LASTEXITCODE -ne 0 -or -not $status.ConfigurationRecordersStatus) {
    Write-Host "  FAIL: Cannot describe recorder '$RecorderName'" -ForegroundColor Red
    $pass = $false
} else {
    $rec = $status.ConfigurationRecordersStatus[0]
    if ($rec.recording -eq $true -and $rec.lastStatus -eq "SUCCESS") {
        Write-Host "  PASS: recording=$($rec.recording) lastStatus=$($rec.lastStatus)" -ForegroundColor Green
    } elseif ($rec.recording -eq $true) {
        Write-Host "  PASS (pending): recording=true lastStatus=$($rec.lastStatus) - re-run if still PENDING" -ForegroundColor Yellow
    } else {
        Write-Host "  FAIL: recording=$($rec.recording) lastStatus=$($rec.lastStatus)" -ForegroundColor Red
        $pass = $false
    }
}

Write-Host "`n[2] Delivery channel -> S3 bucket"
$channels = aws configservice describe-delivery-channels --region $Region --output json 2>&1 | ConvertFrom-Json
$channel = $channels.DeliveryChannels | Where-Object { $_.name -match "home-healthcare-dr-config-delivery" } | Select-Object -First 1
if (-not $channel) {
    $channel = $channels.DeliveryChannels | Select-Object -First 1
}
if ($channel -and $channel.s3BucketName -eq $ConfigBucketName) {
    Write-Host "  PASS: s3BucketName=$($channel.s3BucketName)" -ForegroundColor Green
} else {
    Write-Host "  FAIL: Expected delivery to $ConfigBucketName" -ForegroundColor Red
    $pass = $false
}

Write-Host "`n[3] HIPAA conformance pack deployed"
$packs = aws configservice describe-conformance-packs `
    --region $Region `
    --conformance-pack-names $ConformancePackName `
    --output json 2>&1 | ConvertFrom-Json

if ($LASTEXITCODE -ne 0 -or -not $packs.ConformancePackDetails) {
    Write-Host "  FAIL: Conformance pack '$ConformancePackName' not found" -ForegroundColor Red
    $pass = $false
} else {
    $detail = $packs.ConformancePackDetails[0]
    Write-Host "  PASS: $($detail.ConformancePackName)" -ForegroundColor Green
    Write-Host "  Template: $($detail.ConformancePackInputParameters.Count) parameter(s) configured"
}

Write-Host "`n[4] Conformance pack status"
$packStatus = aws configservice describe-conformance-pack-status `
    --region $Region `
    --conformance-pack-names $ConformancePackName `
    --output json 2>&1 | ConvertFrom-Json

if ($packStatus.ConformancePackStatusDetails) {
    $st = $packStatus.ConformancePackStatusDetails[0]
    Write-Host "  Status: $($st.ConformancePackState)"
    if ($st.ConformancePackState -in @("CREATE_COMPLETE", "UPDATE_COMPLETE")) {
        Write-Host "  PASS" -ForegroundColor Green
    } else {
        Write-Host "  FAIL: Wait for CREATE_COMPLETE (current: $($st.ConformancePackState))" -ForegroundColor Red
        $pass = $false
    }
} else {
    Write-Host "  FAIL: No pack status returned" -ForegroundColor Red
    $pass = $false
}

Write-Host "`n[5] Conformance pack compliance summary (informational)"
$summary = aws configservice get-conformance-pack-compliance-summary `
    --region $Region `
    --conformance-pack-name $ConformancePackName `
    --output json 2>&1 | ConvertFrom-Json
if ($LASTEXITCODE -eq 0 -and $summary.ConformancePackComplianceSummary) {
    $s = $summary.ConformancePackComplianceSummary
    Write-Host "  Compliant: $($s.CompliantRuleCount) | Non-compliant: $($s.NonCompliantRuleCount) | Insufficient data: $($s.InsufficientDataRuleCount)"
    Write-Host "  (Account-wide HIPAA pack will show non-compliant rules in a lab - expected.)"
} else {
    Write-Host "  WARN: Summary not ready yet - re-run after evaluations complete" -ForegroundColor Yellow
}

if (-not $SkipEphiComplianceCheck) {
    Write-Host "`n[6] ePHI bucket resource compliance (Phase 2 S3 hardening)"
    $details = aws configservice get-compliance-details-by-resource `
        --region $Region `
        --resource-type "AWS::S3::Bucket" `
        --resource-id $EphiBucketName `
        --output json 2>&1 | ConvertFrom-Json

    if ($LASTEXITCODE -ne 0 -or -not $details.EvaluationResults) {
        Write-Host "  FAIL: No Config evaluations for bucket $EphiBucketName yet" -ForegroundColor Red
        Write-Host "  Tip: Wait 10-20 min after apply, or run with -SkipEphiComplianceCheck for recorder-only check" -ForegroundColor Yellow
        $pass = $false
    } else {
        $compliant = @($details.EvaluationResults | Where-Object { $_.ComplianceType -eq "COMPLIANT" })
        $nonCompliant = @($details.EvaluationResults | Where-Object { $_.ComplianceType -eq "NON_COMPLIANT" })
        Write-Host "  COMPLIANT rules: $($compliant.Count) | NON_COMPLIANT: $($nonCompliant.Count)"
        foreach ($r in $compliant | Select-Object -First 8) {
            Write-Host "    + $($r.EvaluationResultIdentifier.EvaluationResultQualifier.ConfigRuleName)"
        }
        if ($compliant.Count -ge $MinEphiCompliantRules) {
            Write-Host ("  PASS: at least {0} compliant rule(s) on ePHI bucket" -f $MinEphiCompliantRules) -ForegroundColor Green
        } else {
            Write-Host ("  FAIL: need at least {0} compliant rules (got {1})" -f $MinEphiCompliantRules, $compliant.Count) -ForegroundColor Red
            $pass = $false
        }
    }
}

Write-Host ""
if ($pass) {
    Write-Host "CONFIG_PHASE6=PASS" -ForegroundColor Green
    exit 0
} else {
    Write-Host "CONFIG_PHASE6=FAIL" -ForegroundColor Red
    exit 1
}
