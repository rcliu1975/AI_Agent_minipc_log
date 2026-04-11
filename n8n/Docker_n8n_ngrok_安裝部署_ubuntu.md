# Docker、n8n、ngrok 安裝與部署整理

本整理檔根據以下筆記重組而成，目標是保留可直接操作的安裝與部署步驟：

- `1_Codex CLI + GitHub 完整安裝與使用流程.md`
- `2_Telegram Bot × n8n（Webhook版）最小可用流程筆記.md`
- `3_Docker + n8n + ngrok 部署筆記.md`

本份內容聚焦於：

- Docker 安裝
- n8n 以 Docker 方式部署
- ngrok 設定與 webhook 對接
- systemd 自動啟動與 webhook 自動修復思路

## 1. 適用場景

這套流程適合以下架構：

```text
Telegram
→ HTTPS Webhook（ngrok）
→ n8n（Docker）
→ Workflow
→ Telegram API 回覆
```

如果只是要做最小可用版本，核心需求只有三個：

- Docker 能正常執行
- n8n 容器能對外提供 `5678`
- ngrok 能把本機 `5678` 暴露成公開 HTTPS URL

## 2. 前置條件

原始筆記中和本主題直接相關的前置條件如下：

- 作業系統：Armbian / ARM64 環境
- 已可使用 `curl`
- 已可使用 `sudo`
- 若需操作 Telegram Bot，需先向 BotFather 取得 `BOT TOKEN`

如果要確認機器架構，可先執行：

```bash
uname -m
```

預期為：

```text
aarch64
```

## 3. Docker 安裝方式

原始筆記採用 `get.docker.com` 便利安裝腳本。根據 Docker 官方文件，這個方式適合快速建立測試或開發環境，但不建議直接當成正式環境的標準安裝方式。

另外，Docker 官方文件也說明，Ubuntu 或 Debian 的衍生發行版不屬於正式支援對象，雖然通常仍可依對應的 Ubuntu / Debian 安裝流程使用。Armbian 屬於這類實務上可用、但不是 Docker 官方保證支援的情境。

### 3.1 移除有問題的 `docker.io`

```bash
sudo apt remove docker.io -y
sudo apt autoremove -y
```

補充：Docker 官方文件列出的常見衝突套件不只 `docker.io`，還包括 `docker-compose`、`docker-compose-v2`、`docker-doc`、`podman-docker`、`containerd`、`runc` 等；原始筆記只先處理了最直接的 `docker.io`。

### 3.2 使用官方便利腳本安裝 Docker

```bash
curl -fsSL https://get.docker.com | sh
```

如果要更貼近官方正式部署方式，應優先使用 Docker 官方 apt repository 安裝；但在原始筆記的 Armbian 情境下，便利腳本仍是合理的快速路徑。

### 3.3 驗證 Docker 是否正常

```bash
docker run hello-world
```

若安裝成功，應看到類似：

```text
Hello from Docker!
```

## 4. n8n 部署方式

這份筆記的 n8n 安裝方式不是主機原生安裝，而是直接用 Docker container 部署。

### 4.1 建立 n8n 資料目錄

```bash
mkdir -p ~/.n8n
sudo chown -R 1000:1000 ~/.n8n
```

這一步的目的是修正 volume 掛載後的權限問題。筆記中的對應關係是：

| 主機路徑 | 容器路徑 |
| --- | --- |
| `/home/<USER>/.n8n` | `/home/node/.n8n` |

因為容器內的 `node` 使用者 UID 為 `1000`，所以主機端資料夾也要對應權限。

### 4.2 啟動 n8n 容器

原筆記的部署方向沒有問題，但部分環境變數已過時。依目前 n8n 官方 Docker 文件，較接近現況的最小啟動方式如下：

```bash
docker run -d \
  --name n8n \
  --restart always \
  -p 5678:5678 \
  -e GENERIC_TIMEZONE="<YOUR_TIMEZONE>" \
  -e TZ="<YOUR_TIMEZONE>" \
  -e N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true \
  -e N8N_RUNNERS_ENABLED=true \
  -v /home/<USER>/.n8n:/home/node/.n8n \
  docker.n8n.io/n8nio/n8n
```

### 4.3 如果要讓 webhook 正常運作，必須補上 `WEBHOOK_URL`

如果 n8n 放在 ngrok 這類 reverse proxy / tunnel 後方，官方文件要求除了 `WEBHOOK_URL` 之外，也要設定 `N8N_PROXY_HOPS=1`。

Webhook 版本部署時，建議用以下方式：

```bash
docker run -d \
  --name n8n \
  --restart always \
  -p 5678:5678 \
  -e GENERIC_TIMEZONE="<YOUR_TIMEZONE>" \
  -e TZ="<YOUR_TIMEZONE>" \
  -e N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true \
  -e N8N_RUNNERS_ENABLED=true \
  -e WEBHOOK_URL=https://xxxxx.ngrok-free.app \
  -e N8N_PROXY_HOPS=1 \
  -v /home/<USER>/.n8n:/home/node/.n8n \
  docker.n8n.io/n8nio/n8n
```

