# Cloudflare Tunnel — 内网穿透

将 Windows 本地服务通过 Cloudflare Tunnel 暴露到公网。

## 架构

```
公网用户 → Cloudflare Edge (HTTP/2)
  → WSL cloudflared
    → SSH 反向隧道 (端口 3001)
      → Windows localhost:3000 (RAG UI)
```

## 文件说明

| 文件 | 用途 |
|------|------|
| `start-tunnel.cmd` | 一键启动隧道 |
| `stop-tunnel.cmd` | 停止隧道 |

## 前置条件

- WSL2 Ubuntu-22.04
- cloudflared-linux-amd64（首次需从 GitHub Releases 下载）
  ```
  curl -sL -o cloudflared-linux https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
  ```
  复制到 WSL: `sudo cp cloudflared-linux /usr/local/bin/cloudflared && sudo chmod +x /usr/local/bin/cloudflared`
- Windows SSH key（首次运行脚本会自动生成）

## 使用

```
start-tunnel.cmd
```

自动完成：获取 WSL IP → 启动 SSH 反向隧道 → 启动 cloudflared → 获取公网 URL

## 管道组成

1. **SSH 反向隧道**: Windows `ssh.exe` → WSL `sshd`，将 `127.0.0.1:3001` (WSL) 转发到 `127.0.0.1:3000` (Windows)
2. **cloudflared**: WSL 内运行，指向 `127.0.0.1:3001`，使用 HTTP/2 协议连接 Cloudflare Edge

## 已知问题

- Cloudflare Tunnel 从国内访问可能不稳定（trycloudflare.com 被限速）
- 如需稳定方案，建议使用国内云服务器 + frp
