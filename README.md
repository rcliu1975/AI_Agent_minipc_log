# AI_Agent_minipc_log

這個 repo 用來獨立保存 MiniPC 與 AI Agent 相關的安裝、部署與操作筆記。
前身名稱為 `AI_Agent_setup_log`；目前已統一以 `AI_Agent_minipc_log` 為正式 repo 名稱。

目前收錄：

- [Docker_n8n_ngrok_安裝部署_ubuntu.md](./n8n/Docker_n8n_ngrok_安裝部署_ubuntu.md)

## 結構

```text
AI_Agent_minipc_log/
├── README.md
└── n8n/
    └── Docker_n8n_ngrok_安裝部署_ubuntu.md
```

## 說明

- `README.md` 內含 `MiniPC Setup Log` 區塊，集中記錄 MiniPC 初始環境建置與系統設定狀態。
- `n8n/Docker_n8n_ngrok_安裝部署_ubuntu.md` 整理 Docker、n8n、ngrok 的部署步驟與 Ubuntu 實機校正內容。

目前這個 repo 是從 `My-Notes` 拆出的獨立版本，方便後續單獨維護與發布。
若你在舊筆記、舊分支名稱或歷史說明中看到 `AI_Agent_setup_log`，都應視為目前這個 `AI_Agent_minipc_log` repo。

## MiniPC Setup Log

以下內容為原獨立 setup log 的整併版本，方便直接從 README 查閱目前的建置與同步狀態。

Date: 2026-04-11

### Completed Work

- 確認系統環境為 Ubuntu 24.04.4 LTS，登入使用者為 `<USER>`。
- 安裝並設定 `nvm`、Node.js 24 LTS、`npm` 與 Codex CLI。
- 建立 `WorkSpace` 工作目錄，並安裝 `tmux` 與 `git`。
- 檢查 `My-Notes` repo 內容與 `README.md`。
- 建立 GitHub SSH 金鑰，並確認可用 SSH 連線到 GitHub 帳號 `<GITHUB_USERNAME>`。
- 查詢主機網路資訊。
- 安裝並啟用 OpenSSH Server。

### SMB / File Sharing

- 確認系統尚未安裝 Samba。
- 確認沒有獨立的 `/home/account` 目錄，因此共享目標改採 `/home/<USER>`。
- 已建立 `setup_samba_<USER>.sh` 設定腳本；此獨立 repo 未包含該腳本檔案本體。
- Samba 尚未真正啟用，仍需要本機以 `sudo` 執行腳本完成安裝、密碼設定與服務啟動。

### My-Notes Repo

- 使用 `My-Notes-main.zip` 比對 `My-Notes` repo 內容。
- 確認 zip 內容與 repo 工作樹一致。
- 確認本地 `main`、`origin/main` 與 zip 內 commit `ae683b0f63f4958932a7d61e63821260722e42c5` 完全一致。
- 刪除 `My-Notes-main.zip` 並清理暫存解壓目錄。
- 建立本檔案並放入 `My-Notes` repo。

### Codex Interactive Mode / ctask

- 從 `WorkSpace/codex-interactive-mode` 執行 `scripts/install.sh` 安裝 `ctask`。
- 安裝完成後，`ctask` 位於 `/home/roger/.local/bin/ctask`，設定檔位於 `/home/roger/.config/codex-interactive-mode/env.sh`。
- `~/.bashrc` 已加入 `codex-interactive-mode` block，會自動 source `env.sh` 並提供 `alias ctask="$HOME/.local/bin/ctask"`。
- `env.sh` 目前記錄的預設值為 `CODEX_WORKDIR=/home/roger/WorkSpace`、`CODEX_SOCKET_DIR=/tmp/codex-tmux`、`CODEX_SESSION_PREFIX=codex`、`CODEX_CMD=/home/roger/.nvm/versions/node/v24.14.1/bin/codex`。
- 已驗證權限為：`/home/roger/.config/codex-interactive-mode` = `700`、`env.sh` = `600`、`ctask` = `755`。
- 已驗證在新 shell 中可執行 `ctask --list`；目前尚未建立任何 task，因此 `/tmp/codex-tmux` 尚不存在。

### 2026-04-12 n8n / Webhook

- 讀取並重整 `AI_Agent_minipc_log/n8n/Docker_n8n_ngrok_安裝部署_ubuntu.md`，改寫成符合本機實況的 Ubuntu 修正版。
- 確認本機 `sudo` 需要密碼、`docker` 尚未安裝，且 rootless Docker 需要的 `newuidmap` / `slirp4netns` 不存在，因此這次未採 Docker 路線。
- 改用 user-level 方案部署 `n8n 2.15.1`，安裝位置為 `/home/roger/.local/share/n8n-app`，資料目錄為 `/home/roger/.n8n`。
- repo `scripts/` 現在只保留一次性部署腳本，主要使用 `/home/roger/WorkSpace/AI_Agent_minipc_log/scripts/deploy-n8n-runtime.sh` 來建立或同步 runtime 檔案。
- n8n service 會用到的 runtime scripts 與設定檔已集中在 `/home/roger/n8n-stack`，systemd user service 也已改指向該目錄。
- 舊的 `/home/roger/.config/n8n-stack/.env` 複本已清除，避免和 `/home/roger/n8n-stack/.env` 並存造成混淆。
- 已啟用 `n8n.service`、`localtunnel.service`、`ngrok-webhook.path`；目前 `ngrok-tunnel.service` 保留但未啟用，因為機器上沒有 `NGROK_AUTHTOKEN`。
- 已驗證本機 `http://127.0.0.1:5678` 與當下公開 HTTPS URL 均回 `200 OK`，且 `WEBHOOK_URL` 已由 watcher 自動寫回 n8n 環境。
- 目前仍需後續在 UI 建立 n8n owner 帳號；另外 `loginctl show-user roger -p Linger` 為 `no`，表示 reboot 後未登入前不保證自動起服務。
- 已完成重新調整：repo `scripts/` 只放一次性部署腳本，service 依賴檔案則放在 `/home/roger/n8n-stack`。

