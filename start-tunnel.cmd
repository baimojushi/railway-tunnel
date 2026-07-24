@echo off
chcp 65001 >NUL
title Cloudflare Tunnel - RAG Frontend
cd /d "%~dp0"
setlocal enabledelayedexpansion

echo ============================================
echo  Cloudflare Tunnel - RAG Frontend
echo ============================================
echo.

:: === CONFIG ===
set "SSH_KEY=%USERPROFILE%\.ssh\id_ed25519_railway"
set "WSL_DISTRO=Ubuntu-22.04"
set "SSH_USER=baimo"
set "LOCAL_PORT=3000"
set "TUNNEL_PORT=3001"

:: === 1) GET WSL IP ===
echo [1/5] Getting WSL IP...
for /f %%i in ('wsl -d %WSL_DISTRO% hostname -I 2^>NUL') do set "WSL_IP=%%i" & goto :ip_ok
:ip_ok
if "%WSL_IP%"=="" (echo FAILED & pause & exit /b 1)
echo     WSL IP: %WSL_IP%

:: === 2) ENSURE SSH SERVER IN WSL ===
echo [2/5] Checking WSL SSH server...
wsl -d %WSL_DISTRO% sudo service ssh status >NUL 2>&1
if errorlevel 1 (
    wsl -d %WSL_DISTRO% sudo service ssh start >NUL 2>&1
)
echo     OK

:: === 3) START SSH REVERSE TUNNEL ===
echo [3/5] Starting SSH reverse tunnel (port %TUNNEL_PORT% ^<^-- localhost:%LOCAL_PORT%)...

:: Kill old ones
for /f "tokens=2" %%p in ('tasklist /FI "IMAGENAME eq ssh.exe" /FO CSV /NH 2^>NUL ^| findstr "3001"') do taskkill /F /PID %%p >NUL 2>&1

:: Start new (in background via Powershell to avoid cmd.exe hanging)
powershell -NoProfile -Command ^
    "$p=Start-Process -WindowStyle Hidden -PassThru -FilePath ssh.exe -ArgumentList '-N', '-i', '%SSH_KEY:\=\\\%', '-o', 'StrictHostKeyChecking=accept-new', '-o', 'ServerAliveInterval=30', '-o', 'ServerAliveCountMax=3', '-o', 'ExitOnForwardFailure=yes', '-R', '%TUNNEL_PORT%:localhost:%LOCAL_PORT%', '%SSH_USER%@%WSL_IP%'; Start-Sleep 2; if (!$p.HasExited) { Write-Output 'SSH_PID='+$p.Id } else { Write-Output 'SSH_EXITED' }" > "%TEMP%\ssh_tunnel_result.txt" 2>&1

set /p SSH_RESULT=<"%TEMP%\ssh_tunnel_result.txt"
echo     %SSH_RESULT%

:: Verify
wsl -d %WSL_DISTRO% ss -tlnp ^| findstr ":%TUNNEL_PORT% " >NUL 2>&1
if errorlevel 1 (echo     WARNING: SSH tunnel may not be ready) else (echo     SSH tunnel listening on %TUNNEL_PORT%)

:: === 4) START CLOUDFLARED ===
echo [4/5] Starting cloudflared tunnel...
wsl -d %WSL_DISTRO% tmux kill-session -t cftunnel 2>/dev/null
wsl -d %WSL_DISTRO% tmux new-session -d -s cftunnel ^
    "cloudflared tunnel --protocol http2 --url http://127.0.0.1:%TUNNEL_PORT%"

:: === 5) WAIT FOR URL ===
echo [5/5] Waiting for Cloudflare public URL...
set "CF_URL="
set "WAIT_COUNT=0"
:wait_loop
powershell -NoProfile -Command "Start-Sleep 2"
set /a WAIT_COUNT+=1
for /f %%u in ('wsl -d %WSL_DISTRO% tmux capture-pane -t cftunnel -p ^| grep -o "https://[a-z-]*\.trycloudflare\.com"') do set "CF_URL=%%u" & goto :got_url

:: Check tunnel health
wsl -d %WSL_DISTRO% tmux has-session -t cftunnel >NUL 2>&1
if errorlevel 1 (
    echo     Tunnel died, restarting...
    wsl -d %WSL_DISTRO% tmux new-session -d -s cftunnel ^
        "cloudflared tunnel --protocol http2 --url http://127.0.0.1:%TUNNEL_PORT%"
)

if %WAIT_COUNT% lss 30 goto :wait_loop

:got_url

:: === SHOW RESULT ===
cls
echo ============================================
echo  TUNNEL STATUS
echo ============================================
echo.
if not "%CF_URL%"=="" (
    echo  PUBLIC URL: %CF_URL%
    echo  LOCAL:      http://127.0.0.1:%LOCAL_PORT%  (RAG UI)
) else (
    echo  PUBLIC URL: (still waiting...)
    wsl -d %WSL_DISTRO% tmux capture-pane -t cftunnel -p ^| findstr "https://" 2>NUL
)
echo.
echo  Stack:
echo    Cloudflare Edge --http2--^> WSL cloudflared
echo      --^> 127.0.0.1:%TUNNEL_PORT% (SSH reverse tunnel)
echo        --^> Windows 127.0.0.1:%LOCAL_PORT%
echo.
echo  Controls:
echo    stop-tunnel.cmd  -  Stop all tunnels
echo    tmux attach -t cftunnel  -  View cloudflared logs
echo.
echo  Press Ctrl+C to stop
echo ============================================

:: === MONITOR LOOP ===
:monitor
powershell -NoProfile -Command "Start-Sleep 10"
wsl -d %WSL_DISTRO% tmux has-session -t cftunnel >NUL 2>&1
if errorlevel 1 (
    echo [%DATE% %TIME%] cloudflared died, restarting...
    wsl -d %WSL_DISTRO% tmux new-session -d -s cftunnel ^
        "cloudflared tunnel --protocol http2 --url http://127.0.0.1:%TUNNEL_PORT%"
)
goto :monitor
