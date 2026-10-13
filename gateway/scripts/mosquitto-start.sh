#!/bin/sh
# Generates the Mosquitto password file from environment variables, then
# starts the broker. Runs inside the eclipse-mosquitto container.
set -eu

for var in MQTT_HA_USER MQTT_HA_PASSWORD MQTT_Z2M_USER MQTT_Z2M_PASSWORD; do
  eval "value=\${$var:-}"
  if [ -z "$value" ] || [ "$value" = "change-me" ]; then
    echo "mosquitto-start: $var is not set in .env (or still 'change-me')" >&2
    exit 1
  fi
done

passwd_file=/mosquitto/data/passwd
umask 077
: > "$passwd_file"
mosquitto_passwd -b "$passwd_file" "$MQTT_HA_USER" "$MQTT_HA_PASSWORD"
mosquitto_passwd -b "$passwd_file" "$MQTT_Z2M_USER" "$MQTT_Z2M_PASSWORD"
# The broker drops privileges to "mosquitto"; it must own its data.
chown -R mosquitto:mosquitto /mosquitto/data 2>/dev/null || true

exec /usr/sbin/mosquitto -c /mosquitto/config/mosquitto.conf
