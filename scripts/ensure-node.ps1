param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$NodeVersion = '20.18.0'
)

$ErrorActionPreference = 'Stop'

function Write-Step($msg) { Write-Host "  >> $msg" -ForegroundColor Cyan }
function Write-Ok($msg) { Write-Host "  [OK] $msg" -ForegroundColor Green }

$targetDir = Join-Path $RepoRoot 'packages\node'
$nodeExe = Join-Path $targetDir 'node.exe'
if (Test-Path $nodeExe) {
    Write-Ok "Bundled Node already exists: $nodeExe"
    return
}

Write-Step "Downloading Node.js v$NodeVersion for Windows..."
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
        throw "Unexpected archive layout: $extracted"
    }

    New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
    Copy-Item -Path (Join-Path $extracted '*') -Destination $targetDir -Recurse -Force
    Write-Ok "Node installed to $targetDir"
} finally {
    Remove-Item -Recurse -Force $tempRoot -ErrorAction SilentlyContinue
}
