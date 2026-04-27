param(
    [string]$ScriptPath = ".\browser_smoke.js",

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ProjectName,

    [string]$OutputDir,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$BaseUrl
)

if (-not [System.IO.Path]::IsPathRooted($ScriptPath)) {
    $ScriptPath = Join-Path $PSScriptRoot $ScriptPath
}

if (-not (Test-Path -LiteralPath $ScriptPath -PathType Leaf)) {
    throw "k6 browser script not found: $ScriptPath"
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
$summaryFile = Join-Path $resolvedOutput "summary-browser-$timestamp.json"

$env:BASE_URL = $BaseUrl
$env:K6_BROWSER_HEADLESS = "true"

k6 run --summary-export $summaryFile $ScriptPath
if ($LASTEXITCODE -ne 0) {
    throw "k6 browser test failed with exit code $LASTEXITCODE"
}

Write-Host "Summary : $summaryFile"
