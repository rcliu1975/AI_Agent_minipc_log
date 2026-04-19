# Docker、n8n、ngrok 安裝部署整理（Ubuntu 實機修正版）

本整理檔以 2026-04-12 這台 Ubuntu 主機的實際部署結果為準，不再只描述理想中的 Docker 路線，而是把「能落地的做法」、「目前的限制」、以及「之後如何切回 ngrok / Docker」一起整理清楚。

## 1. 一句結論

這台機器目前的可用架構不是：

```text
Telegram
→ ngrok
→ n8n（Docker）
```

而是：

```text
Telegram
→ HTTPS Tunnel（目前是 localtunnel，之後可切回 ngrok）
→ n8n（user-level systemd + Node.js）
→ Workflow
```

原因很直接：

- 主機上沒有可直接使用的 `docker`
- `sudo` 需要密碼，無法直接做 apt / Docker 安裝
- rootless Docker 需要的系統元件也不齊
- 但機器上已經有可用的 Node.js / npm / user-level systemd，所以先把 n8n 跑起來是可行的

## 2. 本機現況

部署當下的主機條件如下：

- OS：`Ubuntu 24.04.4 LTS`
- Architecture：`x86_64`
- User：`roger`
- Node.js：`v24.14.1`
- npm：`11.11.0`
- `sudo -n true`：失敗，代表需要密碼
- `docker`：不存在
- `ngrok` Agent CLI：不存在

另外兩個重要限制：

1. `loginctl show-user roger -p Linger` 回傳 `Linger=no`
2. 這代表 user-level service 會在 `roger` 登入後啟動，但不能保證無登入情況下跨 reboot 常駐

## 3. 為什麼這次沒有走 Docker

理想上 Ubuntu 上的標準做法仍然是：

1. 安裝 Docker
2. 用 Docker 啟動 n8n
3. 用 ngrok 提供 HTTPS webhook

但這台機器當下卡在兩個層級：

### 3.1 rootful Docker 卡在 `sudo`

文件原本的 Docker 安裝需要：

```bash
sudo apt remove docker.io -y
curl -fsSL https://get.docker.com | sh
```

這台機器無法直接執行，因為 `sudo` 需要手動輸入密碼。

### 3.2 rootless Docker 卡在系統缺件

檢查結果顯示：

- 有 `subuid` / `subgid`
- 但缺 `newuidmap`
- 也缺 `slirp4netns`

這代表 rootless Docker 也無法直接落地，除非先由有 root 權限的人安裝：

```bash
sudo apt install uidmap slirp4netns iptables
```

所以這次的務實做法是：

- 先不用 Docker
- 直接把 `n8n` 安裝到使用者目錄
- 用 `systemd --user` 管理
- 再補一條可公開 HTTPS 的 tunnel

## 4. 最終落地方案

### 4.1 n8n 執行方式

本機目前採用：

```text
Node.js + npm 安裝 n8n
→ systemd --user 啟動 n8n
→ 監聽 localhost / 0.0.0.0:5678
```

實際安裝位置：

```text
/home/roger/.local/share/n8n-app
```

實際啟動指令核心：

```bash
/home/roger/.local/share/n8n-app/node_modules/.bin/n8n start
```

### 4.2 n8n 資料目錄

實際資料目錄為：

```text
/home/roger/.n8n
```

裡面包含：

- `config`
- `database.sqlite`
- `n8nEventLog.log`

一個這次實作時確認的重要細節是：

- `N8N_USER_FOLDER` 不能設成 `/home/roger/.n8n`
- 因為 n8n 會再自動 append 一層 `.n8n`
- 正確值應設為 `/home/roger`

也就是說：

```text
N8N_USER_FOLDER=/home/roger
→ 實際資料路徑 /home/roger/.n8n
```

## 5. 已建立的部署目錄與檔案

repo 內目前只保留一次性部署腳本：

```text
/home/roger/WorkSpace/AI_Agent_minipc_log/scripts
```

主要使用：

- `deploy-n8n-runtime.sh`

真正提供給 service 使用的 runtime 目錄為：

```text
/home/roger/n8n-stack
```

核心檔案如下：

- `.env`
- `start-n8n.sh`
- `start-ngrok.sh`
- `start-ngrok.js`
- `start-localtunnel.sh`
- `start-localtunnel.js`
- `restart-n8n-on-webhook-change.sh`
- `status.sh`
- `switch-to-ngrok.sh`

部署或同步 runtime 檔案時，執行：

```text
/home/roger/WorkSpace/AI_Agent_minipc_log/scripts/deploy-n8n-runtime.sh
```

執行期設定檔位於：

```text
/home/roger/n8n-stack/.env
```

目前使用的設定如下：

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

補充：

- `N8N_RUNNERS_ENABLED` 在 `n8n 2.15.1` 已不需要，已從設定移除
- `N8N_SECURE_COOKIE=false` 是因為本機 UI 仍會經由 `http://localhost:5678` 打開

## 6. 已建立的 user-level systemd service

本次實際安裝到：

```text
/home/roger/.config/systemd/user
```

目前存在的 unit：

- `n8n.service`
- `localtunnel.service`
- `ngrok-tunnel.service`
- `ngrok-webhook.service`
- `ngrok-webhook.path`

角色分工如下：

### 6.1 `n8n.service`

負責啟動 n8n 主服務。

### 6.2 `localtunnel.service`

目前實際使用中的公開 HTTPS tunnel。

用途：

- 將本機 `127.0.0.1:5678` 對外暴露成 HTTPS URL
- 將 URL 寫到：

```text
/home/roger/.n8n/current_webhook_url
```

### 6.3 `ngrok-tunnel.service`

已經準備好，但目前未啟用。

原因：

