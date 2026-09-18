# Valheim docker image with BepInEx

[![Valheim](https://img.shields.io/badge/Valheim-1.0.15-blue)](https://github.com/landoria-gaming/valheim-server-image/pkgs/container/valheim_server.x86_64)
[![BepInEx](https://img.shields.io/badge/BepInEx-5.4.2350-green)](https://github.com/landoria-gaming/valheim-server-image/pkgs/container/valheim_server.x86_64)

A Linux x86_64 image containing the Valheim dedicated server and
BepInExPack_Valheim, based on Debian 13 (Trixie), `debian:trixie-slim`.

## Host requirements

- An x86_64 CPU (Intel or AMD 64-bit). ARM is not supported by this image.
- Most Linux distributions, such as Debian, Ubuntu, Fedora, Arch Linux, and
  Alpine Linux, can run the image with Podman or Docker and a container-compatible
  kernel.
- For the Steam backend, allow the selected UDP port and the following port
  (default: 2456–2457), and forward them on your router or firewall when needed. Crossplay
  uses a relay and does not require router port forwarding.

See [Podman installation instructions](https://podman.io/docs/installation) and
the [official Valheim dedicated server guide](https://www.valheimgame.com/support/a-guide-to-dedicated-servers/).

## Start the server with podman

Podman is an open-source alternative to Docker.

Install [Podman](https://podman.io/docs/installation) on a Debian host:

```bash
sudo apt update
sudo apt install -y podman
```

Create the persistent directories and give the container's `valheim` user
ownership so the server can write its files. Run these commands in Bash:

```bash
sudo mkdir -p /mnt/data/valheim/{savedir,BepInEx}
sudo chown -R 1000:1000 /mnt/data/valheim/{savedir,BepInEx}

```

Start the server:

```bash
sudo podman run \
  --name valheim \
  --restart always \
  --stop-timeout 60 \
  -p 2456-2457:2456-2457/udp \
  -v /mnt/data/valheim/savedir:/savedir \
  -v /mnt/data/valheim/BepInEx:/BepInEx \
  ghcr.io/landoria-gaming/valheim_server.x86_64 \
  -nographics -batchmode \
  -name "My Valheim Server" \
  -password "secret" \
  -world "MyWorld" \
  -port 2456 -public 1 -crossplay
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
open. To stop the server gracefully, run `sudo podman stop --time 60 valheim`
from another terminal.

To view logs separately, use `sudo podman logs -f valheim`. In this log view,
`Ctrl+C` stops following logs without stopping the server.

## Configuration

See the official [Valheim dedicated server guide](https://www.valheimgame.com/support/a-guide-to-dedicated-servers/)
for server arguments and configuration. Pass server arguments after the image name.

## Logs, shutdown, and updates

```bash
sudo podman logs -f valheim
sudo podman stop --time 60 valheim
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
sudo podman stop --time 60 valheim
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
