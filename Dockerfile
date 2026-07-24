FROM alpine:latest

RUN apk add --no-cache socat

EXPOSE 7000

# TCP echo server: 客户端发送什么，就回复什么
CMD ["sh", "-c", "echo 'ECHO_SERVER_READY' && socat TCP-LISTEN:7000,reuseaddr,fork EXEC:cat,ptty,raw,echo=0"]
