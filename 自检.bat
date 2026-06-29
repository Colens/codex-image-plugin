@echo off

setlocal

chcp 65001 >nul 2>&1

cd /d "%~dp0"



powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0doctor.ps1"

set ERR=%ERRORLEVEL%



echo.

if %ERR% EQU 0 (

    echo 自检通过！按任意键关闭...

) else (

    echo 自检发现问题，请按上方提示修复。按任意键关闭...

)

pause >nul

exit /b %ERR%

