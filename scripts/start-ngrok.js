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
