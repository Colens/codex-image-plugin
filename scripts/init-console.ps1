# Windows 控制台 UTF-8 初始化（避免中文乱码）
$utf8 = [System.Text.UTF8Encoding]::new($false)
try {
    [Console]::OutputEncoding = $utf8
    [Console]::InputEncoding = $utf8
} catch {}
$global:OutputEncoding = $utf8

if ($Host.Name -eq 'ConsoleHost') {
    try {
        $null = & cmd.exe /c 'chcp 65001 >nul'
        $global:LASTEXITCODE = 0
    } catch {}
}
