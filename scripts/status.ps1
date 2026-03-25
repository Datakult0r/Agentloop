[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$datasetFile = Join-Path $env:USERPROFILE ".cache\autoresearch\datasets\tinystories\data\tinystories_gpt4_clean.parquet"
$tokenizerFile = Join-Path $env:USERPROFILE ".cache\autoresearch\datasets\tinystories\tokenizer\tokenizer_config.json"

Write-Host ""
Write-Host "Agentloop status" -ForegroundColor Cyan
Write-Host "Repo root: $repoRoot"
Write-Host "Branch: $(git rev-parse --abbrev-ref HEAD)"
Write-Host "Commit: $(git rev-parse --short HEAD)"
Write-Host "GitHub remote: $(git remote get-url agentloop)"
Write-Host ""

if (Get-Command uv -ErrorAction SilentlyContinue) {
    Write-Host "uv: $(uv --version)"
} else {
    Write-Host "uv: not found"
}

Write-Host "Dataset ready: $([bool](Test-Path $datasetFile))"
Write-Host "Tokenizer ready: $([bool](Test-Path $tokenizerFile))"

if (Get-Command uv -ErrorAction SilentlyContinue) {
    try {
        $gpuName = uv run python -c "import torch; print(torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'CUDA unavailable')" 2>$null
        Write-Host "GPU path: $gpuName"
    } catch {
        Write-Host "GPU path: unavailable"
    }
}
