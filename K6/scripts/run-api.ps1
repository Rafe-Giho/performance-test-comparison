param(
    [string]$ScriptPath = ".\event_api_load.js",

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ProjectName,

    [string]$OutputDir,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$BaseUrl,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$HealthPath,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$LoginPath,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ListPath,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$DetailPath,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$EventPath,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$EventPayload,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Username,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Password
)

if (-not [System.IO.Path]::IsPathRooted($ScriptPath)) {
    $ScriptPath = Join-Path $PSScriptRoot $ScriptPath
}

if (-not (Test-Path -LiteralPath $ScriptPath -PathType Leaf)) {
    throw "k6 script not found: $ScriptPath"
}

if (-not (Get-Command k6 -ErrorAction SilentlyContinue)) {
    throw "k6 executable not found in PATH"
}

if (-not $OutputDir) {
    $OutputDir = Join-Path (Join-Path (Split-Path -Parent $PSScriptRoot) "reports\$ProjectName") (Get-Date -Format "yyyyMMdd")
} elseif (-not [System.IO.Path]::IsPathRooted($OutputDir)) {
    $OutputDir = Join-Path $PSScriptRoot $OutputDir
}

$resolvedOutput = Resolve-Path -LiteralPath $OutputDir -ErrorAction SilentlyContinue
if (-not $resolvedOutput) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    $resolvedOutput = Resolve-Path $OutputDir
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$summaryFile = Join-Path $resolvedOutput "summary-api-$timestamp.json"

foreach ($pathValue in @($HealthPath, $LoginPath, $ListPath, $DetailPath, $EventPath)) {
    if (-not $pathValue.StartsWith("/")) {
        throw "API path must start with '/': $pathValue"
    }
}

try {
    $null = $EventPayload | ConvertFrom-Json -ErrorAction Stop
} catch {
    throw "EventPayload must be valid JSON: $($_.Exception.Message)"
}

$env:BASE_URL = $BaseUrl
$env:HEALTH_PATH = $HealthPath
$env:LOGIN_PATH = $LoginPath
$env:LIST_PATH = $ListPath
$env:DETAIL_PATH = $DetailPath
$env:USERNAME = $Username
$env:PASSWORD = $Password
$env:EVENT_PATH = $EventPath
$env:EVENT_PAYLOAD = $EventPayload

k6 run --summary-export $summaryFile $ScriptPath
if ($LASTEXITCODE -ne 0) {
    throw "k6 API test failed with exit code $LASTEXITCODE"
}

Write-Host "Summary : $summaryFile"
