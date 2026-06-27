$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ScriptDir 'scripts\lib-node.ps1')

$PluginSrc = Join-Path $ScriptDir 'cobabaai-image-plugin'
$RepoRoot = Get-RepoRoot -StartDir $ScriptDir
$CodexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE '.codex' }
$MarketplaceRoot = Join-Path $CodexHome 'marketplaces\cobabaai-local'
$PluginDest = Join-Path $MarketplaceRoot 'plugins\cobabaai-image'
$ConfigPath = Join-Path $CodexHome 'config.toml'

function Write-Step($msg) { Write-Host "  >> $msg" -ForegroundColor Cyan }
function Write-Ok($msg) { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "  [!!] $msg" -ForegroundColor Yellow }

function Write-Utf8NoBom($path, $content) {
    $dir = Split-Path -Parent $path
    if ($dir) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    [System.IO.File]::WriteAllText($path, $content, [System.Text.UTF8Encoding]::new($false))
}

function Find-CodexCli {
    if ($env:CODEX_BIN -and (Test-Path $env:CODEX_BIN)) { return $env:CODEX_BIN }
    $cmd = Get-Command codex -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $binRoot = Join-Path $env:LOCALAPPDATA 'OpenAI\Codex\bin'
    if (Test-Path $binRoot) {
        $exe = Get-ChildItem $binRoot -Recurse -Filter 'codex.exe' -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1
        if ($exe) { return $exe.FullName }
    }
    return $null
}

Write-Host ''
Write-Host '  ========================================' -ForegroundColor Cyan
Write-Host '     CobabaAi Image Plugin Installer' -ForegroundColor Cyan
Write-Host '  ========================================' -ForegroundColor Cyan
Write-Host ''

if (-not (Test-Path $PluginSrc)) {
    throw "Plugin directory not found: $PluginSrc"
}

Write-Step 'Resolving Node.js (bundled or auto-download)...'
$installMode = if ($env:INSTALL_MODE -eq 'netdisk') { 'BundledOnly' } else { 'Auto' }
$nodeInfo = Resolve-NodeForInstall -RepoRoot $RepoRoot -Mode $installMode
Use-PortableNode -NodeExe $nodeInfo.NodeExe
Write-Ok "Using Node: $($nodeInfo.NodeExe) ($($nodeInfo.Source))"

Write-Step 'Installing MCP dependencies...'
if (Test-Path (Join-Path $PluginSrc 'node_modules')) {
    Write-Ok 'node_modules already present (netdisk release), running build only'
    Push-Location $PluginSrc
    try {
        $npmCli = Get-NpmCli -NodeExe $nodeInfo.NodeExe
        & $npmCli run build
        if ($LASTEXITCODE -ne 0) { throw "npm run build failed (exit $LASTEXITCODE)" }
    } finally {
        Pop-Location
    }
} else {
    Invoke-PluginNpmInstall -PluginDir $PluginSrc -NodeExe $nodeInfo.NodeExe
}
Write-Ok 'Dependencies ready'

Write-Step 'Installing portable Node to ~/.codex/packages/node...'
$runtimeNodeExe = Install-NodeToCodexHome -SourceRoot $RepoRoot
Write-Ok "Runtime Node: $runtimeNodeExe"

Write-Step 'Deploying plugin to Codex...'
New-Item -ItemType Directory -Force -Path (Split-Path $PluginDest) | Out-Null
if (Test-Path $PluginDest) {
    Remove-Item -Recurse -Force $PluginDest
}
Copy-Item -Recurse -Force $PluginSrc $PluginDest
Write-Ok "Plugin copied to $PluginDest"

Write-Step 'Creating marketplace manifest...'
$MarketplaceManifestPath = Join-Path $MarketplaceRoot '.agents\plugins\marketplace.json'
$marketplaceJson = @'
{
  "name": "cobabaai-local",
  "interface": {
    "displayName": "CobabaAi Local"
  },
  "plugins": [
    {
      "name": "cobabaai-image",
      "source": {
        "source": "local",
        "path": "./plugins/cobabaai-image"
      },
      "policy": {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL"
      },
      "category": "Creative"
    }
  ]
}
'@
Write-Utf8NoBom $MarketplaceManifestPath $marketplaceJson
$legacyManifest = Join-Path $MarketplaceRoot 'marketplace.json'
if (Test-Path $legacyManifest) {
    Remove-Item $legacyManifest -Force
}
Write-Ok 'marketplace manifest created'

Write-Step 'Checking COBABAAI_API_KEY...'
$EnvFilePath = Join-Path $CodexHome 'cobabaai-image.env'

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

function Save-KeyToEnvFile($path, $key) {
    $envContent = @"
# CobabaAi 生图插件配置
# 获取密钥: https://cobabaai.com/
COBABAAI_API_KEY=$key
# 可选，默认 gpt-image-2
# COBABAAI_IMAGE_MODEL=gpt-image-2
"@
    Write-Utf8NoBom $path $envContent
}

