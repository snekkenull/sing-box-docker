FROM alpine AS base
WORKDIR /root
RUN set -ex \
    && apk upgrade \
    && apk add git \
    && git clone https://github.com/SagerNet/sing-box.git

FROM golang:1.20-alpine AS builder
COPY --from=base /root/sing-box /go/src/github.com/sagernet/sing-box
WORKDIR /go/src/github.com/sagernet/sing-box
ARG GOPROXY=""
ENV GOPROXY ${GOPROXY}
ENV CGO_ENABLED=1
RUN set -ex \
    && apk add git build-base \
    && export COMMIT=$(git rev-parse --short HEAD) \
    && export VERSION=$(go run ./cmd/internal/read_tag) \
    && go build -v -trimpath -tags with_gvisor,with_quic,with_dhcp,with_wireguard,with_ech,with_utls,with_reality_server,with_clash_api,with_acme \
        -o /go/bin/sing-box \
        -ldflags "-X \"github.com/sagernet/sing-box/constant.Version=$VERSION\" -s -w -buildid=" \
        ./cmd/sing-box

FROM alpine AS dist
WORKDIR /data
RUN set -ex \
    && apk upgrade \
    && apk add bash tzdata ca-certificates \
    && rm -rf /var/cache/apk/* \
    && wget https://github.com/SagerNet/sing-geoip/releases/latest/download/geoip.db \
    && wget https://github.com/SagerNet/sing-geosite/releases/latest/download/geosite.db
    
COPY --from=builder /go/bin/sing-box /usr/local/bin/sing-box

ENTRYPOINT ["sing-box"]
