# Valheim docker image with BepInEx

[![Valheim](https://img.shields.io/badge/Valheim-1.0.14-blue)](https://github.com/landoria-gaming/valheim-server-image/pkgs/container/valheim_server.x86_64)
[![BepInEx](https://img.shields.io/badge/BepInEx-5.4.2350-green)](https://github.com/landoria-gaming/valheim-server-image/pkgs/container/valheim_server.x86_64)

A Linux x86_64 image containing the Valheim dedicated server and
BepInExPack_Valheim, based on Debian 13 (Trixie), `debian:trixie-slim`.

## Start the server with podman

Podman is an open-source alternative to Docker.

Install [Podman](https://podman.io/docs/installation) on a Debian host:

```bash
sudo apt update
sudo apt install -y podman
```

Run the following commands in Bash:

```bash
sudo mkdir -p /mnt/data/valheim/{savedir,BepInEx}
sudo chown 1000:1000 /mnt/data/valheim/{savedir,BepInEx}

sudo podman run \
  --name valheim \
  --restart always \
  --stop-timeout 90 \
  -p 2456-2457:2456-2457/udp \
  -v /mnt/data/valheim/savedir:/savedir \
  -v /mnt/data/valheim/BepInEx:/BepInEx \
  ghcr.io/landoria-gaming/valheim_server.x86_64 \
  -nographics -batchmode \
  -name "My Valheim Server" \
  -password "secret" \
  -world "MyWorld" \
  -port 2456 -public 1 -crossplay -savedir /savedir
```

All persistent files are grouped under `/mnt/data/valheim` on the host:

```text
/mnt/data/valheim/
|-- savedir/
`-- BepInEx/
    |-- core/
    |-- plugins/
    `-- config/
```

These directories are bind-mounted into the container and survive its replacement.
If migrating an existing server, stop it and copy its worlds, plugins, and
configuration into these directories before recreating the container.

Enable container startup after a host reboot:

```bash
sudo systemctl enable podman-restart.service
```

The `always` policy restarts the container after an unexpected exit. The service
starts it after a host reboot, even if it was stopped manually before reboot.
See [Podman restart policies](https://docs.podman.io/en/v4.4/markdown/podman-run.1.html#restart-policy).

The command runs in the foreground and displays server logs. Keep the terminal
open. To stop the server gracefully, run `sudo podman stop --time 90 valheim`
from another terminal.

To view logs separately, use `sudo podman logs -f valheim`. In this log view,
`Ctrl+C` stops following logs without stopping the server.

## Configuration

See the official [Valheim dedicated server guide](https://www.valheimgame.com/support/a-guide-to-dedicated-servers/)
for server arguments and configuration. Pass server arguments after the image name.

## Persistent files and mods

| Host path | Container path | Contents |
| --- | --- | --- |
| `/mnt/data/valheim/savedir` | `/savedir` | Worlds and server data |
| `/mnt/data/valheim/BepInEx/plugins` | `/BepInEx/plugins` | BepInEx plugins and their dependencies |
| `/mnt/data/valheim/BepInEx/config` | `/BepInEx/config` | BepInEx and plugin configuration |

BepInEx files are initialized on startup without replacing existing plugins or
configuration. Bundled core files are refreshed from the image on each startup.
BepInEx is enabled automatically.

To choose another data directory on the host, replace `/mnt/data/valheim` in the start
command. Both mounted directories must be writable by UID 1000.

The start command stores worlds in `/savedir` with `-savedir /savedir`. Changing the host directory does
not move existing worlds. Copy the existing data into the new host directory
before recreating the container.

### Install mods

Download and extract the mod archive, then install the dependencies listed by
its author. BepInEx is already included in the image; do not replace its core
files with those from a mod archive.

For an archive containing `BepInEx/plugins`, copy its contents into the persistent
plugins directory:

```bash
sudo podman cp ./BepInEx/plugins/. valheim:/BepInEx/plugins/
sudo podman restart valheim
sudo podman logs -f valheim
```

Adapt the source path to the extracted archive. Preserve plugin subdirectories
and supporting files. For a single plugin DLL:

```bash
sudo podman cp ./MyPlugin.dll valheim:/BepInEx/plugins/MyPlugin.dll
sudo podman restart valheim
```

Files copied to `/BepInEx/plugins` persist in `/mnt/data/valheim/BepInEx/plugins` on the host. Check
the startup logs for the plugin name and any missing dependency or loading errors.
Plugins usually generate their configuration under `/BepInEx/config` after startup.

To edit a generated configuration, copy it out, edit it locally, then stop the
server and copy it back before starting it again:

```bash
sudo podman cp valheim:/BepInEx/config/MyPlugin.cfg ./MyPlugin.cfg
# Edit MyPlugin.cfg with your text editor.
sudo podman stop --time 90 valheim
sudo podman cp ./MyPlugin.cfg valheim:/BepInEx/config/MyPlugin.cfg
sudo podman start valheim
```

Replace `MyPlugin.cfg` with the actual configuration filename. Files copied from
the host must remain readable by UID 1000; configuration files must also be
writable by UID 1000 if the plugin updates them. Back up worlds before adding or
updating mods. Follow each mod's instructions for compatibility and client-side
installation requirements.

Install any client-side mods required by your chosen plugins on each player's
game as well.

## Logs, shutdown, and updates

```bash
sudo podman logs -f valheim
sudo podman stop --time 90 valheim
sudo podman start valheim
```

Stopping sends `SIGINT` so the server can save and exit.

### Update the image without losing data

The start command above stores worlds, plugins, and configuration under
`/mnt/data/valheim` on the host. These files are retained when the container is removed.

1. Keep your current start command, including the startup
   arguments, port mappings, and bind mount paths.
2. Pull the new image while the existing server is still running:

```bash
sudo podman pull ghcr.io/landoria-gaming/valheim_server.x86_64
```

3. Stop the server gracefully so it finishes saving before the backup:

```bash
sudo podman stop --time 90 valheim
```

4. Back up both directories while the server is stopped. Run this Bash
   command from the directory where you want to store the backup:

```bash
backup_file="$PWD/valheim-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
sudo tar -czf "$backup_file" -C /mnt/data/valheim savedir BepInEx
```

Use your actual host directory if it differs. Keep the same mount destinations
when recreating the container.

5. Remove only the old container:

```bash
sudo podman rm valheim
```

6. Repeat the full start command from **Start the server with podman**, using the same host
   directories and your saved configuration. Podman uses the newly pulled image.
7. Check `sudo podman logs -f valheim` for startup and mod errors, then verify that
   the expected world loads before allowing players to reconnect.

Do not delete or change the host directories when recreating the container.

The container does not update its own server files. Recreate it to use a newly
published image or change ports or startup arguments.

## Image tags and versions

The image is published as `ghcr.io/landoria-gaming/valheim_server.x86_64`.
When no tag is specified, Podman uses `latest`.

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
sudo podman image inspect ghcr.io/landoria-gaming/valheim_server.x86_64 \
  --format '{{json .Config.Labels}}'
```

## Build and publication

The **Build and publish Valheim server image** workflow runs daily on GitHub-hosted runners.
It checks Steam and Thunderstore, reuses current download caches, and downloads
changed versions. It then builds the server image, tests Valheim and BepInEx
startup, and publishes to GHCR. Publication is skipped when the existing image
matches the Steam Build ID and image source fingerprint.

For a fresh download, manually run the workflow with `discard-cache` enabled
(default: `false`). It deletes SteamCMD, TCLI, BepInEx, and the selected Valheim
channel's caches before rebuilding them. It does not force image publication
when the published image already matches.

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
