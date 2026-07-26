#!/bin/sh
set -eu

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
container_engine="${CONTAINER_ENGINE:-podman}"
image_name="${VALHEIM_IMAGE:-localhost/landoria-valheim:latest}"

command -v "$container_engine" >/dev/null 2>&1 || {
    echo "The configured container engine is unavailable: $container_engine" >&2
    exit 1
}

"$container_engine" build --pull=always --tag "$image_name" "$script_dir"
"$container_engine" image inspect "$image_name" --format 'Built image: {{.Id}}'
