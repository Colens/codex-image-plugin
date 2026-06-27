@echo off
chcp 65001 >nul
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0configure-key.ps1"
if errorlevel 1 (
  echo.
  echo 配置失败，请查看上方错误信息。
  pause
  exit /b 1
)
echo.
pause
