$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ScriptDir 'scripts\init-console.ps1')

$CodexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE '.codex' }
$EnvFilePath = Join-Path $CodexHome 'cobabaai-image.env'

function Write-Utf8NoBom($path, $content) {
    $dir = Split-Path -Parent $path
    if ($dir) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    [System.IO.File]::WriteAllText($path, $content, [System.Text.UTF8Encoding]::new($false))
}

function Read-KeyFromEnvFile($path) {
    if (-not (Test-Path $path)) { return $null }
    foreach ($line in Get-Content $path -Encoding UTF8) {
        $trimmed = $line.Trim()
        if (-not $trimmed -or $trimmed.StartsWith('#')) { continue }
        if ($trimmed -match '^COBABAAI_API_KEY\s*=\s*(.+)$') {
            $value = $Matches[1].Trim().Trim('"').Trim("'")
            if ($value) { return $value }
        }
    }
    return $null
}

Write-Host ''
Write-Host '  CobabaAi 生图 - API 密钥配置' -ForegroundColor Cyan
Write-Host ''

$existingKey = Read-KeyFromEnvFile $EnvFilePath
if (-not $existingKey) {
    $existingKey = [Environment]::GetEnvironmentVariable('COBABAAI_API_KEY', 'User')
}
if (-not $existingKey) {
    $existingKey = $env:COBABAAI_API_KEY
}

if ($existingKey) {
    $masked = if ($existingKey.Length -gt 8) {
        $existingKey.Substring(0, 4) + '****' + $existingKey.Substring($existingKey.Length - 4)
    } else {
        '****'
    }
    Write-Host "  当前已配置: $masked" -ForegroundColor Gray
    Write-Host ''
}

Write-Host '  从 cobabaai.com 控制台复制 sk- 开头的密钥' -ForegroundColor Gray
$inputKey = Read-Host '  粘贴 API 密钥（留空取消）'
if (-not $inputKey -or -not $inputKey.Trim()) {
    Write-Host '  已取消。' -ForegroundColor Yellow
    exit 0
}

$inputKey = $inputKey.Trim()
$envContent = @"
# CobabaAi 生图插件配置
# 获取密钥: https://cobabaai.com/
COBABAAI_API_KEY=$inputKey
# 可选，默认 gpt-image-2
# COBABAAI_IMAGE_MODEL=gpt-image-2
"@

Write-Utf8NoBom $EnvFilePath $envContent
[Environment]::SetEnvironmentVariable('COBABAAI_API_KEY', $inputKey, 'User')
$env:COBABAAI_API_KEY = $inputKey
Write-Host ''
Write-Host "  已保存到: $EnvFilePath" -ForegroundColor Green
Write-Host '  已同步到 Windows 用户环境变量 COBABAAI_API_KEY' -ForegroundColor Green
Write-Host '  请重启 Codex 或新开对话后生效。' -ForegroundColor Gray
Write-Host ''
exit 0
