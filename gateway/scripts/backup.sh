#!/usr/bin/env bash
# Backs up all gateway volumes into ./backups/<timestamp>/<volume>.tar.gz.
#
# Containers are stopped during the copy so databases (Home Assistant's
# SQLite recorder, Zigbee/Z-Wave network state) are consistent, then
# started again. The backup contains secrets (HA auth, network keys):
# store it encrypted and off the machine.
set -euo pipefail
cd "$(dirname "$0")/.."

project=smarthome
volumes=(homeassistant_config mosquitto_data zigbee2mqtt_data zwave_js_store matter_data otbr_data esphome_config)
target="backups/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$target"
chmod 700 backups "$target"

running=$(docker compose ps --services --status running)
echo "Stopping: ${running//$'\n'/ }"
docker compose stop

for v in "${volumes[@]}"; do
  full="${project}_${v}"
  if docker volume inspect "$full" >/dev/null 2>&1; then
    echo "Backing up $full"
    docker run --rm -v "$full":/source:ro -v "$PWD/$target":/backup alpine \
      tar czf "/backup/$v.tar.gz" -C /source .
  fi
done

if [ -n "$running" ]; then
  # shellcheck disable=SC2086
  docker compose start $running
fi
echo "Backup written to $target"
