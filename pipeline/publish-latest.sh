#!/usr/bin/env sh
set -eu

image_exists() {
	skopeo inspect "docker://$1" >/dev/null 2>&1
}

tag_image() {
	base_version="$1"
	tag="$1"
	n=2

	while image_exists "$CI_REGISTRY_IMAGE/pam:$tag"; do
		echo "$tag already exists, trying v$n"
		tag="$base_version-v$n"
		n=$((n + 1))
	done
}

publish_tags() {
	for TAG in "$@"; do
		skopeo copy \
			"docker://$CI_REGISTRY_IMAGE/master:$CI_COMMIT_SHA" \
			"docker://$CI_REGISTRY_IMAGE/pam:$TAG"
		echo "$TAG was successfully published!"
	done
}

main() {
	tag_image "$IMAGE_VER"
	publish_tags "$tag" "latest"
}

main
