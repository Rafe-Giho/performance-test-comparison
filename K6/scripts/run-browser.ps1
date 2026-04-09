param(
    [string]$ScriptPath = ".\browser_smoke.js",
    [string]$BaseUrl = "https://test.k6.io/"
)

$env:BASE_URL = $BaseUrl
$env:K6_BROWSER_HEADLESS = "true"

k6 run $ScriptPath
