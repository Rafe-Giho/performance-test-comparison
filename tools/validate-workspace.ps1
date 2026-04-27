param(
    [switch]$Strict
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$errors = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()

function Add-Error {
    param([string]$Message)
    $script:errors.Add($Message) | Out-Null
}

function Add-Warning {
    param([string]$Message)
    $script:warnings.Add($Message) | Out-Null
}

function Join-Root {
    param([string]$RelativePath)
    return Join-Path $root ($RelativePath -replace '/', [IO.Path]::DirectorySeparatorChar)
}

function Test-RequiredFile {
    param([string]$RelativePath)
    $path = Join-Root $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Add-Error "Missing required file: $RelativePath"
    }
}

function Test-RequiredDir {
    param([string]$RelativePath)
    $path = Join-Root $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Container)) {
        Add-Error "Missing required directory: $RelativePath"
    }
}

function Get-RelativePath {
    param([string]$Path)
    $rootFull = (Resolve-Path -LiteralPath $root).Path.TrimEnd('\') + '\'
    $pathFull = (Resolve-Path -LiteralPath $Path).Path
    $rootUri = [Uri]$rootFull
    $pathUri = [Uri]$pathFull
    return [Uri]::UnescapeDataString($rootUri.MakeRelativeUri($pathUri).ToString())
}

function Read-TextFile {
    param([string]$Path)
    return Get-Content -LiteralPath $Path -Raw -Encoding UTF8
}

$requiredFiles = @(
    "README.md",
    "DOCUMENT-STANDARD.md",
    "STANDARD-LOADTEST-GUIDE.md",
    "TEMPLATE-CATALOG.md",
    "PREP-CHECKLIST.md",
    "COMPARISON-REPORT-GUIDE.md",
    "FINAL-DELIVERABLES.md",
    "OPERATIONS-HARNESS.md",
    "docs/notion-loadtest-comparison.md",
    "docs/notion-loadtest-comparison.csv",
    "docs/dooray.md",
    "Jmeter/README.md",
    "Jmeter/SETUP-GUIDE.md",
    "Jmeter/TEST-GUIDE.md",
    "Jmeter/plans/web-standard-template.jmx",
    "Jmeter/scripts/run-local.ps1",
    "Jmeter/scripts/run-distributed.ps1",
    "Jmeter/scripts/generate-report.ps1",
    "K6/README.md",
    "K6/SETUP-GUIDE.md",
    "K6/TEST-GUIDE.md",
    "K6/scripts/event_api_load.js",
    "K6/scripts/browser_smoke.js",
    "K6/infra/RUNTIME-CONTRACT.md",
    "K6/infra/k6-api-testrun.yaml",
    "K6/infra/k6-browser-pod.yaml",
    "nGrinder/README.md",
    "nGrinder/SETUP-GUIDE.md",
    "nGrinder/TEST-GUIDE.md",
    "nGrinder/scripts/web_standard_template.groovy"
)

$requiredDirs = @(
    "Jmeter/reports",
    "K6/reports",
    "K6/scenarios",
    "nGrinder/reports"
)

foreach ($file in $requiredFiles) {
    Test-RequiredFile $file
}

foreach ($dir in $requiredDirs) {
    Test-RequiredDir $dir
}

$markdownFiles = Get-ChildItem -LiteralPath $root -Recurse -Filter "*.md" -File |
    Where-Object { $_.FullName -notmatch "\\.git\\" }

foreach ($file in $markdownFiles) {
    $content = Read-TextFile $file.FullName
    $matches = [regex]::Matches($content, '\[[^\]]+\]\(([^)]+)\)')
    foreach ($match in $matches) {
        $target = $match.Groups[1].Value.Trim()
        if ([string]::IsNullOrWhiteSpace($target)) {
            continue
        }
        if ($target -match '^(https?|mailto):' -or $target.StartsWith("#")) {
            continue
        }

        $targetNoAnchor = ($target -split '#')[0]
        if ([string]::IsNullOrWhiteSpace($targetNoAnchor)) {
            continue
        }

        if ($targetNoAnchor -match '^[A-Za-z]:\\') {
            if (-not (Test-Path -LiteralPath $targetNoAnchor)) {
                Add-Error "Broken absolute markdown link in $(Get-RelativePath $file.FullName): $target"
            } else {
                Add-Warning "Absolute markdown link reduces portability in $(Get-RelativePath $file.FullName): $target"
            }
            continue
        }

        $baseDir = Split-Path -Parent $file.FullName
        $normalized = $targetNoAnchor -replace '/', [IO.Path]::DirectorySeparatorChar
        $resolved = Join-Path $baseDir $normalized
        if (-not (Test-Path -LiteralPath $resolved)) {
            Add-Error "Broken markdown link in $(Get-RelativePath $file.FullName): $target"
        }
    }
}

function ConvertFrom-Utf8Base64 {
    param([string]$Value)
    return [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($Value))
}

$documentGradeMarker = ConvertFrom-Utf8Base64 "66y47IScIOuTseq4iTog7YyAIOuwsO2PrOyaqSDtkZzspIAg7Jq07JiBIOqwgOydtOuTnA=="
$cloudEnvironmentMarker = ConvertFrom-Utf8Base64 "7Jq07JiBIO2ZmOqyvTog7YG065287Jqw65OcIOq4sOuwmCDthYzsiqTtirgg7ZmY6rK9"
$forbiddenDraftPatterns = @(
    "TODO",
    "TBD",
    (ConvertFrom-Utf8Base64 "7LSI7JWI"),
    "placeholder"
)

foreach ($file in $markdownFiles) {
    $relativePath = Get-RelativePath $file.FullName
    $content = Read-TextFile $file.FullName

    if ($content -notmatch [regex]::Escape($documentGradeMarker)) {
        Add-Error "Markdown document is not marked as team operations standard: $relativePath"
    }

    if ($content -notmatch [regex]::Escape($cloudEnvironmentMarker)) {
        Add-Error "Markdown document is not marked as cloud-based test environment standard: $relativePath"
    }

    foreach ($pattern in $forbiddenDraftPatterns) {
        if ($content -match $pattern) {
            Add-Error "Markdown document contains draft marker '$pattern': $relativePath"
        }
    }
}

function Test-RequiredHeadings {
    param(
        [string]$RelativePath,
        [string[]]$Headings,
        [string]$Profile
    )

    $path = Join-Root $RelativePath
    if (-not (Test-Path -LiteralPath $path)) {
        return
    }

    $content = Read-TextFile $path
    foreach ($heading in $Headings) {
        $pattern = "(?m)^$([regex]::Escape($heading))\s*$"
        if ($content -notmatch $pattern) {
            Add-Error "$Profile document missing required heading '$heading': $RelativePath"
        }
    }
}

$setupGuideHeadings = @(
    (ConvertFrom-Utf8Base64 "IyMg66y47IScIOuTseq4iQ=="),
    (ConvertFrom-Utf8Base64 "IyMg7Jq07JiBIO2ZmOqyvQ=="),
    (ConvertFrom-Utf8Base64 "IyMg7KCB7JqpIOuMgOyDgQ=="),
    (ConvertFrom-Utf8Base64 "IyMg6rO17IudIOq4sOykgA=="),
    (ConvertFrom-Utf8Base64 "IyMg7IKs7KCEIOyhsOqxtA=="),
    (ConvertFrom-Utf8Base64 "IyMg7ISk7LmYIFJ1bmJvb2s="),
    (ConvertFrom-Utf8Base64 "IyMg6rKA7KadIFJ1bmJvb2s="),
    (ConvertFrom-Utf8Base64 "IyMg67O07JWIL+uEpO2KuOybjO2BrCDquLDspIA="),
    (ConvertFrom-Utf8Base64 "IyMg7J6l7JWgIOyhsOy5mA=="),
    (ConvertFrom-Utf8Base64 "IyMg7Jq07JiBIOyytO2BrOumrOyKpO2KuA=="),
    (ConvertFrom-Utf8Base64 "IyMg6rWs7LaVIOyZhOujjCDquLDspIA=")
)

foreach ($doc in @("Jmeter/SETUP-GUIDE.md", "K6/SETUP-GUIDE.md", "nGrinder/SETUP-GUIDE.md")) {
    Test-RequiredHeadings -RelativePath $doc -Headings $setupGuideHeadings -Profile "Setup guide"
}

$testGuideHeadings = @(
    (ConvertFrom-Utf8Base64 "IyMg66y47IScIOuTseq4iQ=="),
    (ConvertFrom-Utf8Base64 "IyMg7Jq07JiBIO2ZmOqyvQ=="),
    (ConvertFrom-Utf8Base64 "IyMg6riw67O4IOybkOy5mQ=="),
    (ConvertFrom-Utf8Base64 "IyMg7Iuk7ZaJIOyghOygnA=="),
    (ConvertFrom-Utf8Base64 "IyMg7ZGc7KSAIOyLnOuCmOumrOyYpCDtnZDrpoQ="),
    (ConvertFrom-Utf8Base64 "IyMg7Iuk7ZaJIFJ1bmJvb2s="),
    (ConvertFrom-Utf8Base64 "IyMg7ISx6rO1L+yLpO2MqCDtjJDsoJU="),
    (ConvertFrom-Utf8Base64 "IyMg6rKw6rO8IOyCsOy2nOusvA=="),
    (ConvertFrom-Utf8Base64 "IyMg7J6l7JWgIOyhsOy5mA=="),
    (ConvertFrom-Utf8Base64 "IyMg7KCV66asL+2bhOyGjSDsobDsuZg=")
)

foreach ($doc in @("Jmeter/TEST-GUIDE.md", "K6/TEST-GUIDE.md", "nGrinder/TEST-GUIDE.md")) {
    Test-RequiredHeadings -RelativePath $doc -Headings $testGuideHeadings -Profile "Test guide"
}

$workspaceReadmeHeadings = @(
    (ConvertFrom-Utf8Base64 "IyMg66y47IScIOuTseq4iQ=="),
    (ConvertFrom-Utf8Base64 "IyMg7Jq07JiBIO2ZmOqyvQ=="),
    (ConvertFrom-Utf8Base64 "IyMg7Jet7ZWg"),
    (ConvertFrom-Utf8Base64 "IyMg7Y+0642UIOyaqeuPhA=="),
    (ConvertFrom-Utf8Base64 "IyMg7ZGc7KSAIO2FnO2UjOumvw=="),
    (ConvertFrom-Utf8Base64 "IyMg66i87KCAIOydveydhCDrrLjshJw="),
    (ConvertFrom-Utf8Base64 "IyMg7Jq07JiBIO2PrOyngOyFmA=="),
    (ConvertFrom-Utf8Base64 "IyMg67Cw7Y+sIOyghCDtmZXsnbg=")
)

foreach ($doc in @("Jmeter/README.md", "K6/README.md", "nGrinder/README.md")) {
    Test-RequiredHeadings -RelativePath $doc -Headings $workspaceReadmeHeadings -Profile "Tool README"
}

Test-RequiredHeadings -RelativePath "DOCUMENT-STANDARD.md" -Headings @(
    (ConvertFrom-Utf8Base64 "IyMg66y47IScIOuTseq4iQ=="),
    (ConvertFrom-Utf8Base64 "IyMg7Jq07JiBIO2ZmOqyvQ=="),
    (ConvertFrom-Utf8Base64 "IyMg7KCB7JqpIOuylOychA=="),
    (ConvertFrom-Utf8Base64 "IyMg7ZWE7IiYIOusuOyEnCDquLDspIA="),
    (ConvertFrom-Utf8Base64 "IyMg7ZWY64Sk7IqkIOqwleygnCDquLDspIA="),
    (ConvertFrom-Utf8Base64 "IyMg67Cw7Y+sIO2MkOyglQ==")
) -Profile "Document standard"

$catalogPath = Join-Root "TEMPLATE-CATALOG.md"
if (Test-Path -LiteralPath $catalogPath) {
    $catalog = Get-Content -LiteralPath $catalogPath -Raw
    $catalogItems = [regex]::Matches($catalog, '`([^`]+)`') |
        ForEach-Object { $_.Groups[1].Value } |
        Where-Object {
            ($_ -match '[\\/]') -and
            ($_ -notmatch '<') -and
            ($_ -match '(\.md|\.ps1|\.js|\.groovy|\.jmx|\.ya?ml|\.csv|\.example)$')
        } |
        Sort-Object -Unique

    foreach ($item in $catalogItems) {
        if (-not (Test-Path -LiteralPath (Join-Root $item))) {
            Add-Error "TEMPLATE-CATALOG.md references missing path: $item"
        }
    }
}

$policyDocs = @(
    "README.md",
    "STANDARD-LOADTEST-GUIDE.md",
    "COMPARISON-REPORT-GUIDE.md",
    "docs/notion-loadtest-comparison.md",
    "docs/dooray.md"
)

foreach ($doc in $policyDocs) {
    $path = Join-Root $doc
    if (-not (Test-Path -LiteralPath $path)) {
        continue
    }
    $text = Get-Content -LiteralPath $path -Raw
    foreach ($needle in @("JMeter", "k6", "nGrinder")) {
        if ($text -notmatch [regex]::Escape($needle)) {
            Add-Error "Policy doc missing tool name '$needle': $doc"
        }
    }
}

$flowChecks = @(
    @{ Path = "Jmeter/plans/web-standard-template.jmx"; Needles = @("EVENT_PATH", "05-Event") },
    @{ Path = "K6/scripts/event_api_load.js"; Needles = @("EVENT_PATH", "05-event") },
    @{ Path = "nGrinder/scripts/web_standard_template.groovy"; Needles = @("EVENT_PATH", "EVENT_PAYLOAD") }
)

foreach ($check in $flowChecks) {
    $path = Join-Root $check.Path
    if (-not (Test-Path -LiteralPath $path)) {
        continue
    }
    $text = Get-Content -LiteralPath $path -Raw
    foreach ($needle in $check.Needles) {
        if ($text -notmatch [regex]::Escape($needle)) {
            Add-Error "Standard flow token '$needle' missing from $($check.Path)"
        }
    }
}

$jmeterCloudChecks = @(
    @{ Path = "Jmeter/README.md"; Needles = @("VPC", "security group", "private IP") },
    @{ Path = "Jmeter/SETUP-GUIDE.md"; Needles = @("VPC", "security group", "private subnet", "ClientRmiLocalPort", "object storage", "RMI") },
    @{ Path = "Jmeter/TEST-GUIDE.md"; Needles = @("security group", "RemoteHosts", "ClientRmiLocalPort", "object storage", "RMI") },
    @{ Path = "Jmeter/scripts/run-local.ps1"; Needles = @("bin\jmeter.bat", "bin\jmeter", "Resolve-JMeterExecutable") },
    @{ Path = "Jmeter/scripts/run-distributed.ps1"; Needles = @("ClientRmiLocalPort", "client.rmi.localport", "Resolve-JMeterExecutable") }
)

foreach ($check in $jmeterCloudChecks) {
    $path = Join-Root $check.Path
    if (-not (Test-Path -LiteralPath $path)) {
        continue
    }
    $text = Read-TextFile $path
    foreach ($needle in $check.Needles) {
        if ($text -notmatch [regex]::Escape($needle)) {
            Add-Error "JMeter cloud operating standard token '$needle' missing from $($check.Path)"
        }
    }
}

$stateDocs = @(
    "COMPARISON-REPORT-GUIDE.md",
    "docs/notion-loadtest-comparison.md",
    "docs/notion-loadtest-comparison.csv"
)

foreach ($doc in $stateDocs) {
    $path = Join-Root $doc
    if (-not (Test-Path -LiteralPath $path)) {
        continue
    }
    $text = Get-Content -LiteralPath $path -Raw
    foreach ($needle in @("5.6.3", "v1.7.1", "3.5.9-p1", "2025-09-24")) {
        if ($text -notmatch [regex]::Escape($needle)) {
            Add-Warning "Current-state marker '$needle' not found in $doc"
        }
    }
}

$operationalFiles = Get-ChildItem -LiteralPath $root -Recurse -File |
    Where-Object {
        $_.FullName -notmatch "\\.git\\" -and
        ($_.FullName -match "\\(infra|compose)\\" -or $_.Name -in @("Dockerfile", ".env.example", "docker-compose.yml"))
    }

foreach ($file in $operationalFiles) {
    $text = Get-Content -LiteralPath $file.FullName -Raw
    if ($text -match 'image:\s*\S*latest|:latest(\b|-)|latest-with-browser') {
        Add-Error "Operational file uses a latest-style image tag: $(Get-RelativePath $file.FullName)"
    }
}

$runtimeFiles = Get-ChildItem -LiteralPath $root -Recurse -File |
    Where-Object {
        $_.FullName -notmatch "\\.git\\" -and
        $_.Extension -in @(".ps1", ".js", ".groovy", ".jmx", ".yaml", ".yml", ".csv", ".example")
    }

$forbiddenRuntimePatterns = @(
    "example\.com",
    "test\.k6\.io",
    "user0[0-9]",
    "pass0[0-9]",
    "eventType`"?\s*:\s*`"?sample"
)

foreach ($file in $runtimeFiles) {
    $text = Get-Content -LiteralPath $file.FullName -Raw
    foreach ($pattern in $forbiddenRuntimePatterns) {
        if ($text -match $pattern) {
            Add-Error "Runtime asset contains placeholder pattern '$pattern': $(Get-RelativePath $file.FullName)"
        }
    }
}

$removedConfigMaps = @(
    "K6/infra/k6-api-configmap.yaml",
    "K6/infra/k6-browser-configmap.yaml"
)

foreach ($path in $removedConfigMaps) {
    if (Test-Path -LiteralPath (Join-Root $path)) {
        Add-Error "Static k6 ConfigMap must not be reintroduced; apply scripts generate it from scripts/: $path"
    }
}

$k6ApiTestRun = Join-Root "K6/infra/k6-api-testrun.yaml"
if (Test-Path -LiteralPath $k6ApiTestRun) {
    $text = Get-Content -LiteralPath $k6ApiTestRun -Raw
    foreach ($pattern in @(
        'image:\s*grafana/k6:1\.7\.1',
        'workload:\s*k6-runner',
        'test\.tool:\s*k6',
        'name:\s*k6-runtime-config',
        'name:\s*k6-runtime-secret',
        'name:\s*k6-api-script',
        'file:\s*event_api_load\.js'
    )) {
        if ($text -notmatch $pattern) {
            Add-Error "K6 API TestRun missing required pattern '$pattern'"
        }
    }
}

$k6BrowserPod = Join-Root "K6/infra/k6-browser-pod.yaml"
if (Test-Path -LiteralPath $k6BrowserPod) {
    $text = Get-Content -LiteralPath $k6BrowserPod -Raw
    foreach ($pattern in @(
        'image:\s*grafana/k6:1\.7\.1-with-browser',
        'workload:\s*k6-browser',
        'nodeSelector:',
        'K6_BROWSER_HEADLESS',
        'name:\s*k6-runtime-config',
        'name:\s*k6-browser-script',
        'subPath:\s*browser_smoke\.js'
    )) {
        if ($text -notmatch $pattern) {
            Add-Error "K6 browser Pod missing required pattern '$pattern'"
        }
    }
}

$k6ApplyApi = Join-Root "K6/infra/apply-api.ps1"
if (Test-Path -LiteralPath $k6ApplyApi) {
    $text = Get-Content -LiteralPath $k6ApplyApi -Raw
    foreach ($pattern in @(
        'event_api_load\.js',
        'kubectl create configmap k6-api-script',
        '--dry-run=client',
        'Runtime config missing data key',
        'Runtime secret missing key'
    )) {
        if ($text -notmatch $pattern) {
            Add-Error "K6 API apply harness missing required pattern '$pattern'"
        }
    }
}

$k6ApplyBrowser = Join-Root "K6/infra/apply-browser.ps1"
if (Test-Path -LiteralPath $k6ApplyBrowser) {
    $text = Get-Content -LiteralPath $k6ApplyBrowser -Raw
    foreach ($pattern in @(
        'browser_smoke\.js',
        'kubectl create configmap k6-browser-script',
        '--dry-run=client',
        'Runtime config missing data key'
    )) {
        if ($text -notmatch $pattern) {
            Add-Error "K6 browser apply harness missing required pattern '$pattern'"
        }
    }
}

$k6CloudChecks = @(
    @{ Path = "K6/README.md"; Needles = @("grafana/k6-operator", "4.3.2", "1.3.2", "k6-test", "testruns.k6.io", "workload=k6-runner", "workload=k6-browser", "object storage") },
    @{ Path = "K6/SETUP-GUIDE.md"; Needles = @("## k6 Operator 설치 Runbook", "grafana/k6-operator", "--version 4.3.2", "app version", "1.3.2", "helm status k6-operator", "k6-operator-system", "k6-test", "testruns.k6.io", "privateloadzones.k6.io", "workload=k6-runner", "workload=k6-browser", "RuntimeConfigPath", "RuntimeSecretPath", "object storage") },
    @{ Path = "K6/TEST-GUIDE.md"; Needles = @("4.3.2", "1.3.2", "helm status k6-operator", "k6-test", "testruns.k6.io", "workload=k6-runner", "workload=k6-browser", "RuntimeConfigPath", "RuntimeSecretPath", "summary-api", "object storage") },
    @{ Path = "K6/infra/RUNTIME-CONTRACT.md"; Needles = @("grafana/k6-operator", "4.3.2", "1.3.2", "helm status k6-operator", "k6-test", "testruns.k6.io", "privateloadzones.k6.io", "workload=k6-runner", "workload=k6-browser", "object storage") },
    @{ Path = "K6/scripts/run-api.ps1"; Needles = @("ProjectName", "--summary-export", "summary-api") },
    @{ Path = "K6/scripts/run-browser.ps1"; Needles = @("ProjectName", "--summary-export", "summary-browser") }
)

foreach ($check in $k6CloudChecks) {
    $path = Join-Root $check.Path
    if (-not (Test-Path -LiteralPath $path)) {
        continue
    }
    $text = Read-TextFile $path
    foreach ($needle in $check.Needles) {
        if ($text -notmatch [regex]::Escape($needle)) {
            Add-Error "k6 cloud operating standard token '$needle' missing from $($check.Path)"
        }
    }
}

$nGrinderCloudChecks = @(
    @{ Path = "nGrinder/README.md"; Needles = @("3.5.9-p1", "Controller", "Agent", "private subnet", "security group", "12000-12009", "object storage", "archive") },
    @{ Path = "nGrinder/SETUP-GUIDE.md"; Needles = @("3.5.9-p1", "2025-09-24", "private subnet", "security group", "8080/tcp", "16001/tcp", "12000-12009/tcp", "docker compose -p ngrinder", "object storage", "Agent Management") },
    @{ Path = "nGrinder/TEST-GUIDE.md"; Needles = @("3.5.9-p1", "docker compose -p ngrinder", "security group", "test.baseUrl", "test.eventPayload", "health -> login -> list -> detail -> event", "reports/<project>/<yyyymmdd>/", "object storage", "archive") },
    @{ Path = "nGrinder/compose/docker-compose.yml"; Needles = @("name: ngrinder", "ngrinder/controller:3.5.9-p1", "ngrinder/agent:3.5.9-p1", "12000-12009:12000-12009", "networks:", "driver: bridge") },
    @{ Path = "nGrinder/compose/up.ps1"; Needles = @("ProjectName", "AgentScale", "docker compose -p", "--scale", "--remove-orphans", "Pull") },
    @{ Path = "nGrinder/compose/down.ps1"; Needles = @("ProjectName", "docker compose -p", "down") }
)

foreach ($check in $nGrinderCloudChecks) {
    $path = Join-Root $check.Path
    if (-not (Test-Path -LiteralPath $path)) {
        continue
    }
    $text = Read-TextFile $path
    foreach ($needle in $check.Needles) {
        if ($text -notmatch [regex]::Escape($needle)) {
            Add-Error "nGrinder cloud operating standard token '$needle' missing from $($check.Path)"
        }
    }
}

$verificationStateChecks = @(
    @{ Path = "README.md"; Needles = @("현재 검증 수준", "JMeter", "k6 Operator", "Docker Desktop", "런타임 자원은 정리") },
    @{ Path = "STANDARD-LOADTEST-GUIDE.md"; Needles = @("현재 검증 수준", "NKS k6 Operator", "Docker Desktop Compose", "실제 대상 시스템 부하 실행") },
    @{ Path = "COMPARISON-REPORT-GUIDE.md"; Needles = @("현재 자산 검증 상태", 'no-op `TestRun`', 'Controller HTTP `200`', "대상 시스템에 실제 부하") },
    @{ Path = "PREP-CHECKLIST.md"; Needles = @("현재 검증 수준", "NKS Operator 검증 완료", "로컬 기동 검증 완료", "대상 시스템 부하 실행") },
    @{ Path = "FINAL-DELIVERABLES.md"; Needles = @("검증 상태 요약", "NKS k6 Operator", "Docker Desktop Compose", "프로젝트별 실제 환경에서 수행") },
    @{ Path = "OPERATIONS-HARNESS.md"; Needles = @("검증 수준 표기 기준", "설치 체인 검증", "실행 체인 검증", "대상 부하 검증") },
    @{ Path = "docs/notion-loadtest-comparison.md"; Needles = @("현재 자산 검증 상태", "NKS k6 Operator", "Docker Desktop Compose", "런타임 자원은 정리") },
    @{ Path = "docs/dooray.md"; Needles = @("현재 자산 검증 상태", "NKS k6 Operator", "Docker Desktop Compose", "런타임 자원은 정리") },
    @{ Path = "docs/notion-loadtest-comparison.csv"; Needles = @("검증 상태", "NKS k6 Operator 4.3.2", "Docker Desktop Compose", "대상 시스템 부하 실행") }
)

foreach ($check in $verificationStateChecks) {
    $path = Join-Root $check.Path
    if (-not (Test-Path -LiteralPath $path)) {
        continue
    }
    $text = Read-TextFile $path
    foreach ($needle in $check.Needles) {
        if ($text -notmatch [regex]::Escape($needle)) {
            Add-Error "Current verification state token '$needle' missing from $($check.Path)"
        }
    }
}

$nGrinderCompose = Join-Root "nGrinder/compose/docker-compose.yml"
if (Test-Path -LiteralPath $nGrinderCompose) {
    $text = Read-TextFile $nGrinderCompose
    if ($text -match '(?m)^\s*container_name\s*:') {
        Add-Error "nGrinder Compose must not use fixed container_name because it blocks repeatable project naming"
    }
    if ($text -match '/opt/ngrinder-agent') {
        Add-Error "nGrinder Agent service must not share a persistent agent home volume across scaled replicas"
    }
}

Write-Host "Workspace validation"
Write-Host "Root     : $root"
Write-Host "Errors   : $($errors.Count)"
Write-Host "Warnings : $($warnings.Count)"

foreach ($item in $errors) {
    Write-Host "[ERROR] $item"
}

foreach ($item in $warnings) {
    Write-Host "[WARN]  $item"
}

if ($errors.Count -gt 0 -or ($Strict -and $warnings.Count -gt 0)) {
    exit 1
}

Write-Host "[OK] Workspace consistency checks passed"
