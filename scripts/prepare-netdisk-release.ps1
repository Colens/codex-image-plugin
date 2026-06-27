param(
    [string]$NodeSource = 'D:\githubproject\Codex-Chinese-Setup\packages\node',
    [string]$OutputDir = (Join-Path (Split-Path -Parent $PSScriptRoot) 'dist')
)

$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot
$DistRoot = Join-Path $OutputDir ('cobabaai-codex-image-netdisk-' + (Get-Date -Format 'yyyyMMdd'))
$ZipPath = "$DistRoot.zip"

function Write-Step($msg) { Write-Host ">> $msg" -ForegroundColor Cyan }
function Write-Ok($msg) { Write-Host "[OK] $msg" -ForegroundColor Green }

Write-Step 'Preparing netdisk release folder...'
if (Test-Path $DistRoot) { Remove-Item -Recurse -Force $DistRoot }
New-Item -ItemType Directory -Force -Path $DistRoot | Out-Null

$exclude = @('dist', '.git', 'cobabaai-image-plugin\node_modules', 'packages\node')
Get-ChildItem $RepoRoot -Force | Where-Object {
    $name = $_.Name
    $name -notin $exclude
} | ForEach-Object {
    Copy-Item $_.FullName -Destination $DistRoot -Recurse -Force
}

Write-Step 'Copying bundled Node.js...'
if (-not (Test-Path (Join-Path $NodeSource 'node.exe'))) {
    throw "Node source not found: $NodeSource\node.exe"
}
Copy-Item $NodeSource (Join-Path $DistRoot 'packages\node') -Recurse -Force
Write-Ok 'Bundled Node copied'

. (Join-Path $PSScriptRoot 'lib-node.ps1')
$nodeInfo = Resolve-NodeForInstall -RepoRoot $DistRoot -Mode 'BundledOnly'
$pluginDir = Join-Path $DistRoot 'cobabaai-image-plugin'

Write-Step 'Pre-installing plugin dependencies with bundled Node...'
Invoke-PluginNpmInstall -PluginDir $pluginDir -NodeExe $nodeInfo.NodeExe
Write-Ok 'node_modules baked into release'

Write-Step 'Creating zip archive...'
if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }
Compress-Archive -Path $DistRoot -DestinationPath $ZipPath -Force

Write-Host ''
Write-Ok "Netdisk package ready:"
Write-Host "  Folder: $DistRoot"
Write-Host "  Zip:    $ZipPath"
Write-Host ''
Write-Host 'Upload the zip to cloud storage. Users extract and run 一键安装.bat (no Node install needed).'
