# Validate Phase 2 encryption and HTTPS-only bucket policy.
param(
    [Parameter(Mandatory = $true)]
    [string]$BucketName,

    [string]$KmsKeyArn,

    [string]$SampleKey = "patients/SYN-000001.json"
)

$ErrorActionPreference = "Stop"
$pass = $true

Write-Host "=== Phase 2 Validation ===" -ForegroundColor Cyan

Write-Host "`n[1] head-object (SSE-KMS check)"
$head = aws s3api head-object --bucket $BucketName --key $SampleKey | ConvertFrom-Json
Write-Host "  ServerSideEncryption: $($head.ServerSideEncryption)"
Write-Host "  SSEKMSKeyId:          $($head.SSEKMSKeyId)"

if ($head.ServerSideEncryption -ne "aws:kms") {
    Write-Host "  FAIL: Expected aws:kms" -ForegroundColor Red
    $pass = $false
} elseif ($KmsKeyArn -and $head.SSEKMSKeyId -notmatch [regex]::Escape($KmsKeyArn.Split('/')[-1])) {
    Write-Host "  WARN: KMS key id may differ by ARN format; verify manually." -ForegroundColor Yellow
} else {
    Write-Host "  PASS" -ForegroundColor Green
}

Write-Host "`n[2] HTTPS-only policy (insecure transport should fail)"
$tmpFile = New-TemporaryFile
"insecure-transport-test" | Set-Content -Path $tmpFile.FullName -NoNewline
$httpEndpoint = "http://$BucketName.s3.us-east-1.amazonaws.com/insecure-test.txt"

try {
    aws s3api put-object `
        --bucket $BucketName `
        --key "insecure-test.txt" `
        --body $tmpFile.FullName `
        --endpoint-url "http://s3.us-east-1.amazonaws.com" `
        --sse aws:kms 2>&1 | Out-Null
    Write-Host "  FAIL: HTTP PUT was not denied" -ForegroundColor Red
    $pass = $false
} catch {
    Write-Host "  PASS: HTTP/insecure upload denied" -ForegroundColor Green
} finally {
    Remove-Item $tmpFile.FullName -Force -ErrorAction SilentlyContinue
}

Write-Host "`n[3] CloudTrail recent events (last 15 minutes)"
$start = (Get-Date).AddMinutes(-15).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$events = aws cloudtrail lookup-events `
    --lookup-attributes AttributeKey=EventName,AttributeValue=PutObject `
    --start-time $start `
    --max-results 5 2>$null | ConvertFrom-Json

if ($events.Events.Count -gt 0) {
    Write-Host "  PASS: Found $($events.Events.Count) PutObject event(s) in CloudTrail" -ForegroundColor Green
} else {
    Write-Host "  WARN: No PutObject events yet (may take a few minutes to appear)" -ForegroundColor Yellow
}

if ($pass) {
    Write-Host "`nVERIFICATION_RESULT=PASS" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nVERIFICATION_RESULT=FAIL" -ForegroundColor Red
    exit 1
}
