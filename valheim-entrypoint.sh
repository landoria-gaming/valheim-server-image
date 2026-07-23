#!/bin/sh
set -eu

: "${SERVER_NAME:?SERVER_NAME is required}"
: "${WORLD_NAME:?WORLD_NAME is required}"
: "${SERVER_PASSWORD?SERVER_PASSWORD is required}"
: "${INSTANCE_ID:?INSTANCE_ID is required}"
: "${SERVER_PORT:?SERVER_PORT is required}"

case "$SERVER_PORT" in
    ''|*[!0-9]*) echo "SERVER_PORT must be a number." >&2; exit 1 ;;
esac
[ "$SERVER_PORT" -ge 1 ] && [ "$SERVER_PORT" -le 65534 ] || {
    echo "SERVER_PORT must be between 1 and 65534." >&2
    exit 1
}

if [ -n "$SERVER_PASSWORD" ] && [ "${#SERVER_PASSWORD}" -lt 5 ]; then
    echo "SERVER_PASSWORD must be empty or contain at least five characters." >&2
    exit 1
fi

mkdir -p /mods/plugins /mods/config
if [ ! -f /mods/config/BepInEx.cfg ]; then
    cp /opt/bepinex-default-config/BepInEx.cfg /mods/config/BepInEx.cfg
fi

rm -rf /opt/valheim-server/BepInEx/plugins /opt/valheim-server/BepInEx/config
ln -s /mods/plugins /opt/valheim-server/BepInEx/plugins
ln -s /mods/config /opt/valheim-server/BepInEx/config

set -- \
    -nographics \
    -batchmode \
    -name "$SERVER_NAME" \
    -port "$SERVER_PORT" \
    -world "$WORLD_NAME" \
    -password "$SERVER_PASSWORD" \
    -savedir /data \
    -public "${PUBLIC_SERVER:-0}" \
    -instanceid "${VALHEIM_INSTANCE_ID:-$INSTANCE_ID}"

if [ "${CROSSPLAY:-0}" = "1" ]; then
    set -- "$@" -crossplay
fi

if [ -n "${WORLD_PRESET:-}" ]; then
    set -- "$@" -preset "$WORLD_PRESET"
fi

if [ -n "${WORLD_KEY:-}" ]; then
    set -- "$@" -setkey "$WORLD_KEY"
elif [ -n "${WORLD_MODIFIER:-}" ]; then
    : "${WORLD_MODIFIER_VALUE:?WORLD_MODIFIER_VALUE is required with WORLD_MODIFIER}"
    set -- "$@" -modifier "$WORLD_MODIFIER" "$WORLD_MODIFIER_VALUE"
fi

export DOORSTOP_ENABLED=1
export DOORSTOP_TARGET_ASSEMBLY=./BepInEx/core/BepInEx.Preloader.dll
export LD_LIBRARY_PATH="./doorstop_libs:./linux64:${LD_LIBRARY_PATH:-}"
export LD_PRELOAD="libdoorstop_x64.so${LD_PRELOAD:+:$LD_PRELOAD}"
export SteamAppId=892970

exec ./valheim_server.x86_64 "$@"
