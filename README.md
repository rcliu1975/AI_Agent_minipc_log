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

- 確認 `AI_Agent_minipc_log` 本地 `main` 已 fast-forward 到 `origin/main`，目前對齊 commit `c469b8a`。
- 確認本地 `codex/rename-local-repo-dir` upstream 已刪除，但其內容與 `origin/main` 相同；為避免額外破壞性操作，這次未刪本地 branch。
- 修正 `README.md` 內殘留的 repo 名稱 `AI_Agent_setup_log` 與過時的 n8n 文件連結，統一為 `AI_Agent_minipc_log` 與目前實際檔名。
- 已將 `youtube_post_repeater` clone 到 `/home/roger/WorkSpace/youtube_post_repeater`，並確認本地 `main` 與 `origin/main` 對齊於 commit `12993bf`。

### 2026-04-12 youtube-post-worker

- 已將 `youtube-post-worker` clone 到 `/home/roger/WorkSpace/youtube-post-worker`，並確認 repo 初始狀態只有 `README.md` 與 `plan.md` 規劃文件。
- 依目前 agent rule 先做 repo 安全掃描；未發現實際 secret、private key 或危險腳本，但發現尚未建立 `.gitignore`、`.env.example`、runtime 資料夾隔離，存在日後誤提交 debug/output/SQLite 檔的風險。
- 已補上 `pyproject.toml`、`.gitignore`、`.env.example`、`docs/architecture.md`，並建立 `worker/`、`tests/`、`scripts/`、`data/debug`、`data/out`、`data/media` 骨架。
- 已實作第一版核心模組：`worker/cli.py`、`models.py`、`state.py`、`fetcher.py`、`parser.py`、`output.py`、`downloader.py`、`sender.py`、`utils.py`。
- CLI 目前支援 `init-db`、`run`、`debug-fetch`、`debug-parse`、`list-new`；`run` 可用 saved HTML mock file 做 end-to-end 驗證，並會輸出 JSON payload 與 SQLite 去重結果。
- 已新增 `scripts/run_once.sh`、`scripts/install_cron.sh`、`scripts/install_systemd.sh`，並同步在 repo `README.md` 記錄其用途與基本使用說明。
- 已加入 `tests/fixtures/sample_community.html` 與 3 個 `unittest` 測試，涵蓋 parser、state 與 CLI mock run。
- 已本地驗證：`python3 -m unittest discover -s tests -v` 全數通過；mock `run` 會先輸出 2 筆新文、第二次重跑則正確回傳無新文。
- 已用真實頻道 `https://www.youtube.com/@yutinghaofinance/community` 做 live 驗證；初版 parser 會混入非目標作者內容，因此已改為依 `authorEndpoint.browseEndpoint.canonicalBaseUrl` 過濾，只保留目標頻道自己的 community 貼文。
- 已同步修正圖片抽取邏輯，不再把同一張圖的多個縮圖尺寸全部寫入 payload，而是保留每組 thumbnails 中解析度最高的一個 URL。
- live 驗證結果：重新解析保存的 raw HTML 後，共得到 11 篇屬於 `游庭皓的財經皓角`、`UC0lbAQVpenvfA2QqzsRtL_g` 的貼文；直接用 live URL 連跑兩次 `run`，第一次回傳 `10` 並輸出 11 個 payload，第二次回傳 `0`，證明 SQLite 去重生效。
- 已建立 branch `codex/bootstrap-youtube-worker`，commit `b0c6c25` (`Bootstrap worker and validate live parsing`)；由於本機沒有 `gh` 且 origin push URL 原本是 HTTPS，已只在此 repo 將 `origin` 的 push URL 改為 SSH 後成功推送。
- 已建立 draft PR `#2`：`[codex] Bootstrap worker and validate live YouTube parsing`，連結為 `https://github.com/rcliu1975/youtube-post-worker/pull/2`。
- 已追加 follow-up commit `851dcf2` (`Harden channel author matching`) 到同一個 PR；修正 parser 在 `/channel/UC.../community` 形式 URL 下，可能因 canonical path 與 handle path 不同而誤排除正確貼文的問題。
- 已補測試覆蓋 `https://www.youtube.com/channel/UC123456789/community` 這類 channel-id URL，並重新執行 `python3 -m unittest discover -s tests -v`，4 個測試全數通過。
- 2026-04-13 持續加固 scraper 維運性：開始補 `fetch` 失敗時的 debug 保留機制，目標是在 403/429/異常 HTML 回應下，也能把失敗回應本體存到 `data/debug/` 供後續分析。
- 本輪已修改 `worker/fetcher.py`、`worker/cli.py` 與 `tests/test_cli.py`，新增 `FetchError` 攜帶 `response_text` / `debug_path` 的設計，以及 `debug-fetch` 失敗時應寫出 `*fetch-error.html` 的測試。
- 測試過程中發現一個尚未完成的修正：`debug-fetch` subcommand 的 `Namespace` 沒有 `mock_file` 欄位，導致新的 `_load_html()` 路徑在測試中出現 `AttributeError`。本次先中止進一步修改，待下一輪補成 `getattr(args, "mock_file", None)` 後再重跑測試並推回 PR。