- ngrok 現在要求 verified account + authtoken
- 這台機器上沒有現成 token

### 6.4 `ngrok-webhook.path`

監看：

```text
/home/roger/.n8n/current_webhook_url
```

當 tunnel URL 改變時：

```text
path unit 偵測變更
→ oneshot service 觸發
→ 重新啟動 n8n
→ n8n 重新吃到新的 WEBHOOK_URL
```

這次實作中也修正了一個 systemd 細節：

- 原本如果同時設 `PathExists=` 與 `PathChanged=`
- 在檔案已存在時容易造成 repeated trigger
- 最終保留 `PathChanged=` 才穩定

## 7. 目前可用的存取方式

### 7.1 本機 / 內網

```text
http://localhost:5678
http://<LAN-IP>:5678
http://<TAILSCALE-OR-VPN-IP>:5678
```

### 7.2 目前公開 HTTPS URL

當下的公開 HTTPS URL 不建議直接寫死在 repo，因為：

- tunnel URL 可能改變
- 若 repo 會對外共享，保留 live endpoint 沒必要

正確做法是每次都以：

```bash
cat /home/roger/.n8n/current_webhook_url
```

為準。

## 8. 目前服務狀態

部署完成時的實際狀態：

```text
n8n: active
localtunnel: active
ngrok-tunnel: inactive
ngrok-webhook.path: active
```

可用以下指令查看：

```bash
/home/roger/n8n-stack/status.sh
```

## 9. 健康檢查結果

本次已驗證：

### 9.1 本機 HTTP 正常

```bash
curl -I http://127.0.0.1:5678
```

回應：

```text
HTTP/1.1 200 OK
```

### 9.2 公開 HTTPS 正常

```bash
curl -I "$(cat /home/roger/.n8n/current_webhook_url)"
```

回應：

```text
HTTP/1.1 200 OK
```

### 9.3 `WEBHOOK_URL` 已寫進 n8n 執行環境

實際檢查結果顯示：

```text
WEBHOOK_URL=<current public HTTPS URL>
N8N_PROXY_HOPS=1
```

也就是說：

- tunnel URL 已經寫入 `current_webhook_url`
- watcher 已觸發 n8n 重啟
- n8n 已經帶著正確的 `WEBHOOK_URL` 啟動

## 10. n8n 啟動後仍需手動完成的事

目前 `n8n` 的 API 回應顯示：

```text
showSetupOnFirstLoad: true
```

代表 owner 帳號尚未建立。

所以第一次開啟 UI 後還要做：

1. 建立 n8n owner 帳號
2. 登入
3. 建立 workflow
4. 若要接 Telegram，再建立對應 credential

## 11. Telegram Webhook 最小可用流程

如果只是驗證 webhook 通了沒有，最小流程仍然是：

```text
Telegram Trigger
→ Telegram Send Message
```

建議測試內容：

### 11.1 Telegram Trigger

- Event：`On Message`
- Credential：Bot Token

### 11.2 Telegram Send Message

Chat ID：

```text
{{ $json.message.chat.id }}
```

Text：

```text
收到：{{ $json.message.text }}
```

### 11.3 測試方式

1. 在 n8n 中開啟 workflow
2. 進入測試監聽或直接將 workflow 設為 `Active`
3. 在 Telegram 傳送 `hello`
4. 確認 bot 回覆 `收到：hello`

## 12. ngrok 之後如何切回來

雖然這次沒有真正啟用 ngrok，但切回 ngrok 的路已經鋪好。

### 12.1 原因

這次沒有啟用 ngrok 不是因為程式碼沒寫好，而是因為官方現在要求：

- verified account
- authtoken

實際測試時，沒有 token 會直接得到：

```text
ERR_NGROK_4018
Usage of ngrok requires a verified account and authtoken.
```

### 12.2 切回 ngrok 的步驟

1. 到 ngrok dashboard 取得 authtoken
2. 編輯：

```text
/home/roger/n8n-stack/.env
```

3. 填入：

```dotenv
NGROK_AUTHTOKEN=
```

再把你自己的 ngrok authtoken 填在等號右側，不要把實際值寫回 repo。

4. 執行：

```bash
/home/roger/n8n-stack/switch-to-ngrok.sh
```

這支腳本會做的事：

```text
停止 localtunnel
→ disable localtunnel.service
→ enable --now ngrok-tunnel.service
→ ngrok 將新網址寫入 current_webhook_url
→ watcher 觸發 n8n 重啟
→ n8n 吃到新的 WEBHOOK_URL
```

## 13. 如果之後一定要切回 Docker

若後續要回到原本「Docker + n8n + ngrok」的標準化模式，至少需要先解掉以下前置條件：

### 13.1 取得 root 權限

至少要能執行：

```bash
sudo apt update
sudo apt install ...
```

### 13.2 安裝 Docker 或 rootless Docker 需求

可能的需求包括：

```bash
sudo apt install uidmap slirp4netns iptables
```

如果走 rootful Docker，則再安裝 Docker Engine。

### 13.3 啟用 linger

如果想讓 user-level service 在 reboot 後、未登入前也能自動啟動，需要 root 執行：

```bash
sudo loginctl enable-linger roger
```

## 14. 常用維運指令

### 14.1 看整體狀態

```bash
/home/roger/n8n-stack/status.sh
```

### 14.2 看 n8n log

```bash
journalctl --user -u n8n.service -n 50 --no-pager
journalctl --user -u n8n.service -f
```

### 14.3 看 localtunnel log

```bash
journalctl --user -u localtunnel.service -n 50 --no-pager
journalctl --user -u localtunnel.service -f
```

### 14.4 看目前 webhook URL

```bash
cat /home/roger/.n8n/current_webhook_url
```
