param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$RuntimeConfigPath,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$RuntimeSecretPath,

    [switch]$DryRun
)

$baseDir = $PSScriptRoot
$scriptPath = Join-Path (Split-Path -Parent $baseDir) "scripts\event_api_load.js"

function Assert-Contains {
    param(
        [string]$Text,
        [string]$Pattern,
        [string]$Message
    )
    if ($Text -notmatch $Pattern) {
        throw $Message
    }
}

function Invoke-Kubectl {
    param([string[]]$Arguments)
    & kubectl @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "kubectl failed with exit code ${LASTEXITCODE}: kubectl $($Arguments -join ' ')"
    }
}

if (-not (Test-Path -LiteralPath $RuntimeConfigPath -PathType Leaf)) {
    throw "Runtime config file not found: $RuntimeConfigPath"
}

if (-not (Test-Path -LiteralPath $RuntimeSecretPath -PathType Leaf)) {
    throw "Runtime secret file not found: $RuntimeSecretPath"
}

if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) {
    throw "k6 API script not found: $scriptPath"
}

if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    throw "kubectl executable not found in PATH"
}

$configText = Get-Content -LiteralPath $RuntimeConfigPath -Raw
$secretText = Get-Content -LiteralPath $RuntimeSecretPath -Raw

Assert-Contains $configText '(?m)^\s*kind:\s*ConfigMap\s*$' "Runtime config must be a ConfigMap"
Assert-Contains $configText '(?m)^\s*name:\s*k6-runtime-config\s*$' "Runtime config metadata.name must be k6-runtime-config"
Assert-Contains $configText '(?m)^\s*namespace:\s*k6-test\s*$' "Runtime config metadata.namespace must be k6-test"
foreach ($key in @("BASE_URL", "HEALTH_PATH", "LOGIN_PATH", "LIST_PATH", "DETAIL_PATH", "EVENT_PATH", "EVENT_PAYLOAD")) {
    Assert-Contains $configText "(?m)^\s*$key\s*:" "Runtime config missing data key: $key"
}

Assert-Contains $secretText '(?m)^\s*kind:\s*Secret\s*$' "Runtime secret must be a Secret"
Assert-Contains $secretText '(?m)^\s*name:\s*k6-runtime-secret\s*$' "Runtime secret metadata.name must be k6-runtime-secret"
Assert-Contains $secretText '(?m)^\s*namespace:\s*k6-test\s*$' "Runtime secret metadata.namespace must be k6-test"
foreach ($key in @("USERNAME", "PASSWORD")) {
    Assert-Contains $secretText "(?m)^\s*$key\s*:" "Runtime secret missing key: $key"
}

$generatedConfigMap = Join-Path $env:TEMP "k6-api-script-$PID.yaml"
try {
    & kubectl create configmap k6-api-script --namespace k6-test "--from-file=event_api_load.js=$scriptPath" --dry-run=client -o yaml |
        Set-Content -LiteralPath $generatedConfigMap -Encoding UTF8
    if ($LASTEXITCODE -ne 0) {
        throw "kubectl create configmap failed with exit code $LASTEXITCODE"
    }

    if ($DryRun) {
        Invoke-Kubectl -Arguments @("apply", "--dry-run=client", "-f", (Join-Path $baseDir "namespace.yaml"))
        Invoke-Kubectl -Arguments @("apply", "--dry-run=client", "-f", $RuntimeConfigPath)
        Invoke-Kubectl -Arguments @("apply", "--dry-run=client", "-f", $RuntimeSecretPath)
        Invoke-Kubectl -Arguments @("apply", "--dry-run=client", "-f", $generatedConfigMap)
        Write-Host "Dry-run completed. TestRun CRD server validation is intentionally skipped in local dry-run mode."
        return
    }

    Invoke-Kubectl -Arguments @("apply", "-f", (Join-Path $baseDir "namespace.yaml"))
    Invoke-Kubectl -Arguments @("apply", "-f", $RuntimeConfigPath)
    Invoke-Kubectl -Arguments @("apply", "-f", $RuntimeSecretPath)
    Invoke-Kubectl -Arguments @("apply", "-f", $generatedConfigMap)
    Invoke-Kubectl -Arguments @("apply", "-f", (Join-Path $baseDir "k6-api-testrun.yaml"))
} finally {
    if (Test-Path -LiteralPath $generatedConfigMap) {
        Remove-Item -LiteralPath $generatedConfigMap -Force
    }
}
