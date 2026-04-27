param(
    [ValidateNotNullOrEmpty()]
    [string]$ProjectName = "ngrinder"
)

$ErrorActionPreference = "Stop"

$composeFile = Join-Path $PSScriptRoot "docker-compose.yml"

& docker compose -p $ProjectName -f $composeFile down
if ($LASTEXITCODE -ne 0) {
    throw "docker compose down failed with exit code ${LASTEXITCODE}"
}
