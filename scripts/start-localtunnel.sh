#!/usr/bin/env bash
set -euo pipefail

HOME_DIR="${HOME:-/home/roger}"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME_DIR/.config}"
ENV_FILE="${N8N_STACK_ENV_FILE:-$CONFIG_HOME/n8n-stack/.env}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [[ -s "$HOME_DIR/.nvm/nvm.sh" ]]; then
  # shellcheck disable=SC1091
  source "$HOME_DIR/.nvm/nvm.sh"
  nvm use --silent default >/dev/null 2>&1 || true
fi

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

exec node "$SCRIPT_DIR/start-localtunnel.js"
