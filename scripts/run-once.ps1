[CmdletBinding()]
param(
    [ValidateSet("tinystories")]
    [string]$Dataset = "tinystories",

    [string]$LogPath = "run.log"
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Cyan
}

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

Write-Step "Running one full Agentloop experiment"
Write-Host "Layman version: this starts one real 5-minute training run and saves a transcript to a log file."
uv run train.py --dataset $Dataset *>&1 | Tee-Object -FilePath $LogPath

Write-Step "Run complete"
Write-Host "Log saved to $LogPath"
