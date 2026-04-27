param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ProjectName,

    [string]$JMeterHome = "C:\tools\apache-jmeter-5.6.3",
    [string]$PlanPath = "..\plans\web-standard-template.jmx",
    [string]$OutputDir,

    [Parameter(Mandatory = $true)]
    [ValidateSet("http", "https")]
    [string]$Protocol,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Host,

    [Parameter(Mandatory = $true)]
    [ValidateRange(1, 65535)]
    [int]$Port,

    [Parameter(Mandatory = $true)]
    [ValidateRange(1, 2147483647)]
    [int]$Threads,

    [Parameter(Mandatory = $true)]
    [ValidateRange(0, 2147483647)]
    [int]$RampUp,

    [Parameter(Mandatory = $true)]
    [ValidateRange(1, 2147483647)]
    [int]$Loops,

    [Parameter(Mandatory = $true)]
    [ValidateRange(0, 2147483647)]
    [int]$ThinkTimeMs,

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

function Resolve-JMeterExecutable {
    param([string]$Home)

    $candidates = @(
        (Join-Path $Home "bin\jmeter.bat"),
        (Join-Path $Home "bin\jmeter"),
        "jmeter.bat",
        "jmeter"
    )

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }

        $command = Get-Command $candidate -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($command) {
            return $command.Source
        }
    }

    throw "JMeter executable not found. Checked JMeterHome and PATH: $Home"
}

$jmeterExe = Resolve-JMeterExecutable -Home $JMeterHome

if (-not [System.IO.Path]::IsPathRooted($PlanPath)) {
    $PlanPath = Join-Path $PSScriptRoot $PlanPath
}

$resolvedPlan = Resolve-Path -LiteralPath $PlanPath

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
$resultFile = Join-Path $resolvedOutput "result-$timestamp.jtl"
$htmlDir = Join-Path $resolvedOutput "html-$timestamp"

foreach ($pathValue in @($HealthPath, $LoginPath, $ListPath, $DetailPath, $EventPath)) {
    if (-not $pathValue.StartsWith("/")) {
        throw "HTTP path must start with '/': $pathValue"
    }
}

try {
    $null = $EventPayload | ConvertFrom-Json -ErrorAction Stop
} catch {
    throw "EventPayload must be valid JSON: $($_.Exception.Message)"
}

$jmeterArgs = @(
    "-n",
    "-t", $resolvedPlan.Path,
    "-l", $resultFile,
    "-e",
    "-o", $htmlDir,
    "-JPROTOCOL=$Protocol",
    "-JHOST=$Host",
    "-JPORT=$Port",
    "-JTHREADS=$Threads",
    "-JRAMP_UP=$RampUp",
    "-JLOOPS=$Loops",
    "-JTHINK_TIME_MS=$ThinkTimeMs",
    "-JHEALTH_PATH=$HealthPath",
    "-JLOGIN_PATH=$LoginPath",
    "-JLIST_PATH=$ListPath",
    "-JDETAIL_PATH=$DetailPath",
    "-JUSERNAME=$Username",
    "-JPASSWORD=$Password",
    "-JEVENT_PATH=$EventPath",
    "-JEVENT_PAYLOAD=$EventPayload"
)

& $jmeterExe @jmeterArgs
if ($LASTEXITCODE -ne 0) {
    throw "JMeter execution failed with exit code $LASTEXITCODE"
}

Write-Host "JTL  : $resultFile"
Write-Host "HTML : $htmlDir"
