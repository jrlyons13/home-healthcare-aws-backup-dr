# Phase 7: Custom Config rules - primary + DR copy RPO freshness.
param(
    [string]$Region = "us-east-1",
    [string]$PrimaryRuleName = "home-healthcare-dr-primary-rpo-freshness",
    [string]$CopyRuleName = "home-healthcare-dr-copy-rpo-freshness",
    [string]$EphiBucketName = "home-healthcare-dr-ephi-376873818584",
    [switch]$AllowInsufficientData
)

$ErrorActionPreference = "Continue"
$pass = $true

Write-Host "=== Phase 7 Validation ===" -ForegroundColor Cyan
Write-Host "Note: Rules run on a 6-hour schedule. After apply, trigger a manual evaluation in Config or wait for the first run.`n"

function Test-RuleCompliance {
    param(
        [string]$RuleName,
        [string]$Label
    )
    Write-Host "[$Label] Config rule: $RuleName"
    $rules = aws configservice describe-config-rules `
        --region $Region `
        --config-rule-names $RuleName `
        --output json 2>&1 | ConvertFrom-Json

    if ($LASTEXITCODE -ne 0 -or -not $rules.ConfigRules) {
        Write-Host "  FAIL: Rule not found" -ForegroundColor Red
        return $false
    }

    $details = aws configservice get-compliance-details-by-config-rule `
        --region $Region `
        --config-rule-name $RuleName `
        --output json 2>&1 | ConvertFrom-Json

    if ($LASTEXITCODE -ne 0 -or -not $details.EvaluationResults) {
        Write-Host "  FAIL: No evaluation results yet (trigger rule or wait for schedule)" -ForegroundColor Red
        return $false
    }

    $match = @($details.EvaluationResults | Where-Object {
            $_.EvaluationResultIdentifier.EvaluationResultQualifier.ResourceId -eq $EphiBucketName
        })

    if ($match.Count -eq 0) {
        $latest = $details.EvaluationResults[-1]
        Write-Host "  WARN: No evaluation for bucket $EphiBucketName; latest resource: $($latest.EvaluationResultIdentifier.EvaluationResultQualifier.ResourceId)"
        $match = @($details.EvaluationResults[-1])
    }

    $result = $match[-1]
    $ctype = $result.ComplianceType
    $note = $result.Annotation
    Write-Host "  Compliance: $ctype"
    if ($note) { Write-Host "  Annotation: $note" }

    if ($ctype -eq "COMPLIANT") {
        Write-Host "  PASS" -ForegroundColor Green
        return $true
    }
    if ($ctype -eq "INSUFFICIENT_DATA" -and $AllowInsufficientData) {
        Write-Host "  PASS (grace): INSUFFICIENT_DATA allowed" -ForegroundColor Yellow
        return $true
    }
    Write-Host "  FAIL: Expected COMPLIANT" -ForegroundColor Red
    return $false
}

if (-not (Test-RuleCompliance -RuleName $PrimaryRuleName -Label "1")) { $pass = $false }
Write-Host ""
if (-not (Test-RuleCompliance -RuleName $CopyRuleName -Label "2")) { $pass = $false }

Write-Host ""
if ($pass) {
    Write-Host "PHASE7_RPO_MONITOR=PASS" -ForegroundColor Green
    exit 0
} else {
    Write-Host "PHASE7_RPO_MONITOR=FAIL" -ForegroundColor Red
    Write-Host "Tip: AWS Config -> Rules -> select rule -> Remediate/Evaluate or wait up to 6 hours." -ForegroundColor Yellow
    exit 1
}
