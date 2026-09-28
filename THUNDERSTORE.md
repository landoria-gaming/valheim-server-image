# Thunderstore package installer

This script downloads and extracts the latest version of a Thunderstore package.
It removes older versions of the same package from the destination directory.

Install the required tools on Debian:

```bash
sudo apt-get install -y curl jq unzip
```

Create the command:

```bash
sudo nano /usr/local/bin/download-thunderstore-package
```

Paste the following content, then save with `Ctrl+O`, `Enter`, and exit with
`Ctrl+X`:

```bash
#!/usr/bin/env bash
# Downloads and extracts the latest version of a Thunderstore package.

set -euo pipefail

readonly PACKAGE_REF="${1:-}"
readonly PARENT_DIR="${2:-}"

# Prints usage information and exits.
usage() {
  echo "Usage: $0 <namespace/package> <parent-directory>" >&2
  exit 2
}

# Checks that a required command is available.
require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Error: required command not found: $1" >&2
    exit 1
  fi
}

if (( $# != 2 )) || [[ ! "$PACKAGE_REF" =~ ^[A-Za-z0-9_-]+/[A-Za-z0-9_-]+$ || -z "$PARENT_DIR" ]]; then
  usage
fi

require_command curl
require_command jq
require_command unzip

readonly NAMESPACE="${PACKAGE_REF%%/*}"
readonly PACKAGE_NAME="${PACKAGE_REF##*/}"
readonly API_URL="https://thunderstore.io/api/experimental/package/$NAMESPACE/$PACKAGE_NAME/"

package_json="$(curl -fsSL "$API_URL")"
version="$(jq -er '.latest.version_number' <<<"$package_json")"
archive_name="$(jq -er '.latest.full_name' <<<"$package_json")"
download_url="$(jq -er '.latest.download_url' <<<"$package_json")"
destination="${PARENT_DIR%/}/$archive_name"
archive="$(mktemp --suffix=.zip)"
trap 'rm -f "$archive"' EXIT

curl -fL "$download_url" -o "$archive"
unzip -tq "$archive" >/dev/null
mkdir -p "$PARENT_DIR"
find "$PARENT_DIR" -mindepth 1 -maxdepth 1 -type d \
  -name "$NAMESPACE-$PACKAGE_NAME-*" -print -exec rm -rf -- {} +
mkdir -p "$destination"
unzip -oq "$archive" -d "$destination"

echo "Installed $NAMESPACE/$PACKAGE_NAME $version in $destination"
```

Make the command executable:

```bash
sudo chmod 755 /usr/local/bin/download-thunderstore-package
```

## Install a Thunderstore mod

This example installs these two mods:

- [Landoria CharacterVault](https://thunderstore.io/c/valheim/p/Landoria/CharacterVault/)
- [Landoria ModSentry](https://thunderstore.io/c/valheim/p/Landoria/ModSentry/)

Run the command once for each mod:

```bash
sudo download-thunderstore-package \
  Landoria/CharacterVault \
  /mnt/data/valheim/BepInEx/plugins

sudo download-thunderstore-package \
  Landoria/ModSentry \
  /mnt/data/valheim/BepInEx/plugins
```

Each mod is extracted to a versioned directory:

```text
/mnt/data/valheim/BepInEx/plugins/Landoria-CharacterVault-<version>
/mnt/data/valheim/BepInEx/plugins/Landoria-ModSentry-<version>
```
