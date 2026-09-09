# Upload Phase 1 synthetic data to the encrypted ePHI S3 bucket.
param(
    [Parameter(Mandatory = $true)]
    [string]$BucketName,

    [string]$KmsAlias = "alias/home-healthcare-dr-ephi",

    [string]$SourceDir = "$PSScriptRoot\..\phase1-synthetic-data\output"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path "$SourceDir\manifest.json")) {
    throw "manifest.json not found in $SourceDir. Run Phase 1 generator first."
}

Write-Host "Uploading patient records to s3://$BucketName/patients/ ..."
aws s3 sync "$SourceDir\patients" "s3://$BucketName/patients/" `
    --sse aws:kms `
    --sse-kms-key-id $KmsAlias `
    --only-show-errors

Write-Host "Uploading manifest.json ..."
aws s3 cp "$SourceDir\manifest.json" "s3://$BucketName/manifest.json" `
    --sse aws:kms `
    --sse-kms-key-id $KmsAlias `
    --only-show-errors

Write-Host "Upload complete."
