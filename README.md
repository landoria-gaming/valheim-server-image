# Valheim dedicated server with BepInEx

[![Valheim](https://img.shields.io/badge/Valheim-1.0.14-blue)](https://github.com/landoria-gaming/valheim-server-image/pkgs/container/valheim-server-image)
[![BepInEx](https://img.shields.io/badge/BepInEx-5.4.2350-green)](https://github.com/landoria-gaming/valheim-server-image/pkgs/container/valheim-server-image)

A Linux AMD64 image containing the Valheim dedicated server and
BepInExPack_Valheim, based on Debian 13 (Trixie), `debian:trixie-slim`.

## Start the server

Install Docker and run this command in Bash:

```bash
docker run -d \
  --name valheim \
  --restart unless-stopped \
  --stop-timeout 90 \
  -e SERVER_NAME="My Valheim Server" \
  -e SERVER_PASSWORD="change-this-password" \
  -e WORLD_NAME="MyWorld" \
  -e SERVER_PORT=2456 \
  -e PUBLIC_SERVER=1 \
  -e CROSSPLAY=1 \
  -p 2456-2457:2456-2457/udp \
  -v valheim-data:/data \
  -v valheim-plugins:/mods/plugins \
  -v valheim-config:/mods/config \
  ghcr.io/landoria-gaming/valheim-server-image:latest
```

Docker creates the three named volumes on first use. They survive container
replacement. If the package requires authentication, run `docker login ghcr.io`
with an account and token that can read the package before pulling it.

## Configuration

Set these environment variables when creating the container:

| Variable | Default | Purpose |
| --- | --- | --- |
| `SERVER_NAME` | `Valheim Server` | Server name, including spaces |
| `SERVER_PASSWORD` | Required | At least five characters; must not appear in the server name |
| `WORLD_NAME` | `Dedicated` | World to load or create |
| `SERVER_PORT` | `2456` | First UDP port, from 1024 to 65534 |
| `PUBLIC_SERVER` | `1` | `1` lists the server publicly; `0` hides it |
| `CROSSPLAY` | `1` | `1` enables crossplay; `0` disables it |
| `DATA_DIR` | `/data` | Absolute path inside the container for worlds and server data |

Only set one server port. Valheim also uses the following port automatically.
Publish both UDP ports with matching host and container numbers, and allow them
through your firewall or router when needed. For example, replace the port lines
above with:

```bash
-e SERVER_PORT=2460 \
-p 2460-2461:2460-2461/udp
```

Arguments after the image name are appended to the Valheim command. For example,
append `-preset hard` to the full `docker run` command:

```bash
ghcr.io/landoria-gaming/valheim-server-image:latest -preset hard
```

## Persistent files and mods

| Container path | Contents |
| --- | --- |
| `${DATA_DIR}` (default `/data`) | Worlds and server data |
| `/mods/plugins` | BepInEx plugins and their dependencies |
| `/mods/config` | BepInEx and plugin configuration |

The default BepInEx configuration is copied on startup without replacing existing
configuration files. BepInEx is enabled automatically.

To choose a data directory on the host, replace `-v valheim-data:/data` with
`-v /srv/valheim-data:/data` in the start command. The host directory must be
writable by UID 1000.

To also change the path inside the container, set `DATA_DIR` and mount your data
at that same path. For example, replace the data volume line with:

```bash
-e DATA_DIR=/srv/worlds \
-v /srv/valheim-data:/srv/worlds
```

Changing the path does not move existing worlds. Copy the existing data into the
new host directory before recreating the container.

### Install mods

Download and extract the mod archive, then install the dependencies listed by
its author. BepInEx is already included in the image; do not replace its core
files with those from a mod archive.

For an archive containing `BepInEx/plugins`, copy its contents into the persistent
plugins directory:

```bash
docker cp ./BepInEx/plugins/. valheim:/mods/plugins/
docker restart valheim
docker logs -f valheim
```

Adapt the source path to the extracted archive. Preserve plugin subdirectories
and supporting files. For a single plugin DLL:

```bash
docker cp ./MyPlugin.dll valheim:/mods/plugins/MyPlugin.dll
docker restart valheim
```

Files copied to `/mods/plugins` persist in the `valheim-plugins` volume. Check
the startup logs for the plugin name and any missing dependency or loading errors.
Plugins usually generate their configuration under `/mods/config` after startup.

To edit a generated configuration, copy it out, edit it locally, then stop the
server and copy it back before starting it again:

```bash
docker cp valheim:/mods/config/MyPlugin.cfg ./MyPlugin.cfg
# Edit MyPlugin.cfg with your text editor.
docker stop --time 90 valheim
docker cp ./MyPlugin.cfg valheim:/mods/config/MyPlugin.cfg
docker start valheim
```

Replace `MyPlugin.cfg` with the actual configuration filename. Files copied from
the host must remain readable by UID 1000; configuration files must also be
writable by UID 1000 if the plugin updates them. Back up worlds before adding or
updating mods. Follow each mod's instructions for compatibility and client-side
installation requirements.

For bind mounts instead of named volumes, the mounted directories must be
writable by UID 1000. Install any client-side mods required by your chosen plugins
on each player's game as well.

## Logs, shutdown, and updates

```bash
docker logs -f valheim
docker stop --time 90 valheim
docker start valheim
```

Stopping sends `SIGINT` so the server can save and exit.

### Update the image without losing data

The start command above uses named volumes for worlds (`valheim-data`), plugins
(`valheim-plugins`), and configuration (`valheim-config`). These files are stored
outside the container and are retained when the container is removed.

1. Keep your current start command, including the environment variables, startup
   arguments, port mappings, and volume names or bind mount paths.
2. Pull the new image while the existing server is still running:

```bash
docker pull ghcr.io/landoria-gaming/valheim-server-image:latest
```

3. Stop the server gracefully so it finishes saving before the backup:

```bash
docker stop --time 90 valheim
```

4. Back up all three named volumes. Run this Bash command from the directory
   where you want to store the backups:

```bash
backup_dir="$PWD/valheim-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$backup_dir"
for volume in valheim-data valheim-plugins valheim-config; do
  docker run --rm \
    --mount "type=volume,source=$volume,target=/source,readonly" \
    --mount "type=bind,source=$backup_dir,target=/backup" \
    debian:trixie-slim \
    tar -czf "/backup/$volume.tar.gz" -C /source .
done
```

Use your actual volume names if they differ. For bind mounts, back up the host
directories instead while the server is stopped. If you changed `DATA_DIR`, keep
the same value and mount destination when recreating the container.

5. Remove only the old container:

```bash
docker rm valheim
```

6. Repeat the full start command from **Start the server**, using the same three
   volumes and your saved configuration. Docker uses the newly pulled image.
7. Check `docker logs -f valheim` for startup and mod errors, then verify that
   the expected world loads before allowing players to reconnect.

Do not delete the volumes, change their names, or run `docker compose down -v`.
If you use Compose, keep the same project name and volume definitions, then run
`docker compose pull` and `docker compose up -d`. Configure `stop_grace_period: 90s`
in your Compose service so replacement allows a graceful shutdown. Stop and back
up the server's persistent volumes before replacement as described above.

The container does not update its own server files. Recreate it to use a newly
published image or change environment variables, ports, or startup arguments.

## Image tags and versions

| Tag | Purpose |
| --- | --- |
| `latest`, `current` | Latest published stable server image |
| `1.0.14` | Published image for this Valheim version |
| `valheim-server-1.0.14-bepinex-5.4.2350` | Image with these Valheim and BepInEx versions |
| `public-test` | Latest published public-test image |

Version numbers in the examples change with releases. Tags can be updated;
use an image digest when you need an exact immutable reference. Old versions may
be removed by the separate **Clean up GHCR images** workflow. It runs manually
and keeps only the package version created most recently, including across
channels.

Inspect the Valheim version, Steam Build ID, BepInEx version, and base image
description:

```bash
docker image inspect ghcr.io/landoria-gaming/valheim-server-image:latest \
  --format '{{json .Config.Labels}}'
```

## Build and publication

The **Build and publish Valheim server image** workflow runs daily on GitHub-hosted runners.
It checks Steam and Thunderstore, reuses current download caches, and downloads
changed versions. It then builds the server image, tests Valheim and BepInEx
startup, and publishes to GHCR. Publication is skipped when the existing image
matches the Steam Build ID and image source fingerprint.

Workflow Bash operations run directly in their job steps. Only the container
startup script, `valheim-entrypoint.sh`, is kept as a separate Bash file.

The main workflow calls separate reusable workflows for SteamCMD, TCLI,
Valheim, BepInEx, and image publication. SteamCMD prepares its versioned cache
before Valheim starts; TCLI prepares its cache before BepInEx starts. Each
consumer restores the exact tool cache returned by its prerequisite. System
libraries are still installed on each fresh GitHub runner. Image publication
waits for both content caches. The cleanup workflow remains manual and separate.

The badges show the stable image versions published on GHCR. After a successful
stable image job on `main`, the workflow updates only their version numbers in
this README using the repository token (`contents: write`). Unchanged versions
skip the update. This works for private repositories because Shields does not
need to read repository data. Branch protection must permit the workflow token
to update the README for automatic badge refresh.
