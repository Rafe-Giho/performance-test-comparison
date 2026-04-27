param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$RuntimeConfigPath,

    [switch]$DryRun
)

$baseDir = $PSScriptRoot
$scriptPath = Join-Path (Split-Path -Parent $baseDir) "scripts\browser_smoke.js"

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

if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) {
    throw "k6 browser script not found: $scriptPath"
}

if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    throw "kubectl executable not found in PATH"
}

$configText = Get-Content -LiteralPath $RuntimeConfigPath -Raw
Assert-Contains $configText '(?m)^\s*kind:\s*ConfigMap\s*$' "Runtime config must be a ConfigMap"
Assert-Contains $configText '(?m)^\s*name:\s*k6-runtime-config\s*$' "Runtime config metadata.name must be k6-runtime-config"
Assert-Contains $configText '(?m)^\s*namespace:\s*k6-test\s*$' "Runtime config metadata.namespace must be k6-test"
Assert-Contains $configText '(?m)^\s*BASE_URL\s*:' "Runtime config missing data key: BASE_URL"

$generatedConfigMap = Join-Path $env:TEMP "k6-browser-script-$PID.yaml"
try {
    & kubectl create configmap k6-browser-script --namespace k6-test "--from-file=browser_smoke.js=$scriptPath" --dry-run=client -o yaml |
        Set-Content -LiteralPath $generatedConfigMap -Encoding UTF8
    if ($LASTEXITCODE -ne 0) {
        throw "kubectl create configmap failed with exit code $LASTEXITCODE"
    }

    if ($DryRun) {
        Invoke-Kubectl -Arguments @("apply", "--dry-run=client", "-f", (Join-Path $baseDir "namespace.yaml"))
        Invoke-Kubectl -Arguments @("apply", "--dry-run=client", "-f", $RuntimeConfigPath)
        Invoke-Kubectl -Arguments @("apply", "--dry-run=client", "-f", $generatedConfigMap)
        Invoke-Kubectl -Arguments @("apply", "--dry-run=client", "-f", (Join-Path $baseDir "k6-browser-pod.yaml"))
        return
    }

    Invoke-Kubectl -Arguments @("apply", "-f", (Join-Path $baseDir "namespace.yaml"))
    Invoke-Kubectl -Arguments @("apply", "-f", $RuntimeConfigPath)
    Invoke-Kubectl -Arguments @("apply", "-f", $generatedConfigMap)
    Invoke-Kubectl -Arguments @("apply", "-f", (Join-Path $baseDir "k6-browser-pod.yaml"))
} finally {
    if (Test-Path -LiteralPath $generatedConfigMap) {
        Remove-Item -LiteralPath $generatedConfigMap -Force
    }
}
