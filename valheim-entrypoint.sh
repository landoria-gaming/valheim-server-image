#!/usr/bin/env bash
set -euo pipefail

: "${SERVER_NAME:?SERVER_NAME is required}"
: "${WORLD_NAME:?WORLD_NAME is required}"
: "${SERVER_PASSWORD?SERVER_PASSWORD is required}"
: "${INSTANCE_ID:?INSTANCE_ID is required}"
: "${SERVER_PORT:?SERVER_PORT is required}"

case "$SERVER_PORT" in
    ''|*[!0-9]*) echo "SERVER_PORT must be a number." >&2; exit 1 ;;
esac
if [ "$SERVER_PORT" -lt 1 ] || [ "$SERVER_PORT" -gt 65534 ]; then
    echo "SERVER_PORT must be between 1 and 65534." >&2
    exit 1
fi

if [ -n "$SERVER_PASSWORD" ] && [ "${#SERVER_PASSWORD}" -lt 5 ]; then
    echo "SERVER_PASSWORD must be empty or contain at least five characters." >&2
    exit 1
fi

mod_arguments=()
if [[ -n "${LANDORIA_MOD_ARGUMENTS:-}" ]]; then
    read -r -a mod_arguments <<< "$LANDORIA_MOD_ARGUMENTS"
    for argument in "${mod_arguments[@]}"; do
        [[ "$argument" =~ ^[A-Za-z0-9._:/=,+-]+$ ]] || {
            echo "LANDORIA_MOD_ARGUMENTS contains an unsupported argument." >&2
            exit 1
        }
    done
fi

community_server_name="Landoria ${SERVER_NAME#Landoria }"

mkdir -p /mods/plugins /mods/config
if [ ! -f /mods/config/BepInEx.cfg ]; then
    cp /opt/bepinex-default-config/BepInEx.cfg /mods/config/BepInEx.cfg
fi

rm -rf /opt/valheim-server/BepInEx/plugins /opt/valheim-server/BepInEx/config
ln -s /mods/plugins /opt/valheim-server/BepInEx/plugins
ln -s /mods/config /opt/valheim-server/BepInEx/config

valheim_arguments=(
    -nographics \
    -batchmode \
    -name "$community_server_name" \
    -port "$SERVER_PORT" \
    -world "$WORLD_NAME" \
    -password "$SERVER_PASSWORD" \
    -savedir /data \
    -public "${PUBLIC_SERVER:-0}" \
    -instanceid "${VALHEIM_INSTANCE_ID:-$INSTANCE_ID}" \
    -crossplay
)

if [ -n "${WORLD_PRESET:-}" ]; then
    valheim_arguments+=(-preset "$WORLD_PRESET")
fi

if [[ -n "${WORLD_KEYS:-}" ]]; then
    IFS=',' read -r -a world_keys <<< "$WORLD_KEYS"
    for world_key in "${world_keys[@]}"; do
        [[ "$world_key" =~ ^[A-Za-z0-9._-]+$ ]] || {
            echo "WORLD_KEYS contains an invalid key." >&2
            exit 1
        }
        valheim_arguments+=(-setkey "$world_key")
    done
fi

if [[ -n "${WORLD_MODIFIERS:-}" ]]; then
    IFS=',' read -r -a world_modifiers <<< "$WORLD_MODIFIERS"
    for world_modifier in "${world_modifiers[@]}"; do
        [[ "$world_modifier" =~ ^([A-Za-z0-9._-]+)=([A-Za-z0-9._-]+)$ ]] || {
            echo "WORLD_MODIFIERS entries must use name=value." >&2
            exit 1
        }
        valheim_arguments+=(-modifier "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}")
    done
fi

export DOORSTOP_ENABLED=1
export DOORSTOP_TARGET_ASSEMBLY=./BepInEx/core/BepInEx.Preloader.dll
export LD_LIBRARY_PATH="./doorstop_libs:./linux64:${LD_LIBRARY_PATH:-}"
export LD_PRELOAD="libdoorstop_x64.so${LD_PRELOAD:+:$LD_PRELOAD}"
export SteamAppId=892970

exec ./valheim_server.x86_64 "${valheim_arguments[@]}" "${mod_arguments[@]}"
