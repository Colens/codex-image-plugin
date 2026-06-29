$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ScriptDir 'scripts\init-console.ps1')
. (Join-Path $ScriptDir 'scripts\lib-node.ps1')

$PluginSrc = Join-Path $ScriptDir 'cobabaai-image-plugin'
$RepoRoot = Get-RepoRoot -StartDir $ScriptDir
$CodexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE '.codex' }
$MarketplaceRoot = Join-Path $CodexHome 'marketplaces\cobabaai'
$PluginDest = Join-Path $MarketplaceRoot 'plugins\cobabaai-image'
$GithubRepo = if ($env:COBABAAI_GITHUB_REPO) { $env:COBABAAI_GITHUB_REPO } else { 'Colens/codex-image-plugin' }
$PluginId = 'cobabaai-image@cobabaai'
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
Write-Host '       CobabaAi 生图插件 - 一键安装' -ForegroundColor Cyan
Write-Host '  ========================================' -ForegroundColor Cyan
Write-Host ''

if (-not (Test-Path $PluginSrc)) {
    throw "未找到插件目录: $PluginSrc"
}

Write-Step '正在准备 Node.js（内置或自动下载）...'
$installMode = if ($env:INSTALL_MODE -eq 'netdisk') { 'BundledOnly' } else { 'Auto' }
$nodeInfo = Resolve-NodeForInstall -RepoRoot $RepoRoot -Mode $installMode
Use-PortableNode -NodeExe $nodeInfo.NodeExe
Write-Ok "已使用 Node: $($nodeInfo.NodeExe)（来源: $($nodeInfo.Source)）"

Write-Step '正在安装 MCP 依赖...'
if (Test-Path (Join-Path $PluginSrc 'node_modules')) {
    Write-Ok '依赖已存在，仅执行 build'
    Push-Location $PluginSrc
    try {
        $npmCli = Get-NpmCli -NodeExe $nodeInfo.NodeExe
        & $npmCli run build
        if ($LASTEXITCODE -ne 0) { throw "npm run build 失败（退出码 $LASTEXITCODE）" }
    } finally {
        Pop-Location
    }
} else {
    Invoke-PluginNpmInstall -PluginDir $PluginSrc -NodeExe $nodeInfo.NodeExe
}
Write-Ok '依赖安装完成'

Write-Step '正在安装便携 Node 到 ~/.codex/packages/node ...'
$runtimeNodeExe = Install-NodeToCodexHome -SourceRoot $RepoRoot
Write-Ok "运行 Node: $runtimeNodeExe"

Write-Step '正在部署插件到 Codex...'
New-Item -ItemType Directory -Force -Path (Split-Path $PluginDest) | Out-Null
if (Test-Path $PluginDest) {
    Remove-Item -Recurse -Force $PluginDest
}
Copy-Item -Recurse -Force $PluginSrc $PluginDest
Write-Ok "插件已复制到 $PluginDest"

