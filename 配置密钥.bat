@echo off
setlocal
chcp 65001 >nul 2>&1
cd /d "%~dp0"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0configure-key.ps1"
if %ERRORLEVEL% NEQ 0 goto fail

echo.
echo 配置成功！按任意键关闭窗口...
pause >nul
exit /b 0

:fail
echo.
echo 配置失败，请查看上方错误信息。
pause
exit /b 1
