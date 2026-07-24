@echo off
chcp 65001 >NUL
title frpc - Railway 内网穿透客户端
setlocal enabledelayedexpansion

set "FRP_VER=v0.70.1"
set "FRP_DIR=D:\ai\railway-tunnel\frp_%FRP_VER%_windows_amd64"
set "FRP_ZIP=%FRP_DIR%.zip"
set "FRP_URL=https://github.com/fatedier/frp/releases/download/%FRP_VER%/frp_%FRP_VER%_windows_amd64.zip"
set "FRPC_EXE=%FRP_DIR%\frpc.exe"
set "CONFIG_FILE=%FRP_DIR%\frpc.toml"

:: ---------- 步骤 1: 如果 frpc.exe 不存在则下载 ----------
if not exist "%FRPC_EXE%" (
    echo [*] frpc 未找到，正在下载...
    echo [*] 下载地址: %FRP_URL%
    powershell -NoProfile -Command ^
        "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; ^
         Invoke-WebRequest -Uri '%FRP_URL%' -OutFile '%FRP_ZIP%' -UseBasicParsing"
    if errorlevel 1 (
        echo [!] 下载失败，请检查网络连接或代理设置
        pause
        exit /b 1
    )
    echo [*] 解压中...
    powershell -NoProfile -Command "Expand-Archive -Path '%FRP_ZIP%' -DestinationPath 'D:\ai\railway-tunnel' -Force"
    if exist "%FRP_ZIP%" del "%FRP_ZIP%"
    if not exist "%FRPC_EXE%" (
        echo [!] 解压后未找到 frpc.exe
        pause
        exit /b 1
    )
    echo [*] frpc 下载完成
) else (
    echo [*] frpc 已存在，跳过下载
)

:: ---------- 步骤 2: 配置 frpc.toml ----------
echo.
echo ============================================
echo  frpc 配置 (Railway 内网穿透)
echo ============================================
echo.
set /p "SERVER_ADDR=请输入 Railway 服务地址 (如 xxx.railway.app): "
set /p "SERVER_PORT=请输入 Railway 服务端口 (默认 7000): "
if "%SERVER_PORT%"=="" set SERVER_PORT=7000
set /p "AUTH_TOKEN=请输入认证 Token: "
set /p "LOCAL_PORT=请输入本地服务端口 (如 3000/8000/3389): "
set /p "REMOTE_PORT=请输入远程映射端口 (如 8080/2222): "
set /p "PROXY_NAME=请输入隧道名称 (默认 tunnel-1): "
if "%PROXY_NAME%"=="" set PROXY_NAME=tunnel-1

(
    echo serverAddr = "%SERVER_ADDR%"
    echo serverPort = %SERVER_PORT%
    echo auth.method = "token"
    echo auth.token = "%AUTH_TOKEN%"
    echo.
    echo [[proxies]]
    echo name = "%PROXY_NAME%"
    echo type = "tcp"
    echo localIP = "127.0.0.1"
    echo localPort = %LOCAL_PORT%
    echo remotePort = %REMOTE_PORT%
) > "%CONFIG_FILE%"

echo.
echo [*] 配置文件已写入: %CONFIG_FILE%

:: ---------- 步骤 3: 启动 frpc ----------
echo.
echo [*] 正在启动 frpc...
echo [*] 按 Ctrl+C 停止
echo.
"%FRPC_EXE%" -c "%CONFIG_FILE%"

pause
