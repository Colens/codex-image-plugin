$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ScriptDir 'scripts\lib-node.ps1')

$CodexHome = Get-CodexHomePath
$PluginDir = Join-Path $CodexHome 'marketplaces\cobabaai\plugins\cobabaai-image'
$ConfigPath = Join-Path $CodexHome 'config.toml'
$EnvFilePath = Join-Path $CodexHome 'cobabaai-image.env'
$NodeExe = Get-CodexInstalledNodeExe

function Write-Check($ok, $msg) {
    if ($ok) {
        Write-Host "  [OK] $msg" -ForegroundColor Green
    } else {
        Write-Host "  [!!] $msg" -ForegroundColor Red
    }
    return $ok
}

function Read-KeyFromEnvFile($path) {
    if (-not (Test-Path $path)) { return $null }
    foreach ($line in Get-Content $path -Encoding UTF8) {
        $trimmed = $line.Trim()
        if (-not $trimmed -or $trimmed.StartsWith('#')) { continue }
        if ($trimmed -match '^COBABAAI_API_KEY\s*=\s*(.+)$') {
            $value = $Matches[1].Trim().Trim('"').Trim("'")
            if ($value -and $value -notmatch '你的密钥') { return $value }
        }
    }
    return $null
}

function Mask-Key($key) {
    if ($key.Length -gt 8) {
        return $key.Substring(0, 4) + '****' + $key.Substring($key.Length - 4)
    }
    return '****'
}

Write-Host ''
Write-Host '  CobabaAi Image Plugin - Doctor' -ForegroundColor Cyan
Write-Host ''

$allOk = $true

$allOk = (Write-Check (Test-Path $PluginDir) ('Plugin dir: ' + $PluginDir)) -and $allOk
$allOk = (Write-Check (Test-Path (Join-Path $PluginDir 'server\index.js')) 'MCP server/index.js') -and $allOk

if ($NodeExe) {
    Write-Check $true ('Portable Node: ' + $NodeExe) | Out-Null
} else {
    $allOk = (Write-Check $false 'Portable Node missing - run install.ps1') -and $allOk
}

if (Test-Path $ConfigPath) {
    $configText = Get-Content $ConfigPath -Raw -Encoding UTF8
    $hasMcp = $configText -match 'cobabaai-image@(cobabaai-local|cobabaai).*mcp_servers\.cobabaai-image'
    $hasCwd = $configText -match 'cwd\s*=\s*"[^"]*cobabaai-image"'
    if ($hasMcp -and $hasCwd) {
        Write-Check $true 'config.toml MCP block with cwd' | Out-Null
    } else {
        $allOk = (Write-Check $false 'config.toml MCP missing - run install.ps1') -and $allOk
    }
} else {
    $allOk = (Write-Check $false ('config.toml missing: ' + $ConfigPath)) -and $allOk
}

$fileKey = Read-KeyFromEnvFile $EnvFilePath
$userKey = [Environment]::GetEnvironmentVariable('COBABAAI_API_KEY', 'User')
$procKey = $env:COBABAAI_API_KEY

$key = $fileKey
$keySource = 'cobabaai-image.env'
if (-not $key -and $userKey) {
    $key = $userKey
    $keySource = 'Windows User env'
}
if (-not $key -and $procKey) {
    $key = $procKey
    $keySource = 'process env'
}

if ($key) {
    $keyMsg = 'API key configured (' + $keySource + '): ' + (Mask-Key $key)
    Write-Check $true $keyMsg | Out-Null
} else {
    $allOk = (Write-Check $false 'API key missing - run configure-key.ps1') -and $allOk
}

$testScript = Join-Path $ScriptDir 'scripts\test-mcp-load.js'
if ($NodeExe -and (Test-Path $testScript)) {
    try {
        $loadResult = & $NodeExe $testScript 2>&1
        $mcpLoadOk = ($loadResult -join '').Trim() -eq 'loaded'
        $allOk = (Write-Check $mcpLoadOk 'MCP loadLocalConfig can read key') -and $allOk
    } catch {
        $errMsg = 'MCP key load test failed: ' + $_.Exception.Message
        $allOk = (Write-Check $false $errMsg) -and $allOk
    }
}

Write-Host ''
if ($allOk) {
    Write-Host '  All checks passed.' -ForegroundColor Green
    Write-Host '  Restart Codex -> new chat -> @ CobabaAi -> say: draw a cat drinking on the moon' -ForegroundColor Green
} else {
    Write-Host '  Issues found. Run install.ps1, configure key, then fully restart Codex.' -ForegroundColor Yellow
}
Write-Host ''
if ($allOk) { exit 0 } else { exit 1 }
