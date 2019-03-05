FROM golang:1-alpine AS builder
LABEL maintainer="acme-dns@tcely.33mail.com"

RUN apk add --update gcc musl-dev git

RUN go get github.com/tcely/acme-dns
WORKDIR /go/src/github.com/tcely/acme-dns
RUN git checkout build && CGO_ENABLED=1 go build

FROM tcely/alpine-aports

EXPOSE 10053/tcp 10053/udp 10080/tcp 10443/tcp

ENTRYPOINT ["/usr/local/bin/acme-dns"]
COPY --from=builder /go/src/github.com/tcely/acme-dns/acme-dns /usr/local/bin/acme-dns

RUN mkdir -p /etc/acme-dns /var/lib/acme-dns && chown -R postgres:postgres /var/lib/acme-dns

VOLUME ["/etc/acme-dns", "/var/lib/acme-dns"]

RUN apk --no-cache add ca-certificates

WORKDIR /var/lib/acme-dns
USER postgres:postgres
