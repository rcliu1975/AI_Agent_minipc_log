# MiniPC Setup Log

Date: 2026-04-11

## Completed Work

- 確認系統環境為 Ubuntu 24.04.4 LTS，登入使用者為 `<USER>`。
- 安裝並設定 `nvm`、Node.js 24 LTS、`npm` 與 Codex CLI。
- 建立 `WorkSpace` 工作目錄，並安裝 `tmux` 與 `git`。
- 檢查 `My-Notes` repo 內容與 `README.md`。
- 建立 GitHub SSH 金鑰，並確認可用 SSH 連線到 GitHub 帳號 `<GITHUB_USERNAME>`。
- 查詢主機網路資訊。
- 安裝並啟用 OpenSSH Server。

## SMB / File Sharing

- 確認系統尚未安裝 Samba。
- 確認沒有獨立的 `/home/account` 目錄，因此共享目標改採 `/home/<USER>`。
- 已建立 `setup_samba_<USER>.sh` 設定腳本；此獨立 repo 未包含該腳本檔案本體。
- Samba 尚未真正啟用，仍需要本機以 `sudo` 執行腳本完成安裝、密碼設定與服務啟動。

## My-Notes Repo

- 使用 `My-Notes-main.zip` 比對 `My-Notes` repo 內容。
- 確認 zip 內容與 repo 工作樹一致。
- 確認本地 `main`、`origin/main` 與 zip 內 commit `ae683b0f63f4958932a7d61e63821260722e42c5` 完全一致。
- 刪除 `My-Notes-main.zip` 並清理暫存解壓目錄。
- 建立本檔案並放入 `My-Notes` repo。

## Codex Interactive Mode / ctask

- 從 `WorkSpace/codex-interactive-mode` 執行 `scripts/install.sh` 安裝 `ctask`。
- 安裝完成後，`ctask` 位於 `/home/roger/.local/bin/ctask`，設定檔位於 `/home/roger/.config/codex-interactive-mode/env.sh`。
- `~/.bashrc` 已加入 `codex-interactive-mode` block，會自動 source `env.sh` 並提供 `alias ctask="$HOME/.local/bin/ctask"`。
- `env.sh` 目前記錄的預設值為 `CODEX_WORKDIR=/home/roger/WorkSpace`、`CODEX_SOCKET_DIR=/tmp/codex-tmux`、`CODEX_SESSION_PREFIX=codex`、`CODEX_CMD=/home/roger/.nvm/versions/node/v24.14.1/bin/codex`。
- 已驗證權限為：`/home/roger/.config/codex-interactive-mode` = `700`、`env.sh` = `600`、`ctask` = `755`。
- 已驗證在新 shell 中可執行 `ctask --list`；目前尚未建立任何 task，因此 `/tmp/codex-tmux` 尚不存在。

## 2026-04-12 n8n / Webhook

- 讀取並重整 `AI_Agent_setup_log/n8n/Docker_n8n_ngrok_安裝部署_ubuntu.md`，改寫成符合本機實況的 Ubuntu 修正版。
- 確認本機 `sudo` 需要密碼、`docker` 尚未安裝，且 rootless Docker 需要的 `newuidmap` / `slirp4netns` 不存在，因此這次未採 Docker 路線。
- 改用 user-level 方案部署 `n8n 2.15.1`，安裝位置為 `/home/roger/.local/share/n8n-app`，資料目錄為 `/home/roger/.n8n`。
- 建立 `/home/roger/WorkSpace/n8n-stack`，放置 `.env`、啟動腳本、`status.sh`、`switch-to-ngrok.sh` 與對應的 systemd user service。
- 依 repo 規則，已將目前的 n8n helper scripts 另存一份到 repo 的 `n8n/` 目錄，方便後續追蹤與重建。
- 已啟用 `n8n.service`、`localtunnel.service`、`ngrok-webhook.path`；目前 `ngrok-tunnel.service` 保留但未啟用，因為機器上沒有 `NGROK_AUTHTOKEN`。
- 已驗證本機 `http://127.0.0.1:5678` 與當下公開 HTTPS URL 均回 `200 OK`，且 `WEBHOOK_URL` 已由 watcher 自動寫回 n8n 環境。
- 目前仍需後續在 UI 建立 n8n owner 帳號；另外 `loginctl show-user roger -p Linger` 為 `no`，表示 reboot 後未登入前不保證自動起服務。
