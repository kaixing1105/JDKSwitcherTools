@echo off & color 07 & chcp 65001 >nul

echo.
echo   ################################################################
echo   #                                                              #
echo   #                      JDK 版本切换工具                        #
echo   #                       By Xing - 2025                         #
echo   #    该应用需要JDK安装目录为默认目录：C:\Program Files\Java    #
echo   #                                                              #
echo   ################################################################
echo.
echo.

:: 检测 JDK 或 JRE 是否已安装
set "JAVA_DIR=C:\Program Files\Java"
set "JDK_FOUND=0"

if exist "%JAVA_DIR%" (
    :: 匹配 jdk* 和 jre* 目录，只要含有 java.exe 即认为有效安装
    for /d %%i in ("%JAVA_DIR%\jdk*" "%JAVA_DIR%\jre*") do (
        if exist "%%~i\bin\java.exe" (
            set "JDK_FOUND=1"
            goto :CHECK_ADMIN
        )
    )
)

if "%JDK_FOUND%"=="0" (
    echo   ================================================================
    echo       未检测到任何 JDK/JRE 安装目录（应位于：C:\Program Files\Java）
    echo.
    echo       请先安装 JDK 或 JRE 到默认目录后再使用本工具。
    echo.
    echo       3 秒后将自动打开 Oracle Java 下载页面...
    echo.
    echo       https://www.oracle.com/java/technologies/downloads/archive/
    echo.
    echo   ================================================================
    timeout /t 3 >nul
    start https://www.oracle.com/java/technologies/downloads/archive/
    echo.
    echo       网页已打开，请下载安装后重启本工具。
    echo.
    echo   ================================================================
    call :WaitForQorR
    exit /b
)

:CHECK_ADMIN
setlocal enabledelayedexpansion
set "ADMIN_MODE=0"
2>nul (
    > "%SystemRoot%\System32\test.tmp" echo.
    if exist "%SystemRoot%\System32\test.tmp" (
        del "%SystemRoot%\System32\test.tmp"
        set "ADMIN_MODE=1"
    )
)

if "!ADMIN_MODE!"=="0" (
    echo   ================================================================
    echo             正在请求管理员权限...
    echo   ----------------------------------------------------------------
    echo             可能会遇到以下两种情况：
    echo.
    echo             1.  系统启用了UAC - 请点击UAC弹窗的 [是]
    echo             2.  系统禁用了UAC - 将自动尝试直接运行
    echo   ================================================================
    echo   正在打开Windows PowerShell，请稍等...
    powershell -Command "Start-Process PowerShell -ArgumentList '-ExecutionPolicy Bypass -File "%~dp0JDKSwitcher.ps1"' -Verb RunAs"
    exit
)

:: 运行 PowerShell 脚本并捕获错误
powershell -ExecutionPolicy Bypass -File "%~dp0JDKSwitcher.ps1"
if errorlevel 1 (
    echo [错误] PowerShell 执行失败，正在退出...
    pause
    exit /b
)

exit /b %errorlevel%

:WaitForQorR
:: 使用 choice 等待 Q 或 R 键，避免无效字符输出
echo.
echo      (Q) 退出程序      (R) 重启命令行窗口
echo.

choice /c QR /n >nul

if errorlevel 2 (
    echo.
    echo [INFO] 正在重启命令行窗口...
    start "" "%~dp0start.bat"
    exit /b
)
if errorlevel 1 (
    echo.
    echo [INFO] 正在退出程序...
    exit
)
