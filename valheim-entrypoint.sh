#!/usr/bin/env bash
# Start Valheim with BepInEx and persistent world and mod directories.
set -euo pipefail
: "${SERVER_PASSWORD:?Set SERVER_PASSWORD to at least five characters}"
[[ ${#SERVER_PASSWORD} -ge 5 && "$SERVER_NAME" != *"$SERVER_PASSWORD"* ]] || {
    echo 'Password must have at least five characters and must not appear in the server name.' >&2; exit 1;
}
[[ "$SERVER_PORT" =~ ^[0-9]+$ && "$SERVER_PORT" -ge 1024 && "$SERVER_PORT" -le 65534 ]] || exit 1
[[ "$PUBLIC_SERVER" =~ ^[01]$ && "$CROSSPLAY" =~ ^[01]$ ]] || exit 1
: "${DATA_DIR:=/data}"
[[ "$DATA_DIR" == /* ]] || { echo 'DATA_DIR must be an absolute container path.' >&2; exit 1; }
mkdir -p -- "$DATA_DIR"
[[ -w "$DATA_DIR" ]] || { echo "DATA_DIR is not writable: $DATA_DIR" >&2; exit 1; }
cp -an /opt/bepinex-default-config/. /mods/config/
export DOORSTOP_ENABLED=1
export DOORSTOP_TARGET_ASSEMBLY=/opt/valheim/BepInEx/core/BepInEx.Preloader.dll
export LD_LIBRARY_PATH="/opt/valheim/linux64:/opt/valheim/doorstop_libs:${LD_LIBRARY_PATH:-}"
export LD_PRELOAD="libdoorstop_x64.so${LD_PRELOAD:+:$LD_PRELOAD}"
export SteamAppId=892970
arguments=(-nographics -batchmode -name "$SERVER_NAME" -port "$SERVER_PORT"
    -world "$WORLD_NAME" -password "$SERVER_PASSWORD" -public "$PUBLIC_SERVER" -savedir "$DATA_DIR")
if [[ "$CROSSPLAY" == 1 ]]; then arguments+=(-crossplay); fi
exec ./valheim_server.x86_64 "${arguments[@]}" "$@"
