#!/bin/bash
docker build -t=vadosl/shadowsocks:libev -t=vadosl/shadowsocks:3.3.5 . -f Dockerfile-libev && \
docker build -t=vadosl/shadowsocks:server-libev . -f Dockerfile-server-libev && \
docker build -t=vadosl/shadowsocks:local-libev . -f Dockerfile-local-libev
