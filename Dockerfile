# build args
ARG GUAC_VER
ARG ALPINE_VER
ARG REGISTRY
ARG JAVA_VER
ARG JAVA_MAJOR
ARG TOMCAT_VER
ARG POSTGRES_VER

FROM $REGISTRY/guacamole/guacamole:$GUAC_VER AS guacamole-webclient
FROM $REGISTRY/guacamole/guacd:$GUAC_VER AS guacamole-guacd
FROM $REGISTRY/tomcat:$TOMCAT_VER-jre$JAVA_MAJOR AS tomcat
FROM $REGISTRY/eclipse-temurin:$JAVA_VER-jre-alpine-$ALPINE_VER AS java
FROM $REGISTRY/alpine:$ALPINE_VER AS builder

COPY build/custom-homepage /custom-homepage
RUN apk add --no-cache zip && \
    cd /custom-homepage && \
    zip -r /custom-homepage.jar .

FROM $REGISTRY/postgres:$POSTGRES_VER-alpine$ALPINE_VER AS postgres

USER root

ARG GUAC_VER
ENV GUAC_VER=$GUAC_VER
ENV GUAC_BASE=/opt/guacamole
ENV GUACW_HOME=/opt/guacamole-webclient
ENV TOMCAT_HOME=/usr/local/tomcat
ENV GUACD_HOME=/opt/guacamole
ENV GUAC_EXT=/opt/guacamole/extensions
ENV GUAC_RECORDS=/var/lib/guacamole/recordings
ENV GUACAMOLE_SCHEMA=/usr/share/guacamole-schema
ENV JAVA_HOME=/opt/java/openjdk
ENV PGDATA=/var/lib/postgresql PGDATABASE=guacamole_db PGUSER=postgres
ENV POSTGRES_UID=70 TOMCAT_UID=71 GUACD_UID=72
ENV INTERNAL_PORT=8443

COPY --chmod=555 build/runtime/ /
COPY --chown=$POSTGRES_UID:$POSTGRES_UID --chmod=400 build/postgres /postgres
COPY --from=guacamole-webclient --chown=$POSTGRES_UID:$POSTGRES_UID --chmod=500 "$GUAC_EXT"/guacamole-auth-jdbc/postgresql/schema/ "$GUACAMOLE_SCHEMA"/
COPY --from=guacamole-webclient --chown=$TOMCAT_UID:$TOMCAT_UID --chmod=700 "$GUAC_BASE"/webapp/ "$TOMCAT_HOME"/webapps/
COPY --from=guacamole-webclient --chown=$TOMCAT_UID:$TOMCAT_UID --chmod=700 \
    "$GUAC_EXT"/guacamole-auth-jdbc/postgresql/guacamole-auth-jdbc-postgresql.jar \
    "$GUAC_EXT"/guacamole-auth-ban/guacamole-auth-ban.jar \
    "$GUAC_EXT"/guacamole-auth-totp/guacamole-auth-totp.jar \
    "$GUAC_EXT"/guacamole-history-recording-storage/guacamole-history-recording-storage.jar \
    "$GUACW_HOME"/extensions/
COPY --from=guacamole-webclient --chown=$TOMCAT_UID:$TOMCAT_UID --chmod=700 \
    "$GUAC_EXT"/guacamole-auth-ldap/guacamole-auth-ldap.jar \
    "$GUAC_EXT"/guacamole-auth-sso/saml/guacamole-auth-sso-saml.jar \
    "$GUACW_HOME"/optional_extensions/
COPY --from=guacamole-webclient --chown=$TOMCAT_UID:$TOMCAT_UID --chmod=700 "$GUAC_BASE"/drivers/postgresql-jdbc.jar "$GUACW_HOME"/lib/postgresql-jdbc.jar
COPY --from=builder --chown=$TOMCAT_UID:$TOMCAT_UID --chmod=400 /custom-homepage.jar "$GUACW_HOME"/extensions/custom-homepage.jar
COPY --from=tomcat --chown=$TOMCAT_UID:$TOMCAT_UID --chmod=700 "$TOMCAT_HOME"/ "$TOMCAT_HOME"/
COPY --from=java --chown=$TOMCAT_UID:$TOMCAT_UID --chmod=700 $JAVA_HOME/ $JAVA_HOME/
COPY --from=guacamole-guacd --chown=$GUACD_UID:$GUACD_UID --chmod=400 /lib/libssl.so.1.1 /lib/libcrypto.so.1.1 /lib/
COPY --from=guacamole-guacd --chown=$GUACD_UID:$GUACD_UID --chmod=500 "$GUAC_BASE"/ "$GUACD_HOME"/

RUN sed -i 's/bash/sh/' /usr/local/tomcat/bin/catalina.sh && \
    sed -i '/libssl1\.1/d;/libcrypto1\.1/d' /opt/guacamole/DEPENDENCIES && \
    adduser -D -H -u "$GUACD_UID" -s /sbin/nologin guacd && \
    adduser -D -H -u "$TOMCAT_UID" -s /sbin/nologin tomcat && \
    apk add --no-cache $(cat "$GUACD_HOME"/DEPENDENCIES) dinit curl gettext-envsubst \
        # java dependencies
        fontconfig ttf-dejavu gnupg ca-certificates p11-kit-trust musl-locales musl-locales-lang binutils tzdata coreutils openssl

VOLUME /certs
VOLUME "$PGDATA"
VOLUME "$GUAC_RECORDS"

EXPOSE "$INTERNAL_PORT"
HEALTHCHECK --interval=10s --timeout=5s --retries=3 CMD ["/scripts/healthcheck.sh"]
ENTRYPOINT ["/usr/sbin/dinit", "--container", "--services-dir", "/services"]
