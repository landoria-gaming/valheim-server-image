#!/bin/sh
set -eu

script_dir="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
container_engine="${CONTAINER_ENGINE:-podman}"
image_name="${VALHEIM_IMAGE:-localhost/landoria-valheim:latest}"
valheim_channel="${VALHEIM_CHANNEL:-current}"
: "${LANDORIA_MOD_REPOSITORY_URL:?LANDORIA_MOD_REPOSITORY_URL is required}"

case "$valheim_channel" in
    current|public-test) ;;
    *) echo "VALHEIM_CHANNEL must be current or public-test." >&2; exit 1 ;;
esac

command -v "$container_engine" >/dev/null 2>&1 || {
    echo "The configured container engine is unavailable: $container_engine" >&2
    exit 1
}

"$container_engine" build --pull=always \
    --build-arg "MOD_REPOSITORY_URL=${LANDORIA_MOD_REPOSITORY_URL%/}" \
    --build-arg "VALHEIM_CHANNEL=$valheim_channel" \
    --tag "$image_name" "$script_dir"
"$container_engine" image inspect "$image_name" --format 'Built image: {{.Id}}'
