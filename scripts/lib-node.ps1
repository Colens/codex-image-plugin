$ErrorActionPreference = 'Stop'

function Get-RepoRoot {
    param([string]$StartDir = (Split-Path -Parent $PSScriptRoot))
    return (Resolve-Path $StartDir).Path
}

function Get-CodexHomePath {
    if ($env:CODEX_HOME) { return $env:CODEX_HOME }
    return (Join-Path $env:USERPROFILE '.codex')
}

function Get-BundledNodeExe {
    param([string]$Root)
    $candidates = @(
        (Join-Path $Root 'packages\node\node.exe'),
        (Join-Path $Root 'packages\node\bin\node.exe')
    )
    foreach ($path in $candidates) {
        if (Test-Path $path) { return (Resolve-Path $path).Path }
    }
    return $null
}

function Get-CodexInstalledNodeExe {
    $codexHome = Get-CodexHomePath
    $candidates = @(
        (Join-Path $codexHome 'packages\node\node.exe'),
        (Join-Path $codexHome 'packages\node\bin\node.exe')
    )
    foreach ($path in $candidates) {
        if (Test-Path $path) { return (Resolve-Path $path).Path }
    }
    return $null
}

function Get-NpmCli {
    param([string]$NodeExe)
    $nodeDir = Split-Path -Parent $NodeExe
    $npmCmd = Join-Path $nodeDir 'npm.cmd'
    if (Test-Path $npmCmd) { return $npmCmd }
    return 'npm'
}

function Use-PortableNode {
    param([string]$NodeExe)
    $nodeDir = Split-Path -Parent $NodeExe
    $env:Path = "$nodeDir;$env:Path"
}

function Install-NodeToCodexHome {
    param([string]$SourceRoot)
    $sourceNode = Get-BundledNodeExe -Root $SourceRoot
    if (-not $sourceNode) {
        throw "未找到内置 Node: $SourceRoot/packages/node"
    }

    $destRoot = Join-Path (Get-CodexHomePath) 'packages\node'
    if (Test-Path $destRoot) {
        Remove-Item -Recurse -Force $destRoot
    }
    New-Item -ItemType Directory -Force -Path $destRoot | Out-Null

    $sourceDir = Join-Path $SourceRoot 'packages\node'
    Copy-Item -Path (Join-Path $sourceDir '*') -Destination $destRoot -Recurse -Force
    return (Get-CodexInstalledNodeExe)
}

function Resolve-NodeForInstall {
    param(
        [string]$RepoRoot,
        [ValidateSet('Auto', 'BundledOnly', 'DownloadIfMissing')]
        [string]$Mode = 'Auto'
    )

    $bundled = Get-BundledNodeExe -Root $RepoRoot
    if ($bundled) {
        return @{
            NodeExe = $bundled
            Source = 'bundled'
            RepoRoot = $RepoRoot
        }
    }

    if ($Mode -eq 'BundledOnly') {
        throw '未找到内置 Node（packages/node/node.exe），请重新运行安装脚本以自动下载。'
    }

    $ensureScript = Join-Path $PSScriptRoot 'ensure-node.ps1'
    if (-not (Test-Path $ensureScript)) {
        throw '未找到 ensure-node.ps1，无法自动下载 Node。'
    }

    & $ensureScript -RepoRoot $RepoRoot | Out-Host
    $bundled = Get-BundledNodeExe -Root $RepoRoot
    if (-not $bundled) {
        throw '自动下载 Node.js 失败。'
    }

    return @{
        NodeExe = $bundled
        Source = 'downloaded'
        RepoRoot = $RepoRoot
    }
}

function Invoke-PluginNpmInstall {
    param(
        [string]$PluginDir,
        [string]$NodeExe
    )

    Use-PortableNode -NodeExe $NodeExe
    $npmCli = Get-NpmCli -NodeExe $NodeExe
    Push-Location $PluginDir
    try {
        & $npmCli install '--omit=dev'
        if ($LASTEXITCODE -ne 0) { throw ('npm install 失败（退出码 ' + $LASTEXITCODE + '）') }
        & $npmCli run build
        if ($LASTEXITCODE -ne 0) { throw ('npm run build 失败（退出码 ' + $LASTEXITCODE + '）') }
    } finally {
        Pop-Location
    }
}

function Format-TomlPath {
    param([string]$Path)
    return ($Path -replace '\\', '/')
}
