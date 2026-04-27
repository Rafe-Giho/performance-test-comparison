param(
    [ValidateRange(1, 50)]
    [int]$AgentScale = 1,

    [ValidateNotNullOrEmpty()]
    [string]$ProjectName = "ngrinder",

    [switch]$Pull
)

$ErrorActionPreference = "Stop"

$composeFile = Join-Path $PSScriptRoot "docker-compose.yml"
$controllerVolume = Join-Path $PSScriptRoot "volumes\controller"

function Invoke-NGrinderCompose {
    param([string[]]$Arguments)

    & docker compose -p $ProjectName -f $composeFile @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "docker compose failed with exit code ${LASTEXITCODE}: docker compose -p $ProjectName -f $composeFile $($Arguments -join ' ')"
    }
}

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw "docker executable not found in PATH"
}

New-Item -ItemType Directory -Force -Path $controllerVolume | Out-Null

Invoke-NGrinderCompose -Arguments @("config")

if ($Pull) {
    Invoke-NGrinderCompose -Arguments @("pull")
}

Invoke-NGrinderCompose -Arguments @("up", "-d", "--scale", "agent=$AgentScale", "--remove-orphans")
Invoke-NGrinderCompose -Arguments @("ps")

Write-Host "nGrinder compose project: $ProjectName"
Write-Host "nGrinder controller is expected at http://<controller-vm-private-ip>:8080 or http://localhost:8080 from the host"
Write-Host "Requested agent scale: $AgentScale"
