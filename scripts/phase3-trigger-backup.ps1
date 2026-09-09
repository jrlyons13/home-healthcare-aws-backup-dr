# Trigger on-demand S3 backup and cross-region copy job.
param(
    [Parameter(Mandatory = $true)]
    [string]$PrimaryVaultName,

    [Parameter(Mandatory = $true)]
    [string]$CopyVaultArn,

    [Parameter(Mandatory = $true)]
    [string]$BucketArn,

    [Parameter(Mandatory = $true)]
    [string]$BackupRoleArn,

    [string]$PrimaryRegion = "us-east-1",
    [string]$DrRegion = "us-west-2",
    [int]$MaxWaitMinutes = 30
)

$ErrorActionPreference = "Stop"

Write-Host "Starting on-demand backup job ..."
$jobJson = aws backup start-backup-job `
    --region $PrimaryRegion `
    --backup-vault-name $PrimaryVaultName `
    --resource-arn $BucketArn `
    --iam-role-arn $BackupRoleArn `
    --output json | ConvertFrom-Json

$jobId = $jobJson.BackupJobId
Write-Host "BackupJobId: $jobId"

$deadline = (Get-Date).AddMinutes($MaxWaitMinutes)
do {
    Start-Sleep -Seconds 15
    $job = aws backup describe-backup-job --region $PrimaryRegion --backup-job-id $jobId --output json | ConvertFrom-Json
    Write-Host "  Backup state: $($job.State)"
} while ($job.State -in @("CREATED", "PENDING", "RUNNING") -and (Get-Date) -lt $deadline)

if ($job.State -ne "COMPLETED") {
    throw "Backup job did not complete. State=$($job.State) StatusMessage=$($job.StatusMessage)"
}

$recoveryPointArn = $job.RecoveryPointArn
Write-Host "RecoveryPointArn: $recoveryPointArn"

Write-Host "Starting cross-region copy job ..."
# Retention must fall within copy vault Vault Lock min/max (default 7-365 days).
$idempotencyToken = [guid]::NewGuid().ToString()
$copyJson = aws backup start-copy-job `
    --region $PrimaryRegion `
    --recovery-point-arn $recoveryPointArn `
    --source-backup-vault-name $PrimaryVaultName `
    --destination-backup-vault-arn $CopyVaultArn `
    --iam-role-arn $BackupRoleArn `
    --lifecycle DeleteAfterDays=90 `
    --idempotency-token $idempotencyToken `
    --output json | ConvertFrom-Json

$copyJobId = $copyJson.CopyJobId
Write-Host "CopyJobId: $copyJobId"

$deadline = (Get-Date).AddMinutes($MaxWaitMinutes)
do {
    Start-Sleep -Seconds 15
    $copy = aws backup describe-copy-job --region $PrimaryRegion --copy-job-id $copyJobId --output json | ConvertFrom-Json
    Write-Host "  Copy state: $($copy.State)"
} while ($copy.State -in @("CREATED", "PENDING", "RUNNING") -and (Get-Date) -lt $deadline)

if ($copy.State -ne "COMPLETED") {
    throw "Copy job did not complete. State=$($copy.State) StatusMessage=$($copy.StatusMessage)"
}

Write-Host "Backup and copy completed successfully."
Write-Host "RecoveryPointArn=$recoveryPointArn"
