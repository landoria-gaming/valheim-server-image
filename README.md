# Valheim server image

This repository builds and publishes the OCI image used by `valheim-server-platform`. It owns the container filesystem, SteamCMD installation, Valheim dedicated server installation, BepInEx bootstrap, and the container entrypoint.

Two image variants are built from the same source revision:

- `current` installs the default Valheim Steam branch;
- `public-test` installs the `public-test` Steam branch with its required beta password.

## Build locally

```sh
./build-image.sh
```

Use Docker instead of Podman when required:

```sh
CONTAINER_ENGINE=docker ./build-image.sh
```

Override the local image name with `VALHEIM_IMAGE`.
Set `VALHEIM_CHANNEL` to `current` or `public-test`; it defaults to `current`.

## Published image

GitHub Actions builds the image on the `dev` self-hosted runner with rootless Podman and publishes
it to GHCR with immutable release and commit tags:

```text
ghcr.io/landoria-gaming/valheim-server-image:v1.0.0-current
ghcr.io/landoria-gaming/valheim-server-image:v1.0.0-public-test
ghcr.io/landoria-gaming/valheim-server-image:sha-COMMIT-current
ghcr.io/landoria-gaming/valheim-server-image:sha-COMMIT-public-test
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

Required environment variables are `SERVER_NAME`, `WORLD_NAME`, `SERVER_PASSWORD`, `SERVER_PORT`, and `INSTANCE_ID`. `SERVER_PASSWORD` may be empty for passwordless servers; a non-empty value must contain at least five characters. Optional variables are `VALHEIM_INSTANCE_ID`, `PUBLIC_SERVER`, `CROSSPLAY`, `WORLD_PRESET`, `WORLD_KEYS`, `WORLD_MODIFIERS`, and `LANDORIA_MOD_ARGUMENTS`. `WORLD_KEYS` is a comma-separated list such as `allpiecesunlocked,nocraftcost`. `WORLD_MODIFIERS` is a comma-separated list of `name=value` pairs such as `combat=hard,raids=none`. `LANDORIA_MOD_ARGUMENTS` contains validated, whitespace-separated command-line arguments for Landoria mods; each value is passed to Valheim as a distinct argument without shell evaluation.

The entrypoint prefixes the public community-list name with `Landoria `. The operation is idempotent, so an existing `Landoria ` prefix is not duplicated; `WORLD_NAME` remains unchanged.
