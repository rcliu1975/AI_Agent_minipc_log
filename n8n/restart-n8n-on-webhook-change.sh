#!/usr/bin/env bash
set -euo pipefail

CURRENT_FILE="/home/roger/.n8n/current_webhook_url"
APPLIED_FILE="/home/roger/.n8n/current_webhook_url.applied"

if [[ ! -s "$CURRENT_FILE" ]]; then
  exit 0
fi

current_url="$(tr -d '\r\n' < "$CURRENT_FILE")"
applied_url=""

if [[ -s "$APPLIED_FILE" ]]; then
  applied_url="$(tr -d '\r\n' < "$APPLIED_FILE")"
fi

if [[ "$current_url" == "$applied_url" ]]; then
  exit 0
fi

printf '%s\n' "$current_url" > "$APPLIED_FILE"

if systemctl --user --quiet is-active n8n.service; then
  exec systemctl --user restart n8n.service
fi

exec systemctl --user start n8n.service
