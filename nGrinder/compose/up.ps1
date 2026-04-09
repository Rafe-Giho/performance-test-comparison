param(
    [int]$AgentScale = 10
)

$composeFile = Join-Path $PSScriptRoot "docker-compose.yml"

docker compose -f $composeFile up -d --scale agent=$AgentScale

Write-Host "nGrinder controller is expected at http://localhost:8080"
Write-Host "Requested agent scale: $AgentScale"
