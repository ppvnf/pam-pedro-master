#!/usr/bin/env sh
set -eu

set_perms() {
    chmod -R "$1" "$3"
    chown -R "$2" "$3"
}

POSTGRES_USER=guacamole
POSTGRES_PASSWORD=$(tr -dc 'A-Za-z0-9' < /dev/urandom 2>/dev/null | head -c 20)
export POSTGRES_USER POSTGRES_PASSWORD
envsubst < "/config/tomcat/guacamole.tpl.properties" \
    | install -m 400 -o tomcat -g tomcat /dev/stdin "$GUACW_HOME/guacamole.properties"
envsubst '$POSTGRES_USER,$POSTGRES_PASSWORD' < "/config/sql/create-guacamole-role.tpl.sql" \
    | install -m 400 -o postgres -g postgres /dev/stdin /tmp/create-guacamole-role.sql
set_perms 700 tomcat:tomcat /certs
set_perms 2750 guacd:tomcat "$GUAC_RECORDS"