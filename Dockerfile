FROM alpine:latest

# 安装 wget 并下载 frp v0.70.1 Linux amd64 二进制
RUN apk add --no-cache wget && \
    wget -q -O /tmp/frp.tar.gz \
      "https://github.com/fatedier/frp/releases/download/v0.70.1/frp_0.70.1_linux_amd64.tar.gz" && \
    tar -xzf /tmp/frp.tar.gz -C /tmp/ && \
    cp /tmp/frp_0.70.1_linux_amd64/frps /usr/local/bin/frps && \
    chmod +x /usr/local/bin/frps && \
    rm -rf /tmp/frp*

COPY frps.toml /etc/frp/frps.toml

EXPOSE 7000

# 启动 frps，如果退出则 sleep 保持容器存活以便查看日志
CMD ["sh", "-c", "echo '=== FRPS CONFIG ===' && cat /etc/frp/frps.toml && echo '=== STARTING FRPS ===' && frps -c /etc/frp/frps.toml; echo FRPS_EXITED_CODE=$? && sleep 3600"]