$existingKey = Read-KeyFromEnvFile $EnvFilePath
if (-not $existingKey) {
    $existingKey = [Environment]::GetEnvironmentVariable('COBABAAI_API_KEY', 'User')
}
if (-not $existingKey) {
    $existingKey = $env:COBABAAI_API_KEY
}
if (-not $existingKey) {
    Write-Warn 'COBABAAI_API_KEY not found'
    if ($env:SKIP_KEY_PROMPT -eq '1') {
        Write-Warn 'SKIP_KEY_PROMPT=1, skipping key input'
    } else {
        Write-Host '  Get your sk- key from cobabaai.com console' -ForegroundColor Gray
        Write-Host '  You can also run 配置密钥.bat or ./configure-key.sh later.' -ForegroundColor Gray
        $inputKey = Read-Host '  Paste API key (leave empty to skip)'
        if ($inputKey -and $inputKey.Trim()) {
            $inputKey = $inputKey.Trim()
            Save-KeyToEnvFile $EnvFilePath $inputKey
            Write-Ok "API key saved to $EnvFilePath"
        } else {
            Write-Warn 'Skipped key setup. Run 配置密钥.bat or ./configure-key.sh later.'
        }
    }
} else {
    if (-not (Read-KeyFromEnvFile $EnvFilePath)) {
        Save-KeyToEnvFile $EnvFilePath $existingKey
        Write-Ok "Existing key copied to $EnvFilePath"
    } else {
        Write-Ok 'API key already configured in cobabaai-image.env'
    }
}

Write-Step 'Registering plugin with Codex CLI...'
$codexCli = Find-CodexCli
if (-not $codexCli) {
    Write-Warn 'Codex CLI not found. Restart Codex and run: codex plugin add cobabaai-image@cobabaai-local'
} else {
    Write-Ok "Codex CLI: $codexCli"
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $marketplaceAdd = & $codexCli plugin marketplace add $MarketplaceRoot --enable plugins 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0 -and ($marketplaceAdd -notmatch 'already added')) {
            throw "codex plugin marketplace add failed: $marketplaceAdd"
        }
        $pluginAdd = & $codexCli plugin add cobabaai-image@cobabaai-local --enable plugins 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0) {
            throw "codex plugin add failed: $pluginAdd"
        }
    } finally {
        $ErrorActionPreference = $prevEap
    }
    Write-Ok 'Plugin registered and installed'
}

Write-Step 'Updating Codex config.toml...'
New-Item -ItemType Directory -Force -Path $CodexHome | Out-Null
$configContent = if (Test-Path $ConfigPath) { Get-Content $ConfigPath -Raw -Encoding UTF8 } else { '' }

$mcpBlock = @"

[plugins."cobabaai-image@cobabaai-local".mcp_servers.cobabaai-image]
enabled = true
command = "$(Format-TomlPath $runtimeNodeExe)"
args = ["server/index.js"]
default_tools_approval_mode = "prompt"
tool_timeout_sec = 600
env_vars = ["COBABAAI_API_KEY", "COBABAAI_IMAGE_MODEL"]
"@

if ($configContent -notmatch '\[plugins\."cobabaai-image@cobabaai-local"\.mcp_servers\.cobabaai-image\]') {
    if ($configContent -and -not $configContent.EndsWith("`n")) {
        $configContent += "`n"
    }
    $configContent += $mcpBlock + "`n"
    Write-Utf8NoBom $ConfigPath $configContent
    Write-Ok 'MCP settings added to config.toml'
} else {
    # Update command to bundled node if block already exists
    $nodePathLiteral = Format-TomlPath $runtimeNodeExe
    if ($configContent -notmatch [regex]::Escape($nodePathLiteral)) {
        $configContent = $configContent -replace '(?ms)\[plugins\."cobabaai-image@cobabaai-local"\.mcp_servers\.cobabaai-image\][^\[]*', ($mcpBlock.TrimStart() + "`n")
        Write-Utf8NoBom $ConfigPath $configContent
        Write-Ok 'MCP settings updated in config.toml'
    } else {
        Write-Ok 'MCP settings already in config.toml, skipped'
    }
}

Write-Host ''
Write-Host '  ========================================' -ForegroundColor Green
Write-Host '           Installation complete!' -ForegroundColor Green
Write-Host '  ========================================' -ForegroundColor Green
Write-Host ''
Write-Host '  Next steps:' -ForegroundColor White
Write-Host '  1. Restart Codex or start a new conversation' -ForegroundColor Gray
Write-Host '  2. Check @ Plugins -> CobabaAi 生图 is installed' -ForegroundColor Gray
Write-Host '  3. Try: use gpt-image-2 to generate a cat on the moon' -ForegroundColor Yellow
Write-Host '  4. To change API key: 配置密钥.bat (Windows) or ./configure-key.sh (macOS)' -ForegroundColor Gray
Write-Host ''
