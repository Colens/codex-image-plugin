param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$NodeVersion = '20.18.0'
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'init-console.ps1')

function Write-Step($msg) { Write-Host "  >> $msg" -ForegroundColor Cyan }
function Write-Ok($msg) { Write-Host "  [OK] $msg" -ForegroundColor Green }

$targetDir = Join-Path $RepoRoot 'packages\node'
$nodeExe = Join-Path $targetDir 'node.exe'
if (Test-Path $nodeExe) {
    Write-Ok "内置 Node 已存在: $nodeExe"
    return
}

Write-Step "正在下载 Node.js v$NodeVersion（Windows）..."
$zipName = "node-v$NodeVersion-win-x64.zip"
$url = "https://nodejs.org/dist/v$NodeVersion/$zipName"
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("cobabaai-node-" + [guid]::NewGuid().ToString('N'))
$zipPath = Join-Path $tempRoot $zipName

New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null
try {
    Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing
    Expand-Archive -Path $zipPath -DestinationPath $tempRoot -Force
    $extracted = Join-Path $tempRoot "node-v$NodeVersion-win-x64"
    if (-not (Test-Path $extracted)) {
        throw "压缩包结构异常: $extracted"
    }

    New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
    Copy-Item -Path (Join-Path $extracted '*') -Destination $targetDir -Recurse -Force
    Write-Ok "Node 已安装到 $targetDir"
} finally {
    Remove-Item -Recurse -Force $tempRoot -ErrorAction SilentlyContinue
}
