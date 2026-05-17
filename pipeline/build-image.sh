#!/usr/bin/env sh
set -eu

SHA_IMAGE="$CI_REGISTRY_IMAGE/master:$CI_COMMIT_SHA"

buildah build \
	--format docker \
	--build-arg REGISTRY="$CI_REGISTRY_IMAGE" \
	--build-arg JAVA_MAJOR="$JAVA_MAJOR" \
	--build-arg GUAC_VER="$GUAC_VER" \
	--build-arg ALPINE_VER="$ALPINE_VER" \
	--build-arg TOMCAT_VER="$TOMCAT_VER" \
	--build-arg JAVA_VER="$JAVA_VER" \
	--build-arg POSTGRES_VER="$POSTGRES_VER" \
	--label image_version="$IMAGE_VER" \
	--label commit_sha="$CI_COMMIT_SHA" \
	--tag "$SHA_IMAGE" .

buildah push "$SHA_IMAGE"

printf "Publishing image!\nImage: %s\n" "$SHA_IMAGE"
