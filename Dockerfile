FROM alpine:latest

RUN apk add --no-cache socat

EXPOSE 7000

# TCP echo server: 客户端发送的每个数据包都会原样返回
CMD ["sh", "-c", "echo 'SERVER_READY'; socat TCP-LISTEN:7000,reuseaddr,fork -"]