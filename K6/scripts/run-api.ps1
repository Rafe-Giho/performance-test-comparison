param(
    [string]$ScriptPath = ".\event_api_load.js",
    [string]$BaseUrl = "https://example.com",
    [string]$Username = "user01",
    [string]$Password = "pass01"
)

$env:BASE_URL = $BaseUrl
$env:USERNAME = $Username
$env:PASSWORD = $Password

k6 run $ScriptPath
