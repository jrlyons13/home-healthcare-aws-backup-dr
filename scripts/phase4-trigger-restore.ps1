# Restore latest recovery point into the destination bucket (original object keys).
# Note: AWS Backup S3 restore does not support a custom prefix; objects restore to
# their original keys (e.g. patients/). S3 versioning on the bucket retains prior versions.
param(
    [Parameter(Mandatory = $true)]
    [string]$RecoveryPointArn,

    [Parameter(Mandatory = $true)]
    [string]$DestinationBucketName,

    [Parameter(Mandatory = $true)]
    [string]$BackupRoleArn,

    [string]$Region = "us-east-1",
    [int]$MaxWaitMinutes = 45
)

$ErrorActionPreference = "Stop"

Write-Host "Starting restore to s3://$DestinationBucketName/ (original object keys) ..."

$token = [guid]::NewGuid().ToString()
$restoreJson = aws backup start-restore-job `
    --region $Region `
    --recovery-point-arn $RecoveryPointArn `
    --metadata "DestinationBucketName=$DestinationBucketName,NewBucket=false,Encrypted=true,EncryptionType=original,RestoreACLs=false,CreationToken=$token" `
    --iam-role-arn $BackupRoleArn `
    --resource-type S3 `
    --output json | ConvertFrom-Json

$restoreJobId = $restoreJson.RestoreJobId
Write-Host "RestoreJobId: $restoreJobId"

$deadline = (Get-Date).AddMinutes($MaxWaitMinutes)
do {
    Start-Sleep -Seconds 15
    $job = aws backup describe-restore-job --region $Region --restore-job-id $restoreJobId --output json | ConvertFrom-Json
    Write-Host "  Restore state: $($job.Status)"
} while ($job.Status -in @("PENDING", "RUNNING") -and (Get-Date) -lt $deadline)

if ($job.Status -ne "COMPLETED") {
    throw "Restore job did not complete. Status=$($job.Status) Message=$($job.StatusMessage)"
}

Write-Host "Restore completed. Objects restored under original keys (patients/, manifest.json)."
