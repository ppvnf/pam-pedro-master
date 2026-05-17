#!/usr/bin/env sh
set -eu

enable_optional_extensions() {
    EXTENSIONS="guacamole_auth_sso_saml guacamole_auth_ldap"
    for var in $EXTENSIONS; do
        eval enabled=\$$var
        jar_name="${var//_/-}"
        extension_path="$GUACW_HOME/extensions/$jar_name.jar"
        if [ "$enabled" = true ]; then
            ln -sf "$GUACW_HOME/optional_extensions/$jar_name.jar" "$extension_path"
        else
            rm -f "$extension_path"
        fi
    done
}

generate_certs() {
    gen_pass() { tr -dc 'A-Za-z0-9' < /dev/urandom 2>/dev/null | head -c 20; }
    SERVER_CERT_PASS=$(gen_pass)
    export SERVER_CERT_PASS
    envsubst < /config/tomcat/server.tpl.xml > server.xml
    keytool -genkeypair \
        -alias serveralias \
        -keyalg RSA \
        -dname "CN=guacamole,O=MyOrg" \
        -keystore server.keystore \
        -keypass "$SERVER_CERT_PASS" \
        -storepass "$SERVER_CERT_PASS"
    keytool -genkeypair \
        -alias clientalias \
        -keyalg RSA \
        -dname "CN=client,O=MyOrg" \
        -keystore client.keystore \
        -keypass "$SERVER_CERT_PASS" \
        -storepass "$SERVER_CERT_PASS"
    keytool -exportcert \
        -alias clientalias \
        -keystore client.keystore \
        -storepass "$SERVER_CERT_PASS" \
        -file client.cer
    keytool -importcert \
        -alias clientalias \
        -file client.cer \
        -keystore server.keystore \
        -storepass "$SERVER_CERT_PASS" \
        -noprompt
    keytool -importkeystore \
        -srckeystore client.keystore \
        -destkeystore client.p12 \
        -deststoretype PKCS12 \
        -deststorepass "$SERVER_CERT_PASS" \
        -srcstorepass "$SERVER_CERT_PASS"
    rm -f client.cer
    printf "%s" "$SERVER_CERT_PASS" | install -m 700 /dev/stdin password
}

 main() {
    enable_optional_extensions
    if [ ! -f server.xml ]; then
        generate_certs
    fi
    ln -sf "$PWD/server.xml" "$TOMCAT_HOME/conf/server.xml"
 }

main