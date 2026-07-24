#!/bin/bash
set -e

# 复制配置
cp /mnt/d/ai/railway-tunnel/frps_local.toml /tmp/
cp /mnt/d/ai/railway-tunnel/frpc_local.toml /tmp/

# 启动本地 frps（后台）
/usr/local/bin/frps -c /tmp/frps_local.toml &
FRPS_PID=$!
sleep 2

# 连接 frpc
echo "=== Testing local frp connection ==="
/usr/local/bin/frpc -c /tmp/frpc_local.toml || true

# 清理
kill $FRPS_PID 2>/dev/null
echo "=== Test complete ==="
