#!/usr/bin/env bash
set -euo pipefail

HOME_DIR="${HOME:-/home/roger}"
REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME_DIR="$HOME_DIR/n8n-stack"
SYSTEMD_DIR="$HOME_DIR/.config/systemd/user"
LEGACY_CONFIG_ENV="$HOME_DIR/.config/n8n-stack/.env"
RUNTIME_ENV="$RUNTIME_DIR/.env"

mkdir -p "$RUNTIME_DIR" "$SYSTEMD_DIR"

if [[ ! -f "$RUNTIME_ENV" && -f "$LEGACY_CONFIG_ENV" ]]; then
  install -m 600 "$LEGACY_CONFIG_ENV" "$RUNTIME_ENV"
fi

if [[ ! -f "$RUNTIME_ENV" ]]; then
  cat > "$RUNTIME_ENV" <<'EOF'
N8N_PORT=5678
N8N_PROTOCOL=http
N8N_HOST=localhost
N8N_LISTEN_ADDRESS=0.0.0.0
N8N_USER_FOLDER=/home/roger
GENERIC_TIMEZONE=Asia/Taipei
TZ=Asia/Taipei
N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true
N8N_PROXY_HOPS=1
N8N_SECURE_COOKIE=false
WEBHOOK_URL=
NGROK_AUTHTOKEN=
EOF
  chmod 600 "$RUNTIME_ENV"
fi

cat > "$RUNTIME_DIR/start-n8n.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

HOME_DIR="${HOME:-/home/roger}"
ENV_FILE="$HOME_DIR/n8n-stack/.env"
WEBHOOK_FILE="$HOME_DIR/.n8n/current_webhook_url"
N8N_BIN="$HOME_DIR/.local/share/n8n-app/node_modules/.bin/n8n"

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

export N8N_USER_FOLDER="${N8N_USER_FOLDER:-$HOME_DIR}"
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

exec "$N8N_BIN" start
EOF

cat > "$RUNTIME_DIR/start-localtunnel.js" <<'EOF'
const fs = require('fs');
const path = require('path');

const home = process.env.HOME || '/home/roger';
const localtunnel = require(path.join(
  home,
  '.local/share/localtunnel-app/node_modules/localtunnel',
));

const port = Number(process.env.N8N_PORT || 5678);
const urlFile = path.join(home, '.n8n', 'current_webhook_url');

let tunnel;

async function main() {
  tunnel = await localtunnel({
    port,
    local_host: '127.0.0.1',
  });

  fs.writeFileSync(urlFile, `${tunnel.url}\n`, 'utf8');
  console.log(`localtunnel forwarding ${tunnel.url} -> http://127.0.0.1:${port}`);

  tunnel.on('close', () => {
    console.error('localtunnel connection closed');
    process.exit(1);
  });
}

async function shutdown(signal) {
  console.log(`received ${signal}, closing localtunnel listener`);

  if (tunnel) {
    await tunnel.close();
  }

  process.exit(0);
}

process.on('SIGINT', () => {
  shutdown('SIGINT').catch((error) => {
    console.error(error);
    process.exit(1);
  });
});

process.on('SIGTERM', () => {
  shutdown('SIGTERM').catch((error) => {
    console.error(error);
    process.exit(1);
  });
});

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
EOF

cat > "$RUNTIME_DIR/start-localtunnel.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

HOME_DIR="${HOME:-/home/roger}"
ENV_FILE="$HOME_DIR/n8n-stack/.env"
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
EOF

cat > "$RUNTIME_DIR/start-ngrok.js" <<'EOF'
const fs = require('fs');
const path = require('path');

const home = process.env.HOME || '/home/roger';
const ngrok = require(path.join(
  home,
  '.local/share/ngrok-app/node_modules/@ngrok/ngrok',
));

const port = Number(process.env.N8N_PORT || 5678);
const urlFile = path.join(home, '.n8n', 'current_webhook_url');

let listener;

async function main() {
  listener = await ngrok.forward({
    addr: `127.0.0.1:${port}`,
    authtoken_from_env: true,
  });

  const publicUrl = listener.url();
  fs.writeFileSync(urlFile, `${publicUrl}\n`, 'utf8');
  console.log(`ngrok forwarding ${publicUrl} -> http://127.0.0.1:${port}`);

  setInterval(() => {}, 24 * 60 * 60 * 1000);
}