### 2026-04-12 Agent Rules

- 更新 `agent_rule.md` 與 `keep-going-prompt.md`。
- 新增 repo 內的 `scripts/` 目錄，供非 repo / 非 GitHub 操作腳本使用；後續相關腳本需同步記錄於本檔。
- 依目前規則執行 repo 安全掃描；未發現實際 secret、private key 或 live private endpoint。
- 將 `n8n/Docker_n8n_ngrok_安裝部署_ubuntu.md` 中的 `NGROK_AUTHTOKEN` 文件範例改為空值佔位，避免看起來像真實憑證。

### 2026-04-12 Repo Sync Check

- 對齊 `AI_Agent_minipc_log` 本地與遠端主線，並修正 README 內的舊 repo 名稱與過時連結。
- 將 `youtube_post_repeater` 同步到本機工作區，確認主線一致。

### 2026-04-12 youtube-post-worker

- 建立並逐步補齊 `youtube-post-worker`：完成 Python package 骨架、CLI、SQLite 去重、JSON 輸出、排程腳本與基本測試。
- 完成 live parsing 與資料品質修正：針對目標頻道作者過濾、圖片抽取去重、`/channel/UC.../community` 相容性做修補，並建立 draft PR `#2`。
- 持續做安全與維運硬化：補上 fetch failure debug 保留、下載器的 HTTPS/private-IP/DNS 解析限制、`image/*` 驗證、retry 與 parser 錯誤訊息強化。
- 同步修正文檔與 handoff：更新 `README.md`、`plan.md`、`HANDOFF.md`、新增 `AGENTS.md`，讓安全邊界、接手流程與測試狀態一致。
- 完成 Phase 1 release hardening 與後續 sender review：測試擴到 18 個全綠，補上 sender delivery journal、retry-safe delivery 流程、`run.sh` wrapper，建立 tag `phase1-worker-hardened`、`phase1-release-complete`、`phase2-sender-reliable`，並建立 draft PR `#5`。

### 2026-04-13 youtube-post-worker 安全與文件整理

- 重新聚焦 `youtube-post-worker`，補強 fetch 與媒體下載安全限制，並增加對應 regression tests；完整測試由 5 個提升到 10 個且全數通過。
- 將 `youtube-post-worker/README.md`、`plan.md`、`HANDOFF.md` 改寫並同步為中文導向內容，讓使用方式、風險與接手資訊一致。

### 2026-04-16 youtube-post-worker 狀態確認

- 再次檢查 `youtube-post-worker` 主線狀態與安全邊界，確認沒有新增明顯 secret 或私有端點暴露，既有 fetch 與 downloader 限制仍有效。
- 將 repo remote 統一為 SSH，並建立 milestone tag `phase1-worker-hardened`。

### 2026-04-17 工作環境與 youtube-post-worker 後續硬化

- 調整 Codex 全域設定，將新 session 的 `sandbox_mode` 改為 `danger-full-access`，並記錄這只影響之後新開的 session。
- 補記運行經驗：某些 CLI 行為必須在啟動時加上 `--dangerously-bypass-approvals-and-sandbox` 才會生效，未加時應先判斷為權限模型限制。
- 更新 `youtube-post-worker/AGENTS.md`、`README.md`、`HANDOFF.md`、`plan.md`，讓下載安全邊界、handoff 狀態與測試數量一致。
- 完成 `M7` 釋出前硬化：加上 `image/*` 驗證、暫時性下載 retry、community unavailable 明確錯誤、更多 live 驗證，測試提升到 14 個全綠。
- 深入 review sender 流程後，補上 SQLite delivery journal、retry-safe delivery 流程、sender regression tests 與 `run.sh` wrapper；完整測試提升到 18 個全綠，並建立 draft PR `#5`。
- 進一步為 Telegram sender 補上圖片投遞：優先直接使用公開圖片 URL，單張圖走 `sendPhoto`、多張圖走 `sendMediaGroup`；若 URL 投遞失敗且本地已有 `local_path`，則 fallback 為本地檔案上傳。
- 已新增對應 sender 測試，覆蓋無圖、單圖、多圖，以及 URL 失敗後改用本地檔案上傳的情境；`youtube-post-worker` 測試提升到 23 個且全數通過。
