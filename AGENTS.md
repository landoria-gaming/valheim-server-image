# Agent Instructions

1. Always write code, documentation, comments, commit messages, and agent instruction files in English.
2. This repository owns only the Valheim OCI image, its entrypoint, image tests, and publication workflow.
3. Keep the runtime contract documented: required environment variables, ports, volumes, generated files, signals, and shutdown behavior.
4. Publish immutable `v*` and `sha-*` tags. The `latest` tag is for convenience and must not be required by production deployments.
5. Never add host provisioning, Quadlet generation, instance lifecycle management, API code, MySQL synchronization, or Swiss Backup orchestration here.
