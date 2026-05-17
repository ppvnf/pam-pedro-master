#!/usr/bin/env sh
CERT_PASS=$(cat "/certs/password")
URL="https://localhost:$INTERNAL_PORT/guacamole"
curl -fsS --cert-type P12 --cert /certs/client.p12:$CERT_PASS --insecure $URL && \
    nc -z localhost 4822 && \
    pg_isready -U postgres