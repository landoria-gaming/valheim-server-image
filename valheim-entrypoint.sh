#!/usr/bin/env bash
# Start Valheim with BepInEx and persistent world and mod directories.
set -euo pipefail
mkdir -p /savedir
[[ -w /savedir ]] || { echo '/savedir is not writable.' >&2; exit 1; }
mkdir -p /BepInEx/{core,plugins,config}
cp -an /opt/bepinex-default/. /BepInEx/
cp -a /opt/bepinex-default/core/. /BepInEx/core/
export DOORSTOP_ENABLED=1
export DOORSTOP_TARGET_ASSEMBLY=/opt/valheim/BepInEx/core/BepInEx.Preloader.dll
export LD_LIBRARY_PATH="/opt/valheim/linux64:/opt/valheim/doorstop_libs:${LD_LIBRARY_PATH:-}"
export LD_PRELOAD="libdoorstop_x64.so${LD_PRELOAD:+:$LD_PRELOAD}"
export SteamAppId=892970
exec ./valheim_server.x86_64 "$@"
