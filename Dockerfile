FROM golang:1-alpine AS builder
LABEL maintainer="acme-dns@tcely.33mail.com"

RUN apk add --update gcc musl-dev git

RUN go get github.com/tcely/acme-dns
WORKDIR /go/src/github.com/tcely/acme-dns
RUN CGO_ENABLED=1 go build
RUN mv acme-dns /acme-dns && git checkout latest && mv config.cfg /config.cfg

FROM tcely/alpine-aports

EXPOSE 10053/tcp 10053/udp 10080/tcp 10443/tcp

ENTRYPOINT ["/usr/local/bin/acme-dns"]
COPY --from=builder /acme-dns /usr/local/bin/acme-dns

RUN mkdir -p /etc/acme-dns /var/lib/acme-dns && chown -R postgres:postgres /var/lib/acme-dns && ln -s acme-dns /var/lib/postgresql

COPY --from=builder /config.cfg /etc/acme-dns/config.cfg

VOLUME ["/etc/acme-dns", "/var/lib/acme-dns"]

RUN apk --no-cache add ca-certificates curl

WORKDIR /var/lib/acme-dns
USER postgres:postgres

HEALTHCHECK CMD curl --silent --insecure -w '%{http_code}\n' "$(awk 'BEGIN {scheme="http"; ip="127.0.0.1"; port="80";} /^tls =/ {scheme="http"; if ($NF !~ /none/) {scheme=scheme "s";}} /^ip =/ {ip=$NF; gsub(/"/, "", ip);} /^port =/ {port=$NF; gsub(/"/, "", port);} END {printf "%s://%s:%d/health\n", scheme, ip, port;}' /etc/acme-dns/config.cfg)" | awk 'BEGIN { rc=1; } /^200$/ { rc=0; } END { exit rc; }'
