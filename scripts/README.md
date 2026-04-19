# Scripts

Store one-shot system-operation scripts here.

For n8n, this repo keeps deployment/sync scripts only.
Runtime files that services use are generated under `~/n8n-stack`.

Available scripts:

- `deploy-n8n-runtime.sh`: generate or refresh the runtime files under `~/n8n-stack`
- `configure-ngrok-for-n8n.sh`: write `NGROK_AUTHTOKEN` into `~/n8n-stack/.env` and switch the public tunnel to `ngrok`

Do not place repo-related or GitHub-operation scripts here.
Keep real tokens and secrets out of the repo; store them only in the external runtime env file.
