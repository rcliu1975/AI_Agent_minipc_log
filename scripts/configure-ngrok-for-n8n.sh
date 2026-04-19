#!/usr/bin/env bash
set -euo pipefail

HOME_DIR="${HOME:-/home/roger}"
RUNTIME_ENV="$HOME_DIR/n8n-stack/.env"
NGROK_CONFIG="$HOME_DIR/.config/ngrok/ngrok.yml"
REMOVE_LOCALTUNNEL=0
TOKEN_ARG=""

usage() {
  cat <<'EOF'
Usage:
  configure-ngrok-for-n8n.sh [--token TOKEN] [--token-file FILE] [--remove-localtunnel]

What it does:
  1. Writes NGROK_AUTHTOKEN into ~/n8n-stack/.env
  2. Stops and disables localtunnel.service
  3. Enables and starts ngrok-tunnel.service
  4. Prints the current public webhook URL and service states

Token sources, in precedence order:
  --token TOKEN
  --token-file FILE
  $NGROK_AUTHTOKEN
  ~/.config/ngrok/ngrok.yml

Options:
  --remove-localtunnel  Also remove ~/.local/share/localtunnel-app after switching
EOF
}

read_token_from_file() {
  local file_path="$1"
  tr -d '\r\n' < "$file_path"
}

read_token_from_ngrok_config() {
  local config_file="$1"
  awk '/authtoken:/{print $2; exit}' "$config_file"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --token)
      [[ $# -ge 2 ]] || { echo "--token requires a value" >&2; exit 1; }
      TOKEN_ARG="$2"
      shift 2
      ;;
    --token-file)
      [[ $# -ge 2 ]] || { echo "--token-file requires a path" >&2; exit 1; }
      TOKEN_ARG="$(read_token_from_file "$2")"
      shift 2
      ;;
    --remove-localtunnel)
      REMOVE_LOCALTUNNEL=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

TOKEN="${TOKEN_ARG:-${NGROK_AUTHTOKEN:-}}"
if [[ -z "$TOKEN" && -f "$NGROK_CONFIG" ]]; then
  TOKEN="$(read_token_from_ngrok_config "$NGROK_CONFIG")"
fi

if [[ -z "$TOKEN" ]]; then
  echo "Unable to find NGROK_AUTHTOKEN. Use --token, --token-file, NGROK_AUTHTOKEN, or ~/.config/ngrok/ngrok.yml." >&2
  exit 1
fi

if [[ ! -f "$RUNTIME_ENV" ]]; then
  echo "Missing runtime env file: $RUNTIME_ENV" >&2
  echo "Run scripts/deploy-n8n-runtime.sh first." >&2
  exit 1
fi

if grep -q '^NGROK_AUTHTOKEN=' "$RUNTIME_ENV"; then
  sed -i "s/^NGROK_AUTHTOKEN=.*/NGROK_AUTHTOKEN=$TOKEN/" "$RUNTIME_ENV"
else
  printf '\nNGROK_AUTHTOKEN=%s\n' "$TOKEN" >> "$RUNTIME_ENV"
fi
chmod 600 "$RUNTIME_ENV"

systemctl --user stop localtunnel.service || true
systemctl --user disable localtunnel.service || true
systemctl --user enable --now ngrok-tunnel.service
systemctl --user restart ngrok-webhook.path

if [[ "$REMOVE_LOCALTUNNEL" -eq 1 ]]; then
  rm -rf "$HOME_DIR/.local/share/localtunnel-app"
fi

sleep 2

if [[ -s "$HOME_DIR/.n8n/current_webhook_url" ]]; then
  printf 'current_webhook_url=%s\n' "$(tr -d '\r\n' < "$HOME_DIR/.n8n/current_webhook_url")"
fi

printf 'ngrok-tunnel.service=%s\n' "$(systemctl --user is-active ngrok-tunnel.service || true)"
printf 'localtunnel.service=%s\n' "$(systemctl --user is-active localtunnel.service || true)"
