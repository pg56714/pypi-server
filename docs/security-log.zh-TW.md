# 安全性紀錄

[English](security-log.md) | 繁體中文

- 日期: 2026-10-25
- 分支: `fix/security-upgrades`
- 範圍: `Dockerfile`、`entrypoint.sh`、`compose.yaml`、`requirements.txt`、部署腳本

## 摘要

移除提交進 repo 的明碼密碼檔，帳密改由環境變數提供，容器啟動時才以 bcrypt 雜湊。映像固定版本，以非 root 身分、唯讀根目錄執行，並從含雜湊的 requirements 安裝 pypiserver。套件的存放方式有變，既有部署需要做一次搬移。

## 修改內容

| 項目 | 修改前 | 修改後 | 原因 |
|---|---|---|---|
| `pypi_password.txt` | `ooo:ooo` (plain text, committed) | removed | 帳密不應存放在 repo 中 |
| Credentials | file baked into the image | `PYPI_USERNAME` / `PYPI_PASSWORD` → bcrypt `/tmp/htpasswd` at startup | 映像與 repo 中都不含密碼 |
| Base image | `python:3.11` (unpinned, full) | `python:3.13.17-slim-trixie` | 較小且可重現的映像 |
| pypiserver install | `pip install pypiserver[passlib]` (unpinned) | uv, `requirements.txt` with hashes (pypiserver 2.4.2, bcrypt <5) | 可重現且可偵測竄改；passlib 1.7.4 無法搭配 bcrypt 5 |
| Runtime | root | non-root user, read-only root filesystem, `no-new-privileges` | 降低伺服器被入侵時的影響 |
| Package storage | bind mount `~/pypi_packages` | Docker volume `packages` | 讓非 root 使用者可以寫入 |
| `deploy.sh` | `docker system prune -f` | `docker image prune -f` | 舊指令會刪除主機上其他無關的已停止容器、網路與映像 |

## 使用前須知

- 執行 `./deploy.sh` 前，請把 `.env.example` 複製成 `.env`，並設定 `PYPI_USERNAME`、`PYPI_PASSWORD`。
- 從舊的 `~/pypi_packages` 搬移套件：先執行一次 `./deploy.sh`（會建立 `pypi-server_packages` volume），再執行 `docker run --rm -v ~/pypi_packages:/src:ro -v pypi-server_packages:/dst alpine sh -c 'cp -a /src/. /dst/ && chown -R 10001:10001 /dst'`，最後執行 `./restart.sh`。
- 舊密碼 `ooo:ooo` 仍留在 Git 歷史中，請勿再使用。
- 若伺服器可從其他機器連線，請放在 HTTPS 之後，否則密碼會以明碼傳送。

## 尚未解決的問題

固定版本的 requirements 中沒有已知的未解決漏洞。

## 驗證方式

- 在 Docker 外測試：未設定帳密時 entrypoint 會拒絕啟動，並會寫出權限 0600 的 bcrypt htpasswd。
- pypi-server 會拒絕密碼錯誤的上傳，接受密碼正確的 `uv publish --index`，`uv add` 能透過 `[tool.uv.sources]` 安裝套件。
- `docker compose config` 驗證通過。

## 未驗證項目

- 實際建置與執行 Docker 映像（測試環境沒有 Docker daemon）。
- 上述的套件搬移指令。
