param(
    [string]$JMeterHome = "C:\tools\apache-jmeter-5.6.3",
    [string]$JtlFile = "..\reports\sample-local\result.jtl",
    [string]$HtmlDir = "..\reports\sample-local\html"
)

$jmeterExe = Join-Path $JMeterHome "bin\jmeter.bat"
$resolvedJtl = Resolve-Path $JtlFile

if (Test-Path $HtmlDir) {
    Remove-Item -Path $HtmlDir -Recurse -Force
}

& $jmeterExe -g $resolvedJtl -o $HtmlDir

Write-Host "HTML report generated: $HtmlDir"
