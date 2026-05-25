#!/usr/bin/env sh
CERT_PASS=$(cat "/certs/password")
URL="https://127.0.0.1:$INTERNAL_PORT/guacamole"
curl -fsS --cert-type P12 --cert /certs/client.p12:$CERT_PASS --insecure $URL && \
    nc -z 127.0.0.1 4822 && \
    pg_isready -U postgres