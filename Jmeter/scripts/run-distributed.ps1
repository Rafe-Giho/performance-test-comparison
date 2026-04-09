param(
    [string]$JMeterHome = "C:\tools\apache-jmeter-5.6.3",
    [string]$PlanPath = "..\plans\web-standard-template.jmx",
    [string]$OutputDir = "..\reports\sample-distributed",
    [string]$RemoteHosts = "10.0.0.11,10.0.0.12",
    [string]$Protocol = "https",
    [string]$Host = "example.com",
    [int]$Port = 443,
    [int]$Threads = 100,
    [int]$RampUp = 60,
    [int]$Loops = 10,
    [int]$ThinkTimeMs = 1000,
    [string]$Username = "user01",
    [string]$Password = "pass01"
)

$jmeterExe = Join-Path $JMeterHome "bin\jmeter.bat"
$resolvedPlan = Resolve-Path $PlanPath
$resolvedOutput = Resolve-Path -LiteralPath $OutputDir -ErrorAction SilentlyContinue
if (-not $resolvedOutput) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    $resolvedOutput = Resolve-Path $OutputDir
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$resultFile = Join-Path $resolvedOutput "result-$timestamp.jtl"
$htmlDir = Join-Path $resolvedOutput "html-$timestamp"

if (-not (Test-Path $jmeterExe)) {
    throw "JMeter executable not found: $jmeterExe"
}

& $jmeterExe `
  -n `
  -t $resolvedPlan `
  -l $resultFile `
  -e `
  -o $htmlDir `
  -R $RemoteHosts `
  -JPROTOCOL=$Protocol `
  -JHOST=$Host `
  -JPORT=$Port `
  -JTHREADS=$Threads `
  -JRAMP_UP=$RampUp `
  -JLOOPS=$Loops `
  -JTHINK_TIME_MS=$ThinkTimeMs `
  -JUSERNAME=$Username `
  -JPASSWORD=$Password

Write-Host "Remote hosts : $RemoteHosts"
Write-Host "JTL          : $resultFile"
Write-Host "HTML         : $htmlDir"
