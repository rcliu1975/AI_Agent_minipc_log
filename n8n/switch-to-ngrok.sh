#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="/home/roger/WorkSpace/n8n-stack/.env"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

: "${NGROK_AUTHTOKEN:?Set NGROK_AUTHTOKEN in /home/roger/WorkSpace/n8n-stack/.env before switching to ngrok.}"

systemctl --user stop localtunnel.service || true
systemctl --user disable localtunnel.service || true
systemctl --user enable --now ngrok-tunnel.service

printf 'Switched public tunnel provider to ngrok.\n'
