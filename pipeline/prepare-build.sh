#!/usr/bin/env sh
set -eu

image_exists() {
	if SPECS=$(skopeo inspect --format '{{range .Env}}{{println .}}{{end}}' "docker://$1" 2>/dev/null); then
		echo "$SPECS" >specs
		return 0
	else
		return 1
	fi
}

get_latest_image() {
	image="${1%%:VER*}"
	tag_suffix="${1#*:VER}"
	pattern="$2"
	for repo in $REMOTE_REPOS; do
		tags=$(skopeo list-tags "docker://$repo/$image" 2>/dev/null |
			grep -Eo '"[0-9][^"]*"' |
			tr -d '"' |
			grep -E "$pattern" |
			sort -rV || true)

		if [ -z "$tags" ]; then
			continue
		fi

		for tag in $tags; do
			tagged_image="$image:$tag$tag_suffix"
			local_image="$CI_REGISTRY_IMAGE/$tagged_image"
			remote_image="$repo/$tagged_image"

			if image_exists "$local_image"; then
				echo "Found locally $tagged_image!" >&2
				echo "$tag"
				return 0
			elif image_exists "$remote_image"; then
				echo "New version $tagged_image! Pulling from $repo..." >&2
				skopeo copy "docker://$remote_image" "docker://$local_image" >&2
				echo "$tag"
				return 0
			fi
		done
	done
	echo "Error: Could not find a valid image for $image across any registry." >&2
	return 1
}

main() {
	set -a
	env | sort >/tmp/ini_env
	REMOTE_REPOS="mirror.gcr.io docker.io"
	POSTGRES_MAJOR=18
	GUACD_VER=$(get_latest_image "guacamole/guacd:VER" '^[0-9]+\.[0-9]+\.[0-9]+$')
	GUAC_VER=$(get_latest_image "guacamole/guacamole:VER" '^[0-9]+\.[0-9]+\.[0-9]+$')
	JAVA_MAJOR=$(awk -F'[=.-]' '/^JAVA_VER/{print $3}' specs)
	TOMCAT_MAJOR=$(awk -F'[=.-]' '/^TOMCAT_VER/{print $2}' specs)
	ALPINE_VER=$(get_latest_image "alpine:VER" '^[0-9]+\.[0-9]+$')
	POSTGRES_VER=$(get_latest_image "postgres:VER-alpine$ALPINE_VER" "^$POSTGRES_MAJOR\.[0-9]+$")
	JAVA_VER=$(get_latest_image "eclipse-temurin:VER" "^$JAVA_MAJOR\.[0-9]+\.[0-9]+_[0-9]+-jre-alpine-$ALPINE_VER" | cut -d '-' -f 1)
	TOMCAT_VER=$(get_latest_image "tomcat:VER-jre$JAVA_MAJOR" "^$TOMCAT_MAJOR\.[0-9]+\.[0-9]+$")
	IMAGE_VER="guacamole$GUAC_VER-tomcat$TOMCAT_VER-alpine$ALPINE_VER-postgres$POSTGRES_VER-java$JAVA_VER"
	rm specs
	env | sort >/tmp/end_env
	comm -3 /tmp/ini_env /tmp/end_env >build.env
}

main
