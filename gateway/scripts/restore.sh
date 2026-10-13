#!/usr/bin/env bash
# Restores volumes from a backup created by backup.sh.
#   scripts/restore.sh backups/20261013-120000
# Existing volume contents are REPLACED. Stops the stack first.
set -euo pipefail
cd "$(dirname "$0")/.."

src=${1:?usage: scripts/restore.sh <backup-dir>}
project=smarthome
[ -d "$src" ] || { echo "No such backup: $src" >&2; exit 1; }

read -r -p "Replace current gateway data with $src? [y/N] " answer
[ "$answer" = "y" ] || { echo "Aborted."; exit 1; }

docker compose down
for archive in "$src"/*.tar.gz; do
  v=$(basename "$archive" .tar.gz)
  full="${project}_${v}"
  echo "Restoring $full"
  docker volume create "$full" >/dev/null
  docker run --rm -v "$full":/target -v "$PWD/$src":/backup:ro alpine \
    sh -c "find /target -mindepth 1 -delete && tar xzf /backup/$v.tar.gz -C /target"
done
echo "Restored. Start again with: docker compose [--profile …] up -d"
