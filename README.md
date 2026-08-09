# Valheim server image

This repository builds and publishes the OCI image used by `valheim-server-platform`. It owns the container filesystem, SteamCMD installation, Valheim dedicated server installation, BepInEx bootstrap, and the container entrypoint.

## Build locally

```sh
./build-image.sh
```

Use Docker instead of Podman when required:

```sh
CONTAINER_ENGINE=docker ./build-image.sh
```

Override the local image name with `VALHEIM_IMAGE`.

## Published image

GitHub Actions builds the image on the `dev` self-hosted runner with rootless Podman and publishes
it to GHCR with immutable release and commit tags:

```text
ghcr.io/end3rbyte/valheim-server-image:v1.0.0
ghcr.io/end3rbyte/valheim-server-image:sha-COMMIT
```

The runner must have the `dev` and `valheim-image` labels and provide Podman in its service
`PATH`. A push to `main`, a `v*` tag, or a manual workflow dispatch starts the pipeline. The
default branch also publishes `latest`; a release tag publishes the matching version tag.

The platform repository consumes the published image and is responsible for Podman, Quadlet units, persistent instances, ports, backups, and lifecycle operations.

## Runtime contract

The image runs as UID 1000, requires `SERVER_PORT`, handles `SIGINT`, and uses these persistent mounts. The orchestrator must publish `SERVER_PORT` and `SERVER_PORT + 1` unchanged so Valheim advertises the correct public game and Steam query ports.

- `/data` for Valheim world and server data;
- `/mods/plugins` for BepInEx plugins;
- `/mods/config` for BepInEx and plugin configuration.

Required environment variables are `SERVER_NAME`, `WORLD_NAME`, `SERVER_PASSWORD`, `SERVER_PORT`, and `INSTANCE_ID`. `SERVER_PASSWORD` may be empty for passwordless servers; a non-empty value must contain at least five characters. Optional variables are `VALHEIM_INSTANCE_ID`, `PUBLIC_SERVER`, `CROSSPLAY`, `WORLD_PRESET`, `WORLD_KEY`, `WORLD_MODIFIER`, `WORLD_MODIFIER_VALUE`, and `LANDORIA_AFK_TIMEOUT_MINUTES`. The AFK timeout defaults to 30 minutes and is passed to Valheim as `--afktimeout`.
