# Build Lambda deployment packages (stdlib + boto3 runtime only).
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$lambdaDir = Join-Path $root "lambda"
$distDir = Join-Path $lambdaDir "dist"
New-Item -ItemType Directory -Force -Path $distDir | Out-Null

function Build-LambdaZip {
    param(
        [string]$SourceFile,
        [string]$ZipName
    )
    $buildDir = Join-Path $lambdaDir "build_$ZipName"
    $distZip = Join-Path $distDir $ZipName

    if (Test-Path $buildDir) {
        Remove-Item $buildDir -Recurse -Force
    }
    New-Item -ItemType Directory -Force -Path $buildDir | Out-Null
    Copy-Item (Join-Path $lambdaDir $SourceFile) $buildDir

    if (Test-Path $distZip) {
        Remove-Item $distZip -Force
    }

    Write-Host "Creating $distZip"
    Push-Location $buildDir
    Compress-Archive -Path * -DestinationPath $distZip -Force
    Pop-Location
    Remove-Item $buildDir -Recurse -Force
}

Build-LambdaZip -SourceFile "verify_restore.py" -ZipName "verify_restore.zip"
Build-LambdaZip -SourceFile "rpo_freshness_config.py" -ZipName "rpo_freshness_config.zip"

Write-Host "Lambda packages ready in $distDir"