async function shutdown(signal) {
  console.log(`received ${signal}, closing ngrok listener`);

  if (listener) {
    await listener.close();
  }

  process.exit(0);
}

process.on('SIGINT', () => {
  shutdown('SIGINT').catch((error) => {
    console.error(error);
    process.exit(1);
  });
});

process.on('SIGTERM', () => {
  shutdown('SIGTERM').catch((error) => {
    console.error(error);
    process.exit(1);
  });
});

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
EOF

cat > "$RUNTIME_DIR/start-ngrok.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

HOME_DIR="${HOME:-/home/roger}"
ENV_FILE="$HOME_DIR/n8n-stack/.env"
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

: "${NGROK_AUTHTOKEN:?Set NGROK_AUTHTOKEN in $ENV_FILE before starting the ngrok tunnel service.}"

exec node "$SCRIPT_DIR/start-ngrok.js"
EOF

cat > "$RUNTIME_DIR/restart-n8n-on-webhook-change.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

HOME_DIR="${HOME:-/home/roger}"
CURRENT_FILE="$HOME_DIR/.n8n/current_webhook_url"
APPLIED_FILE="$HOME_DIR/.n8n/current_webhook_url.applied"

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
EOF

cat > "$RUNTIME_DIR/status.sh" <<'EOF'
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
EOF

cat > "$RUNTIME_DIR/switch-to-ngrok.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

HOME_DIR="${HOME:-/home/roger}"
ENV_FILE="$HOME_DIR/n8n-stack/.env"

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
EOF

chmod 600 "$RUNTIME_ENV"
chmod 755 \
  "$RUNTIME_DIR/start-n8n.sh" \
  "$RUNTIME_DIR/start-localtunnel.sh" \
  "$RUNTIME_DIR/start-ngrok.sh" \
  "$RUNTIME_DIR/restart-n8n-on-webhook-change.sh" \
  "$RUNTIME_DIR/status.sh" \
  "$RUNTIME_DIR/switch-to-ngrok.sh"

cat > "$SYSTEMD_DIR/n8n.service" <<'EOF'
[Unit]
Description=n8n automation server
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
Environment=HOME=/home/roger
WorkingDirectory=/home/roger/n8n-stack
ExecStart=/home/roger/n8n-stack/start-n8n.sh
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
EOF

cat > "$SYSTEMD_DIR/localtunnel.service" <<'EOF'
[Unit]
Description=localtunnel fallback public tunnel for n8n
After=network-online.target n8n.service
Wants=network-online.target n8n.service

[Service]
Type=simple
Environment=HOME=/home/roger
WorkingDirectory=/home/roger/n8n-stack
ExecStart=/home/roger/n8n-stack/start-localtunnel.sh
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
EOF

cat > "$SYSTEMD_DIR/ngrok-tunnel.service" <<'EOF'
[Unit]
Description=ngrok tunnel for n8n
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
Environment=HOME=/home/roger
WorkingDirectory=/home/roger/n8n-stack
ExecStart=/home/roger/n8n-stack/start-ngrok.sh
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
EOF

cat > "$SYSTEMD_DIR/ngrok-webhook.service" <<'EOF'
[Unit]
Description=Restart n8n when ngrok webhook URL changes

[Service]
Type=oneshot
Environment=HOME=/home/roger
ExecStart=/home/roger/n8n-stack/restart-n8n-on-webhook-change.sh
EOF

systemctl --user daemon-reload
systemctl --user restart n8n.service
systemctl --user restart localtunnel.service
systemctl --user restart ngrok-webhook.path

if [[ -f "$LEGACY_CONFIG_ENV" && -f "$RUNTIME_ENV" ]] && cmp -s "$LEGACY_CONFIG_ENV" "$RUNTIME_ENV"; then
  rm -f "$LEGACY_CONFIG_ENV"
  rmdir "$(dirname "$LEGACY_CONFIG_ENV")" 2>/dev/null || true
fi

printf 'Runtime deployed to %s\n' "$RUNTIME_DIR"
printf 'Runtime env file: %s\n' "$RUNTIME_ENV"
