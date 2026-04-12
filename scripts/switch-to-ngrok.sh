#!/usr/bin/env bash
set -euo pipefail

HOME_DIR="${HOME:-/home/roger}"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME_DIR/.config}"
ENV_FILE="${N8N_STACK_ENV_FILE:-$CONFIG_HOME/n8n-stack/.env}"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

: "${NGROK_AUTHTOKEN:?Set NGROK_AUTHTOKEN in $ENV_FILE before switching to ngrok.}"

systemctl --user stop localtunnel.service || true
systemctl --user disable localtunnel.service || true
systemctl --user enable --now ngrok-tunnel.service

printf 'Switched public tunnel provider to ngrok.\n'
