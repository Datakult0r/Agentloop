[CmdletBinding()]
param(
    [ValidateSet("tinystories")]
    [string]$Dataset = "tinystories"
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Cyan
}

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

Write-Step "Running the smoke test"
Write-Host "Layman version: this is a short engine test to confirm the training loop, data, and GPU path are all wired up correctly."
uv run train.py --smoke-test --dataset $Dataset

Write-Step "Smoke test finished"
Write-Host "If that completed without errors, the core training path is healthy."