Write-Step '正在创建插件市场清单...'
$MarketplaceManifestPath = Join-Path $MarketplaceRoot '.agents\plugins\marketplace.json'
$marketplaceJson = @'
{
  "name": "cobabaai",
  "interface": {
    "displayName": "CobabaAi 生图"
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
Write-Ok '插件市场清单已创建'

Write-Step '正在检查 API 密钥...'
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
    [Environment]::SetEnvironmentVariable('COBABAAI_API_KEY', $key, 'User')
    $env:COBABAAI_API_KEY = $key
}

$existingKey = Read-KeyFromEnvFile $EnvFilePath
if (-not $existingKey) {
    $existingKey = [Environment]::GetEnvironmentVariable('COBABAAI_API_KEY', 'User')
}
if (-not $existingKey) {
    $existingKey = $env:COBABAAI_API_KEY
}
if (-not $existingKey) {
    Write-Warn '未找到 API 密钥'
    if ($env:SKIP_KEY_PROMPT -eq '1') {
        Write-Warn '已设置 SKIP_KEY_PROMPT=1，跳过密钥输入'
    } else {
        Write-Host '  请从 cobabaai.com 控制台复制 sk- 开头的密钥' -ForegroundColor Gray
        Write-Host '  也可稍后双击运行「配置密钥.bat」进行配置' -ForegroundColor Gray
        $inputKey = Read-Host '  粘贴 API 密钥（留空跳过）'
        if ($inputKey -and $inputKey.Trim()) {
            $inputKey = $inputKey.Trim()
            Save-KeyToEnvFile $EnvFilePath $inputKey
            Write-Ok "API 密钥已保存到 $EnvFilePath"
        } else {
            Write-Warn '已跳过密钥配置，请稍后运行「配置密钥.bat」'
        }
    }
} else {
    if (-not (Read-KeyFromEnvFile $EnvFilePath)) {
        Save-KeyToEnvFile $EnvFilePath $existingKey
        Write-Ok "已有密钥已写入 $EnvFilePath"
    } else {
        Write-Ok 'cobabaai-image.env 中已配置 API 密钥'
        $syncKey = Read-KeyFromEnvFile $EnvFilePath
        if ($syncKey -and -not [Environment]::GetEnvironmentVariable('COBABAAI_API_KEY', 'User')) {
            [Environment]::SetEnvironmentVariable('COBABAAI_API_KEY', $syncKey, 'User')
            Write-Ok '已同步密钥到 Windows 用户环境变量'
        }
    }
}

Write-Step '正在注册 GitHub 插件市场...'
$codexCli = Find-CodexCli
if (-not $codexCli) {
    Write-Warn '未找到 Codex CLI。请重启 Codex 后手动执行 marketplace add'
} else {
    Write-Ok "Codex CLI: $codexCli"
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $ghAdd = & $codexCli plugin marketplace add $GithubRepo --enable plugins 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0 -and ($ghAdd -notmatch 'already added')) {
            Write-Warn "GitHub 市场注册跳过: $ghAdd"
        } else {
            Write-Ok "GitHub 市场已注册: $GithubRepo"
        }
        $marketplaceAdd = & $codexCli plugin marketplace add $MarketplaceRoot --enable plugins 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0 -and ($marketplaceAdd -notmatch 'already added')) {
            throw "注册本地插件市场失败: $marketplaceAdd"
        }
        $pluginAdd = & $codexCli plugin add $PluginId --enable plugins 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0 -and ($pluginAdd -notmatch 'already')) {
            throw "安装插件失败: $pluginAdd"
        }
    } finally {
        $ErrorActionPreference = $prevEap
    }
    Write-Ok '插件已注册并安装'
}

Write-Step '正在更新 Codex config.toml...'
New-Item -ItemType Directory -Force -Path $CodexHome | Out-Null
$configContent = if (Test-Path $ConfigPath) { Get-Content $ConfigPath -Raw -Encoding UTF8 } else { '' }

$pluginCwd = Format-TomlPath $PluginDest
$mcpBlock = @"

[plugins."$PluginId".mcp_servers.cobabaai-image]
enabled = true
command = "$(Format-TomlPath $runtimeNodeExe)"
args = ["server/index.js"]
cwd = "$pluginCwd"
default_tools_approval_mode = "auto"
tool_timeout_sec = 600
env_vars = ["COBABAAI_API_KEY", "COBABAAI_IMAGE_MODEL"]
"@

if ($configContent -match '\[plugins\."cobabaai-image@(cobabaai-local|cobabaai)"\.mcp_servers\.cobabaai-image\]') {
    $configContent = $configContent -replace '(?ms)\[plugins\."cobabaai-image@(cobabaai-local|cobabaai)"\.mcp_servers\.cobabaai-image\][\s\S]*?(?=\r?\n\[|\z)', ($mcpBlock.TrimStart() + "`n")
} elseif ($configContent -notmatch '\[plugins\."cobabaai-image@cobabaai"\.mcp_servers\.cobabaai-image\]') {
    if ($configContent -and -not $configContent.EndsWith("`n")) {
        $configContent += "`n"
    }
    $configContent += $mcpBlock + "`n"
}
Write-Utf8NoBom $ConfigPath $configContent
Write-Ok 'MCP 配置已写入 config.toml（含 cwd）'

Write-Host ''
Write-Host '  ========================================' -ForegroundColor Green
Write-Host '              安装完成！' -ForegroundColor Green
Write-Host '  ========================================' -ForegroundColor Green
Write-Host ''
Write-Host '  后续步骤：' -ForegroundColor White
Write-Host '  1. 完全退出并重启 Codex' -ForegroundColor Gray
Write-Host '  2. 新建对话 → @ 插件 → 勾选「CobabaAi 生图」' -ForegroundColor Gray
Write-Host '  3. 直接说（可指定模型和分辨率）：' -ForegroundColor Gray
Write-Host '     用 gpt-image-2 画一只在月球上喝酒的猫，1280x1280' -ForegroundColor Yellow
Write-Host '  4. 改密钥：双击「配置密钥.bat」' -ForegroundColor Gray
Write-Host '  5. 出图异常：双击「自检.bat」' -ForegroundColor Gray
Write-Host ''
exit 0
