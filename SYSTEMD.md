# Install as a systemd service

The service starts at boot. During a stop, Valheim saves the world and exits
through its native `server_exit.drp` mechanism.

Create `/etc/systemd/system/valheim-server.service`:

```bash
sudo nano /etc/systemd/system/valheim-server.service
```

Paste this content:

```ini
[Unit]
Description=Valheim dedicated server
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
ExecStartPre=podman pull ghcr.io/landoria-gaming/valheim_server.x86_64:latest
ExecStartPre=-podman rm --ignore valheim
ExecStart=podman run --rm --name valheim \
  -p 2456-2457:2456-2457/udp \
  -v /mnt/data/valheim/savedir:/savedir \
  -v /mnt/data/valheim/BepInEx:/BepInEx \
  ghcr.io/landoria-gaming/valheim_server.x86_64:latest -nographics -batchmode \
  -name "My Valheim Server" -password secret \
  -world MyWorld -port 2456 -public 1 -crossplay -preset normal
ExecStop=podman exec valheim touch /opt/valheim/server_exit.drp
ExecStop=podman wait valheim
Restart=on-failure
RestartSec=10
TimeoutStopSec=120
KillMode=none

[Install]
WantedBy=multi-user.target
```

Start the service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now valheim-server.service
```

Manage the service with these commands:

```bash
sudo systemctl start valheim-server.service
sudo systemctl stop valheim-server.service
sudo systemctl restart valheim-server.service
sudo systemctl status valheim-server.service
sudo journalctl -u valheim-server.service -f
```

Uninstall the service:

```bash
sudo systemctl disable --now valheim-server.service
sudo rm -f /etc/systemd/system/valheim-server.service
sudo systemctl daemon-reload
```

This keeps the server data under `/mnt/data/valheim`.
