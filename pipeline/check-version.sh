#!/usr/bin/env sh
set -eu

if glab release view "$IMAGE_VER" > /dev/null 2>&1; then
    echo "Release $IMAGE_VER already exists, skipping notification."
    exit 0
fi

glab release create "$IMAGE_VER" --notes "$IMAGE_VER" --ref "$CI_COMMIT_SHA"
