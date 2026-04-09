param(
    [string]$EnvFile = ".env"
)

$composeFile = Join-Path $PSScriptRoot "docker-compose.yml"

if (Test-Path (Join-Path $PSScriptRoot $EnvFile)) {
    docker compose --env-file (Join-Path $PSScriptRoot $EnvFile) -f $composeFile up --build --abort-on-container-exit
} else {
    docker compose -f $composeFile up --build --abort-on-container-exit
}
