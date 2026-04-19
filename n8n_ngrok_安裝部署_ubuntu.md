# n8n + ngrok 安裝部署整理（Ubuntu）

這份文件改以目前實際可用的方案為主：

```text
Internet / Telegram / Webhook Provider
→ ngrok public HTTPS URL
→ n8n (systemd --user + Node.js)
→ workflow
```

不再把重點放在 Docker 或 localtunnel，而是聚焦在：

- `n8n` 如何安裝與啟動
- `ngrok` 如何提供公開 HTTPS 入口
- `ngrok` domain 變動時，如何自動同步到 `n8n`

## 1. 原理先講清楚

`n8n` 只要有 webhook，就必須知道「自己對外的公開 URL 是什麼」。

問題在於：

- 本機 `n8n` 通常只監聽 `localhost:5678`
- `ngrok` 會提供一個外部 HTTPS URL
- 如果 `ngrok` 的 domain 改了，`n8n` 裡的 `WEBHOOK_URL` 也要跟著改

這份部署的核心做法不是把 `WEBHOOK_URL` 寫死，而是走一條「狀態檔 + path watcher + restart」的同步鏈：

```text
ngrok-tunnel.service
→ start-ngrok.js 取得新的 public URL
→ 寫入 ~/.n8n/current_webhook_url
→ ngrok-webhook.path 偵測檔案變更
→ ngrok-webhook.service 觸發 restart-n8n-on-webhook-change.sh
→ 比對 current_webhook_url 與 current_webhook_url.applied
→ 若不同，重新啟動 n8n.service
→ start-n8n.sh 在啟動時讀取 current_webhook_url
→ 將該值匯出成 WEBHOOK_URL
```

這樣的好處是：

- 不需要把 `WEBHOOK_URL` 固定寫在 repo
- `ngrok` 換 domain 後，`n8n` 會自動吃到新值
- 變更來源只有 `~/.n8n/current_webhook_url` 這個狀態檔，容易檢查

實際上負責這件事的檔案是：

- `~/n8n-stack/start-ngrok.js`
- `~/n8n-stack/restart-n8n-on-webhook-change.sh`
- `~/n8n-stack/start-n8n.sh`
- `~/.config/systemd/user/ngrok-webhook.path`

## 2. 目前採用的部署方式

這台機器目前不是用 Docker，而是：

- `n8n` 安裝在 `~/.local/share/n8n-app`
- runtime 檔案集中在 `~/n8n-stack`
- service 使用 `systemd --user`
- `ngrok` 提供公開 HTTPS URL

這條路線適合目前這台機器，因為：

- 已有可用的 Node.js / npm
- 可使用 `systemd --user`
- 不需要 rootful Docker

## 3. 路徑約定

實際部署會用到這些路徑：

- repo 文件：`/home/roger/WorkSpace/AI_Agent_minipc_log`
- repo 腳本：`/home/roger/WorkSpace/AI_Agent_minipc_log/scripts`
- runtime 目錄：`/home/roger/n8n-stack`
- runtime env：`/home/roger/n8n-stack/.env`
- n8n 資料目錄：`/home/roger/.n8n`
- 狀態檔：`/home/roger/.n8n/current_webhook_url`
- systemd user units：`/home/roger/.config/systemd/user`

## 4. 前置條件

至少要有：

- Ubuntu
- 一個一般使用者帳號，例如 `roger`
- `systemd --user`
- Node.js 與 npm
- 可用的 `ngrok` 帳號與 `authtoken`

檢查目前環境：

```bash
node -v
npm -v
systemctl --user --version
ngrok version
```

如果 `ngrok` CLI 尚未安裝，先安裝它；若已安裝可略過。

## 5. 安裝 n8n 與 ngrok Node 套件

這份部署需要兩種不同層次的 `ngrok` 元件：

- `ngrok` CLI：供你手動檢查版本、登入或除錯
- `@ngrok/ngrok` Node 套件：供 `start-ngrok.js` 在背景服務中呼叫

安裝建議如下：

```bash
mkdir -p /home/roger/.local/share/n8n-app
cd /home/roger/.local/share/n8n-app
npm init -y
npm install n8n@latest

mkdir -p /home/roger/.local/share/ngrok-app
cd /home/roger/.local/share/ngrok-app
npm init -y
npm install @ngrok/ngrok
```

如果 `ngrok` CLI 還沒裝，請依官方方式安裝；這不寫進 repo 腳本，因為通常和系統套件管理方式綁在一起。

## 6. 產生 runtime 檔案

repo 裡只保留一次性部署腳本；真正被 service 使用的檔案會生成到 `~/n8n-stack`。

執行：

```bash
/home/roger/WorkSpace/AI_Agent_minipc_log/scripts/deploy-n8n-runtime.sh
```

這支腳本會建立或刷新：

- `~/n8n-stack/.env`
- `~/n8n-stack/start-n8n.sh`
- `~/n8n-stack/start-ngrok.sh`
- `~/n8n-stack/start-ngrok.js`
- `~/n8n-stack/restart-n8n-on-webhook-change.sh`
- `~/n8n-stack/status.sh`
- `~/n8n-stack/switch-to-ngrok.sh`
- 對應的 `systemd --user` unit

## 7. 設定 `n8n` 執行參數

