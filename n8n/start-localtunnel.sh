#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="/home/roger/WorkSpace/n8n-stack/.env"

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

exec node "/home/roger/WorkSpace/n8n-stack/start-localtunnel.js"
