#!/bin/sh
set -eu
# Render the numeric chat ID before Grafana parses provisioning. Grafana 12.2
# coerces numeric environment substitutions into numbers, but Telegram needs a string.
case "${TELEGRAM_CHAT_ID:-0}" in
  ''|*[!0-9-]*) echo 'TELEGRAM_CHAT_ID must be a numeric chat ID' >&2; exit 1 ;;
esac
mkdir -p /tmp/grafana-provisioning
cp -R /etc/grafana/provisioning/. /tmp/grafana-provisioning/
sed "s/__TELEGRAM_CHAT_ID__/${TELEGRAM_CHAT_ID:-0}/g" \
  /etc/grafana/provisioning/alerting/telegram.yml \
  > /tmp/grafana-provisioning/alerting/telegram.yml
export GF_PATHS_PROVISIONING=/tmp/grafana-provisioning
exec /run.sh
