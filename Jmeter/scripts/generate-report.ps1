param(
    [string]$JMeterHome = "C:\tools\apache-jmeter-5.6.3",
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$JtlFile,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$HtmlDir
)

$jmeterExe = Join-Path $JMeterHome "bin\jmeter.bat"

if (-not [System.IO.Path]::IsPathRooted($JtlFile)) {
    $JtlFile = Join-Path $PSScriptRoot $JtlFile
}

if (-not [System.IO.Path]::IsPathRooted($HtmlDir)) {
    $HtmlDir = Join-Path $PSScriptRoot $HtmlDir
}

$resolvedJtl = Resolve-Path -LiteralPath $JtlFile

if (-not (Test-Path $jmeterExe)) {
    throw "JMeter executable not found: $jmeterExe"
}

if (Test-Path $HtmlDir) {
    Remove-Item -Path $HtmlDir -Recurse -Force
}

& $jmeterExe -g $resolvedJtl.Path -o $HtmlDir
if ($LASTEXITCODE -ne 0) {
    throw "JMeter report generation failed with exit code $LASTEXITCODE"
}

Write-Host "HTML report generated: $HtmlDir"