主要設定檔是：

```text
/home/roger/n8n-stack/.env
```

建議值如下：

```dotenv
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
```

兩個容易搞錯的點：

### 7.1 `N8N_USER_FOLDER`

不要設成：

```text
/home/roger/.n8n
```

正確應該是：

```text
/home/roger
```

因為 `n8n` 會自己再 append 一層 `.n8n`。

### 7.2 `WEBHOOK_URL`

不要把 live URL 長期寫死在 `.env`。

這份方案的設計是：

- `.env` 內讓 `WEBHOOK_URL` 保持空值
- `start-n8n.sh` 會在啟動時讀取 `~/.n8n/current_webhook_url`

這樣 ngrok domain 改變時，才會走自動同步鏈。

## 8. 設定 ngrok authtoken 並切換到 ngrok

如果手動敲命令，步驟會偏長，所以 repo 提供一次性腳本：

- [configure-ngrok-for-n8n.sh](/home/roger/WorkSpace/AI_Agent_minipc_log/scripts/configure-ngrok-for-n8n.sh)

這支腳本會：

1. 將 `NGROK_AUTHTOKEN` 寫進 `~/n8n-stack/.env`
2. 停止並停用 `localtunnel.service`
3. 啟用並啟動 `ngrok-tunnel.service`
4. 輸出目前 `current_webhook_url`

使用方式：

```bash
/home/roger/WorkSpace/AI_Agent_minipc_log/scripts/configure-ngrok-for-n8n.sh --token '<YOUR_NGROK_AUTHTOKEN>'
```

如果你的 token 已經存在 `~/.config/ngrok/ngrok.yml`，可以直接執行：

```bash
/home/roger/WorkSpace/AI_Agent_minipc_log/scripts/configure-ngrok-for-n8n.sh
```

若要順手刪除本機的 localtunnel 安裝目錄：

```bash
/home/roger/WorkSpace/AI_Agent_minipc_log/scripts/configure-ngrok-for-n8n.sh --remove-localtunnel
```

## 9. systemd --user service 分工

### 9.1 `n8n.service`

負責啟動 `n8n` 主程序。

實際核心命令：

```bash
/home/roger/.local/share/n8n-app/node_modules/.bin/n8n start
```

### 9.2 `ngrok-tunnel.service`

負責啟動 `start-ngrok.sh`，再由 `start-ngrok.js` 向 `ngrok` 取得公開 URL。

### 9.3 `ngrok-webhook.path`

監看：

```text
/home/roger/.n8n/current_webhook_url
```

只要檔案內容改變，就觸發 `ngrok-webhook.service`。

### 9.4 `ngrok-webhook.service`

執行 `restart-n8n-on-webhook-change.sh`。

這支腳本會比較：

- `current_webhook_url`
- `current_webhook_url.applied`

若兩者不同，才重啟 `n8n.service`，避免重複觸發。

## 10. 啟動與驗證

看整體狀態：

```bash
/home/roger/n8n-stack/status.sh
```

看目前 public URL：

```bash
cat /home/roger/.n8n/current_webhook_url
```

看 `ngrok` 狀態：

```bash
systemctl --user status ngrok-tunnel.service --no-pager
```

看 `n8n` 狀態：

```bash
systemctl --user status n8n.service --no-pager
```

健康檢查：

```bash
curl -I http://127.0.0.1:5678
curl -I "$(cat /home/roger/.n8n/current_webhook_url)"
```

正常情況下兩者都應回 `200 OK`。

## 11. 如何確認自動同步真的有生效

最直接的檢查方式是：

1. 重新啟動 `ngrok-tunnel.service`
2. 觀察 `current_webhook_url` 是否被改寫
3. 觀察 `n8n.service` 是否被 watcher 重新啟動

可用指令：

```bash
systemctl --user restart ngrok-tunnel.service
journalctl --user -u ngrok-tunnel.service -n 50 --no-pager
journalctl --user -u ngrok-webhook.service -n 50 --no-pager
journalctl --user -u n8n.service -n 50 --no-pager
```

如果看到：

- `ngrok forwarding https://... -> http://127.0.0.1:5678`
- `current_webhook_url` 被寫入新值
- `n8n.service` 隨後重啟

就代表同步鏈正常。

## 12. 已知限制

### 12.1 user-level service 與 linger

如果：

```bash
loginctl show-user roger -p Linger
```

顯示 `Linger=no`，代表 reboot 後若沒有登入，無法保證 user-level service 自動常駐。

若要在未登入前也能自動啟動，需要 root：

```bash
sudo loginctl enable-linger roger
```

### 12.2 Python task runner 提示

目前 `n8n 2.15.1` 啟動時，可能看到 Python runner internal mode 的提示。

這不影響 JS workflow 正常運作，但若之後要正式使用 Python task runner，應依 `n8n` 官方文件改成 external mode。

## 13. 不再建議的做法

以下做法不建議再當主線：

- 把 `WEBHOOK_URL` 寫死在 repo 文件或 repo 設定檔
- 以 `localtunnel` 當正式長期入口
- 預設假設 `docker` 在這台機器上一定可用

目前這台機器的主線做法應以：

```text
systemd --user + n8n + ngrok + webhook URL state file watcher
```

為準。