重點說明：

- `GENERIC_TIMEZONE`：設定排程相關節點的時區
- `TZ`：設定容器系統時區
- `N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true`：官方 Docker 文件建議啟用
- `N8N_RUNNERS_ENABLED=true`：官方 Docker 文件建議啟用 task runners
- `WEBHOOK_URL`：告訴 n8n 對外公開的 webhook 基底網址
- `N8N_PROXY_HOPS=1`：讓 n8n 在代理後方正確處理 forwarded headers
- `-v /home/<USER>/.n8n:/home/node/.n8n`：保留 n8n 資料與設定
- `docker.n8n.io/n8nio/n8n`：目前官方文件使用的映像來源

### 4.4 存取位置

本機或內網通常透過以下方式存取：

```text
http://<主機 IP 或主機名>:5678
```

筆記中也有 Tailscale 存取示例：

```text
http://<YOUR_HOST>.tailnet.ts.net:5678
```

補充兩個目前官方文件相關的重要點：

- `N8N_SECURE_COOKIE` 預設是 `true`，代表 cookie 只會經由 HTTPS 傳送。如果你是直接用 `http://主機:5678` 打開 n8n UI，而不是經由 HTTPS 反向代理，才考慮額外加上 `-e N8N_SECURE_COOKIE=false`。
- n8n 官方已在 1.0 移除 self-hosted 的 Basic Auth 與 JWT。現在的正確流程是首次打開 UI 後，在介面中建立 owner 帳號，而不是再使用舊的 `N8N_BASIC_AUTH_*` 環境變數。

## 5. ngrok 設定與啟動方式

原始筆記保留的是 ngrok 使用流程與 token 設定。根據 ngrok 官方 quickstart，Agent CLI 可直接安裝後再做 `add-authtoken` 設定。

### 5.0 安裝 ngrok Agent CLI

官方文件提供 Debian Linux 安裝方式：

```bash
curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc \
  | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null \
  && echo "deb https://ngrok-agent.s3.amazonaws.com buster main" \
  | sudo tee /etc/apt/sources.list.d/ngrok.list \
  && sudo apt update \
  && sudo apt install ngrok
```

安裝後可用以下指令確認：

```bash
ngrok help
```

### 5.1 建立帳號並取得 Authtoken

流程如下：

1. 到 `https://ngrok.com`
2. 註冊或登入
3. 進入 Dashboard
4. 找到 `Your Authtoken`
5. 複製 token

### 5.2 在主機上寫入 ngrok token

```bash
ngrok config add-authtoken 你的token
```

成功時會看到：

```text
Authtoken saved to configuration file
```

### 5.3 啟動 ngrok tunnel

```bash
ngrok http 5678
```

啟動後會看到類似輸出：

```text
Forwarding https://xxxxx.ngrok-free.app -> http://localhost:5678
```

這個 HTTPS URL 就是 Telegram webhook 與 n8n `WEBHOOK_URL` 應使用的公開網址。

Telegram 官方 webhook 文件要求公開入口是 HTTPS，且公開 port 須為 `443`、`80`、`88` 或 `8443`。使用 ngrok 時，Telegram 看到的是 ngrok 對外提供的 HTTPS 網址，因此這種做法是符合 webhook 條件的。

## 6. n8n + ngrok 的正確部署順序

依原始筆記整合後，推薦順序如下：

1. 安裝並驗證 Docker
2. 建立 `~/.n8n` 並修正權限
3. 啟動 ngrok，取得公開 HTTPS URL
4. 用該 URL 啟動 n8n，並設定 `WEBHOOK_URL` 與 `N8N_PROXY_HOPS=1`
5. 在 n8n 建立 workflow
6. 啟用 workflow 或進入測試監聽

若先開 n8n、後開 ngrok，則 `WEBHOOK_URL` 很可能不是正確的公開網址，Webhook 會失效。

## 7. Telegram Webhook 最小可用流程

筆記中最小可用流程如下：

```text
Telegram Trigger
→ Telegram（Send Message）
```

### 7.1 Telegram Trigger

- Event：`On Message`
- Credential：Bot Token

### 7.2 Telegram Send Message

Chat ID：

```text
{{ $json.message.chat.id }}
```

Text：

```text
收到：{{ $json.message.text }}
```

### 7.3 測試方式

1. 在 n8n 中按 `Execute` 或進入測試監聽
2. 在 Telegram 傳送 `hello`
3. Bot 回覆 `收到：hello`

## 8. 常見問題整理

### 8.1 `WEBHOOK_URL` 沒設或設錯

後果：

- webhook 指向 localhost
- Telegram 無法打進來

處理方式：

