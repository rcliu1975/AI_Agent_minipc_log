#!/usr/bin/env bash
set -euo pipefail

HOME_DIR="${HOME:-/home/roger}"
WEBHOOK_FILE="$HOME_DIR/.n8n/current_webhook_url"

printf 'n8n: '
systemctl --user is-active n8n.service || true

printf 'localtunnel: '
systemctl --user is-active localtunnel.service || true

printf 'ngrok-tunnel: '
systemctl --user is-active ngrok-tunnel.service || true

printf 'ngrok-webhook.path: '
systemctl --user is-active ngrok-webhook.path || true

if [[ -s "$WEBHOOK_FILE" ]]; then
  printf 'current_webhook_url: '
  cat "$WEBHOOK_FILE"
fi
