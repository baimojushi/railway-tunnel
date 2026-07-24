# Railway 内网穿透 — frp 部署方案

使用 [Railway](https://railway.app) 免费服务器 + [frp](https://github.com/fatedier/frp) 实现内网穿透。

## 架构

```
┌─────────── 你的 Windows 本机 ───────────┐      ┌────────── Railway (免费) ──────────┐
│  frpc (客户端) ──TCP 隧道──→            │      │  frps (服务端 / Docker)              │
│  本地端口 (例如 3000/3389)               │─────→│  TCP: xxx.railway.app:PORT           │
└────────────────────────────────────────┘      └─────────────────────────────────────┘
                                                      ↑
                                              外部访问者从此连接
```

## 第一步：部署 frps 到 Railway

### 方式 A：GitHub + Railway 自动部署 (推荐)

1. 在 GitHub 创建新仓库，将 `D:\ai\railway-tunnel\` 下所有文件推送到仓库
2. 登录 [railway.app](https://railway.app) → Dashboard → **New Project**
3. 选择 **Deploy from GitHub repo** → 选择刚创建的仓库
4. Railway 自动检测 Dockerfile 并构建部署
5. 部署完成后 → 进入服务 → **Settings** → 找到 **TCP Proxy**
   - Railway 会为 `railway.toml` 中定义的 7000 端口生成一个 TCP 端点
   - 格式：`tcps://tcp.us-east-1.railway.app:PORT`
   - 记下这个地址和端口 → 填入本机 `frpc.toml` 的 `serverAddr` 和 `serverPort`

### 方式 B：Railway CLI

```bash
# 安装 CLI (需要 npm)
npm i -g @railway/cli

# 登录
railway login

# 在项目目录部署
cd D:\ai\railway-tunnel
railway init
railway up
```

## 第二步：修改 Token

**在 Railway 端**：打开 `frps.toml`，将 `auth.token` 改为一个随机密码

**在本机端**：打开 `frpc.toml`（或运行 `start-frpc.bat`），使用相同的 token

## 第三步：启动 frpc 本机端

```bash
# 交互式配置 + 启动
D:\ai\railway-tunnel\start-frpc.bat

# 或手动启动
frpc -c frpc.toml
```

脚本会自动：
- 下载 frp v0.70.1 Windows 版（仅首次）
- 提示输入服务地址、端口、token
- 生成 frpc.toml 配置文件
- 启动 frpc 守护进程

## 第四步：测试连接

从外部访问：

```bash
# 如果映射了本地 3000 → 远程 8080
curl http://your-railway-app.railway.app:8080

# 如果映射了本地 SSH 22 → 远程 2222
ssh user@your-railway-app.railway.app -p 2222
```

## 文件结构

```
D:\ai\railway-tunnel\
├── Dockerfile           # frps 构建脚本 → Railway
├── frps.toml            # frps 服务端配置
├── railway.toml         # Railway 端口映射定义
├── frpc.toml.example    # frpc 客户端配置模板
├── start-frpc.bat       # Windows 一键启动脚本 (自动下载+配置+启动)
└── README.md            # 本文件
```

## Railway 免费套餐注意事项

| 项目 | 说明 |
|---|---|
| 免费额度 | $5 / 月 (约 500 小时/月的计算时间) |
| 服务睡眠 | 免费套餐服务在无流量一段时间后会休眠 |
| TCP 端口 | Railway 支持 TCP Proxy，在 Settings 中查看端点 |
| 带宽 | 免费用户有带宽限制，大流量场景不适合 |
| 唤醒 | 有请求时会自动唤醒，首次唤醒有 ~5s 延迟 |

## 安全建议

1. **务必修改默认 token**，否则任何人可以连接你的 frps 服务器
2. 不要暴露敏感端口（如 MySQL 3306）到公网
3. 如果只用于开发测试，建议使用随机高端口号
