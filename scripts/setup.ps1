[CmdletBinding()]
param(
    [ValidateSet("tinystories")]
    [string]$Dataset = "tinystories",

    [ValidateSet("auto", "byte", "bpe")]
    [string]$TokenizerMode = "auto"
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Cyan
}

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

Write-Step "Checking that uv is installed"
Write-Host "Layman version: uv is the project manager that fetches the exact Python tools this repo expects."
if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
    throw "uv was not found on PATH. Install it from https://docs.astral.sh/uv/ and then re-run this script."
}

Write-Step "Installing Python dependencies"
Write-Host "Layman version: this is like stocking the workbench with the right tools before we start."
uv sync

Write-Step "Preparing the dataset and tokenizer"
Write-Host "Layman version: this downloads the practice text and builds the text-to-number dictionary the model uses."
uv run prepare.py --dataset $Dataset --tokenizer-mode $TokenizerMode

Write-Step "Setup complete"
Write-Host "Next recommended commands:"
Write-Host "  .\scripts\smoke-test.ps1"
Write-Host "  .\scripts\run-once.ps1"
