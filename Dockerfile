FROM alpine:latest

RUN apk add --no-cache wget && \
    wget -q -O /tmp/frp.tar.gz \
      "https://github.com/fatedier/frp/releases/download/v0.70.1/frp_0.70.1_linux_amd64.tar.gz" && \
    tar -xzf /tmp/frp.tar.gz -C /tmp/ && \
    cp /tmp/frp_0.70.1_linux_amd64/frps /usr/local/bin/frps && \
    chmod +x /usr/local/bin/frps && \
    rm -rf /tmp/frp*

COPY frps.toml /etc/frp/frps.toml

EXPOSE 7000

CMD ["frps", "-c", "/etc/frp/frps.toml"]
