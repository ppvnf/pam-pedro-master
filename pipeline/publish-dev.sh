#!/usr/bin/env sh
set -eu

echo "Tagging dev image"
skopeo copy \
	"docker://$CI_REGISTRY_IMAGE/master:$CI_COMMIT_SHA" \
	"docker://$CI_REGISTRY_IMAGE/pam:dev"
