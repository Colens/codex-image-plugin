@echo off

setlocal

chcp 65001 >nul 2>&1

cd /d "%~dp0"



echo.

echo  CobabaAi 生图插件 - 一键安装

echo  ========================================

echo.



powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"

if %ERRORLEVEL% NEQ 0 goto fail



set "ENV_FILE=%USERPROFILE%\.codex\cobabaai-image.env"

if not exist "%ENV_FILE%" (

    echo.

    echo  尚未配置 API 密钥，接下来请粘贴 sk- 密钥...

    echo.

    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0configure-key.ps1"

)



echo.

echo  ========================================

echo  安装完成！请按下面 3 步使用：

echo  ========================================

echo  1. 完全退出 Codex，重新打开

echo  2. 新建对话 -^> @ 插件 -^> 勾选「CobabaAi 生图」

echo  3. 直接说，例如：

echo     用 gpt-image-2 画一只在月球上喝酒的猫，1280x1280

echo.

echo  可用模型：gpt-image-2、nano-banana-fast、nano-banana-pro 等

echo  分辨率示例：1280x1280、1024x1024、1:1、16:9、4K

echo.

pause

exit /b 0



:fail

echo.

echo  安装失败，请查看上方错误信息。

pause

exit /b 1

