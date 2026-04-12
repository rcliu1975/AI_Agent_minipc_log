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
