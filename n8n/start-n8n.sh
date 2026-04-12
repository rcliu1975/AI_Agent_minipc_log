#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="/home/roger/WorkSpace/n8n-stack/.env"
WEBHOOK_FILE="/home/roger/.n8n/current_webhook_url"

if [[ -s "/home/roger/.nvm/nvm.sh" ]]; then
  # shellcheck disable=SC1091
  source "/home/roger/.nvm/nvm.sh"
  nvm use --silent default >/dev/null 2>&1 || true
fi

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

export N8N_USER_FOLDER="${N8N_USER_FOLDER:-/home/roger}"
export N8N_PORT="${N8N_PORT:-5678}"
export N8N_PROTOCOL="${N8N_PROTOCOL:-http}"
export N8N_HOST="${N8N_HOST:-localhost}"
export N8N_LISTEN_ADDRESS="${N8N_LISTEN_ADDRESS:-0.0.0.0}"
export GENERIC_TIMEZONE="${GENERIC_TIMEZONE:-Asia/Taipei}"
export TZ="${TZ:-Asia/Taipei}"
export N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS="${N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS:-true}"
export N8N_PROXY_HOPS="${N8N_PROXY_HOPS:-1}"
export N8N_SECURE_COOKIE="${N8N_SECURE_COOKIE:-false}"

if [[ -z "${WEBHOOK_URL:-}" && -s "$WEBHOOK_FILE" ]]; then
  export WEBHOOK_URL="$(tr -d '\r\n' < "$WEBHOOK_FILE")"
fi

if [[ -z "${WEBHOOK_URL:-}" ]]; then
  unset WEBHOOK_URL || true
fi

exec "/home/roger/.local/share/n8n-app/node_modules/.bin/n8n" start
