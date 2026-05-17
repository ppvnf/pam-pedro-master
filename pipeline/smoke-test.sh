#!/usr/bin/env sh
set -eu

exec_test() {
	podman exec guac-smoke sh -c "$1" >/dev/null 2>&1
}

check_service() {
	name="$1"
	cmd="$2"

	if ! eval "\$$name"; then
		if exec_test "$cmd"; then
			echo "Service $name is now UP"
			eval "$name=true"
		fi
	fi
}

pull_image() {
	echo "Pulling image: $IMAGE"
	podman pull "$IMAGE"
}

start_container() {
	echo "Running container: $CONTAINER"
	podman run \
		-e guacamole_auth_sso_saml=true \
		-e guacamole_auth_ldap=false \
		-d --name "$CONTAINER" "$IMAGE"
}

dump_failure_logs() {
	echo "Printing container logs"
	podman logs "$CONTAINER"
	echo "Failure! Guacamole endpoint never became healthy"
	printf "--- Service status ---\nPostgreSQL: %s\nguacd: %s\nGuacamole: %s\n---" \
		"$PG_UP" "$GD_UP" "$GM_UP"
}

main() {
	IMAGE="$CI_REGISTRY_IMAGE/master:$CI_COMMIT_SHA"
	GM_URL="https://localhost:8443/guacamole"
	CONTAINER="guac-smoke"
	PG_UP=false
	GD_UP=false
	GM_UP=false

	pull_image
	start_container

	for i in $(seq 0 59); do
		check_service "PG_UP" "su -s /bin/sh postgres -c 'pg_isready'"
		check_service "GD_UP" "nc -z localhost 4822"
		check_service "GM_UP" "curl -fsS --cert-type P12 --cert /certs/client.p12:\$(cat /certs/password) -k $GM_URL"

		if [[ $PG_UP == true && $GD_UP == true && $GM_UP == true ]]; then
			echo "All services healthy!"
			exit 0
		fi

		sleep 1
	done

	dump_failure_logs
	exit 1
}

main
