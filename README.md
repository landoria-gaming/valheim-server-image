# Valheim docker image with BepInEx

[![Valheim](https://img.shields.io/badge/Valheim-1.0.15-blue)](https://github.com/landoria-gaming/valheim-server-image/pkgs/container/valheim_server.x86_64)
[![BepInEx](https://img.shields.io/badge/BepInEx-5.4.2351-green)](https://github.com/landoria-gaming/valheim-server-image/pkgs/container/valheim_server.x86_64)
[![Image build date](https://img.shields.io/badge/Image_build_date-24%2F09%2F2026-orange)](https://github.com/landoria-gaming/valheim-server-image/pkgs/container/valheim_server.x86_64)

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

## Start the server with podman

Podman is an open-source alternative to Docker.

Install [Podman](https://podman.io/docs/installation) on a Linux host such as Debian or Ubuntu, run:

```bash
sudo apt update && sudo apt install -y podman
# Increase the default stop timeout from 10 to 30 seconds for new containers.
sudo mkdir -p /etc/containers/containers.conf.d
printf '[engine]\nstop_timeout = 30\n' | sudo tee /etc/containers/containers.conf.d/99-stop-timeout.conf
```

The configuration sets a 30-second default stop timeout for new containers.

Create the persistent directories and give the container's `valheim` user
ownership so the server can write its files. Run these commands in Bash:

```bash
sudo mkdir -p /mnt/data/valheim/{savedir,BepInEx}
sudo chown -R 1000:1000 /mnt/data/valheim/{savedir,BepInEx}

```

Start the server:

```bash
# sudo podman pull ghcr.io/landoria-gaming/valheim_server.x86_64:latest
# sudo podman stop valheim && sudo podman rm valheim
sudo podman run \
  --name valheim \
  --restart always \
  -p 2456-2457:2456-2457/udp \
  -v /mnt/data/valheim/savedir:/savedir \
  -v /mnt/data/valheim/BepInEx:/BepInEx \
  ghcr.io/landoria-gaming/valheim_server.x86_64 \
  -nographics -batchmode \
  -name "My Valheim Server" \
  -password "secret" \
  -world "MyWorld" \
  -port 2456 -public 1 -crossplay -preset normal
```

For incoming connections, you usually need to allow UDP ports 2456–2457 through
your firewall and forward them on your router. With crossplay enabled, router
port forwarding is not required because Valheim uses a relay.

Press `Ctrl+C` in the terminal running the server to stop it gracefully.

All persistent files are grouped under `/mnt/data/valheim` on the host:

```text
/mnt/data/valheim/
|-- savedir/
`-- BepInEx/
    |-- core/
    |-- plugins/
    `-- config/
```

## Configuration

See the official [Valheim dedicated server guide](https://www.valheimgame.com/support/a-guide-to-dedicated-servers/)
for server arguments and configuration. Pass server arguments after the image name.

## Optional host configuration

Run these commands as root on Debian.

### Enable swap

Swap provides disk-backed memory when RAM is full.

```bash
apt-get update && apt-get install -y util-linux
fallocate -l 4G /swapfile # Set 4GB of swap
chmod 600 /swapfile
/usr/sbin/mkswap /swapfile
/usr/sbin/swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab
```

### Enable earlyoom

Earlyoom helps prevent host freezes by terminating processes when memory runs critically low; it may terminate Valheim.

```bash
apt-get update && apt-get install -y earlyoom
systemctl enable --now earlyoom
systemctl is-active earlyoom
```
