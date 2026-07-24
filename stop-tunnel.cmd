@echo off
chcp 65001 >NUL
title Stop Tunnel
cd /d "%~dp0"

echo [*] 停止 Cloudflare 隧道...
wsl -d Ubuntu-22.04 tmux kill-session -t cftunnel 2>/dev/null

echo [*] 停止 SSH 反向隧道...
taskkill /F /FI "WINDOWTITLE eq SSH Tunnel - *" /T >NUL 2>&1

echo [*] 所有隧道已停止
timeout /t 2 /nobreak >NUL
