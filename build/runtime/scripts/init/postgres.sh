#!/usr/bin/env sh
set -eu

generate_guacadmin() {
    GUACAMOLE_ADMIN_USER="guacadmin"
    GUACAMOLE_ADMIN_PASSWORD=$(tr -dc 'A-Za-z0-9' < /dev/urandom 2>/dev/null | head -c 20)
    SALT=$(head -c 20 /dev/urandom | sha256sum | awk '{print toupper($1)}')
    HASH=$(printf "%s%s" "$GUACAMOLE_ADMIN_PASSWORD" "$SALT" | sha256sum | awk '{print toupper($1)}')
    export GUACAMOLE_ADMIN_USER SALT HASH
    envsubst < "/config/sql/create-guacamole-admin.tpl.sql" > /tmp/create-guacamole-admin.sql
    psql -f /tmp/create-guacamole-admin.sql
    printf "%s" "$GUACAMOLE_ADMIN_PASSWORD" | install -m 700 /dev/stdin "$PGDATA/guacadmin_password"
}

get_schema_version() {
    TABLE_EXISTS=$(psql -tAc "SELECT EXISTS (SELECT FROM pg_tables WHERE tablename = 'guacamole_version');")
    if [ "$TABLE_EXISTS" = "t" ]; then
        psql -tAc "SELECT version_num FROM guacamole_version LIMIT 1;"
    else
        printf "0.0.0"
    fi
}

backup_database() {
    install -d -o postgres -g postgres -m 700 "$PGDATA/backups"
    BACKUP_FILE="$PGDATA/backups/BACKUP-$SCHEMA_VER-$(date +%Y%m%d%H%M%S).sql"
    pg_dump -f "$BACKUP_FILE"
}

compare_version() {
    [ "$(printf '%s\n' "$2" "$1" | sort -V | head -n1)" != "$1" ]
}

apply_upgrades() {
    for f in "$GUACAMOLE_SCHEMA/upgrade/"*.sql; do
        SCRIPT_VER=$(basename "$f" | awk -F'[-.]' '{print $3"."$4"."$5}')
        # Run upgrade script if SCRIPT_VER > SCHEMA_VER
        if compare_version "$SCRIPT_VER" "$SCHEMA_VER"; then
            printf "Applying upgrade script: %s\n" "$f"
            psql -f "$f" || printf "WARNING: Upgrade script %s encountered an error!\n" "$f"
        fi
    done
}

register_schema_version() {
    envsubst < "/config/sql/register-schema-version.tpl.sql" > /tmp/register_schema_version.sql
    psql -f /tmp/register_schema_version.sql
}

main() {
    if [ ! -d "$PGDATA/base" ]; then
        initdb
        pg_ctl start
        createdb
        psql -f "$GUACAMOLE_SCHEMA/001-create-schema.sql"
        generate_guacadmin
        register_schema_version
    else
        pg_ctl start
        SCHEMA_VER=$(get_schema_version)
        # Only enter upgrade logic if GUAC_VER > SCHEMA_VER
        if compare_version "$GUAC_VER" "$SCHEMA_VER"; then
            backup_database
            apply_upgrades
            register_schema_version
        fi
    fi
    psql -f /tmp/create-guacamole-role.sql
    rm -f /tmp/*.sql
    pg_ctl stop
}

main