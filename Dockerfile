FROM alpine:latest

RUN apk add --no-cache socat

EXPOSE 7000

# TCP 测试: 收到任何连接回复 PONG
CMD ["sh", "-c", "echo 'SERVER_READY'; socat TCP-LISTEN:7000,reuseaddr,fork SYSTEM:'echo PONG'"]