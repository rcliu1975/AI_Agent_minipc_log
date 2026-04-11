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
