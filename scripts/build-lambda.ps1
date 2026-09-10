# Build Lambda deployment package (stdlib + boto3 runtime only).
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$lambdaDir = Join-Path $root "lambda"
$buildDir = Join-Path $lambdaDir "build"
$distZip = Join-Path $lambdaDir "dist\verify_restore.zip"

if (Test-Path $buildDir) {
    Remove-Item $buildDir -Recurse -Force
}
New-Item -ItemType Directory -Force -Path (Split-Path $distZip) | Out-Null
New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

Copy-Item (Join-Path $lambdaDir "verify_restore.py") $buildDir

if (Test-Path $distZip) {
    Remove-Item $distZip -Force
}

Write-Host "Creating $distZip"
Push-Location $buildDir
Compress-Archive -Path * -DestinationPath $distZip -Force
Pop-Location

Write-Host "Lambda package ready: $distZip"