- 確認 `WEBHOOK_URL` 使用的是 ngrok 提供的 HTTPS URL

### 8.2 ngrok 關掉後 webhook 失效

原因：

- ngrok tunnel 中斷後，原本公開網址失效

處理方式：

- 重新啟動 ngrok
- 若網址改變，需同步更新 n8n 的 `WEBHOOK_URL`

### 8.3 沒有按 `Execute` / `Listen`，測試 webhook 沒反應

測試模式下，workflow 需進入監聽狀態才會接收 webhook。

正式環境則應改為：

```text
Workflow → Active
```

### 8.4 n8n 出現 footer

n8n 官方文件確實有這個 footer 選項，送出訊息時可能看到：

```text
This message was sent automatically with n8n
```

這個 footer 不是由 `Parse Mode` 控制。正確做法是在 Telegram `Send Message` 節點的附加選項中，將 `Append n8n Attribution` 關閉。

如果你要完全自行控制訊息內容，改用 `HTTP Request` 直接呼叫 Telegram API 也可以，但不是移除 footer 的必要條件。

## 9. systemd 自動啟動思路

如果要做到開機後自動恢復服務，可將 ngrok 與 webhook 更新流程交給 systemd。

### 9.1 `ngrok.service`

```ini
[Unit]
Description=ngrok tunnel
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=<USER>
ExecStart=/usr/bin/ngrok http 5678
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

這裡使用 `network-online.target` 的原因是 ngrok 需要在網路真的可用後才成功建立 tunnel。

如果你的 ngrok 不是用 apt 安裝，而是手動放在其他路徑，請先用 `which ngrok` 確認實際路徑，再調整 `ExecStart`。

### 9.2 自動更新 n8n `WEBHOOK_URL` 的概念

原筆記指出的核心問題是：

```text
ngrok URL 每次開機可能改變
→ webhook 失效
```

解法是做一支更新腳本：

```text
抓 ngrok URL
→ 比對舊 URL
→ 若不同則重建 n8n
```

筆記中的 `.env` 參考內容：

```dotenv
N8N_CONTAINER_NAME=n8n
N8N_IMAGE=docker.n8n.io/n8nio/n8n
N8N_PORT=5678
N8N_DATA_DIR=/home/<USER>/.n8n

GENERIC_TIMEZONE=Asia/Taipei
TZ=Asia/Taipei
N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true
N8N_RUNNERS_ENABLED=true
N8N_PROXY_HOPS=1

# 如果 UI 是走純 HTTP，再改成 false
N8N_SECURE_COOKIE=true

NGROK_API_URL=http://127.0.0.1:4040/api/tunnels
WEBHOOK_URL_STATE_FILE=/home/<USER>/.n8n/current_webhook_url
```

### 9.3 更新腳本搭配的 systemd service

```ini
[Unit]
After=network-online.target docker.service ngrok.service
Wants=network-online.target docker.service ngrok.service
Requires=docker.service ngrok.service

[Service]
Type=oneshot
ExecStart=/home/<USER>/n8n-stack/update-n8n-webhook.sh
```

### 9.4 開機後完整流程

```text
開機
→ network-online
→ ngrok
→ docker
→ update script
→ n8n 重建
→ webhook 正常
```

## 10. 檢查指令

### 10.1 查 ngrok 對外網址

```bash
curl -s http://127.0.0.1:4040/api/tunnels | grep -o 'https://[^"]*'
```

### 10.2 查 n8n 目前使用的 `WEBHOOK_URL`

```bash
docker inspect n8n | grep WEBHOOK_URL
```

### 10.3 看 ngrok log

```bash
journalctl -u ngrok -f
```

### 10.4 看 n8n log

```bash
docker logs -f n8n
```

## 11. 建議的最小部署版本

如果目前只求先跑起來，建議採用這個最小版本：

1. 安裝 Docker；正式環境優先用官方 apt repository，快速測試可用官方便利腳本
2. 建立 `~/.n8n` 並修正權限
3. 啟動 ngrok，取得公開 HTTPS URL
4. 用 `WEBHOOK_URL=<ngrok URL>` 與 `N8N_PROXY_HOPS=1` 啟動 n8n 容器
5. 首次進入 UI 時建立 n8n owner 帳號
6. 在 n8n 建立 Telegram Trigger → Telegram Send Message
7. 如果不想要 footer，關閉 `Append n8n Attribution`
8. 測試成功後把 workflow 設為 `Active`

## 12. 一句總結

這套部署方法的核心不是單純把 n8n 跑起來，而是讓：

```text
Docker 負責容器化
→ n8n 負責 workflow
→ ngrok 提供公開 HTTPS webhook
→ Telegram 能即時把事件送進你的流程
```

如果後續要升級，下一步就是把：

- `ngrok.service`
- `update-n8n-webhook.sh`
- n8n container 啟動參數

整合成可重開機自動修復的完整 stack。
