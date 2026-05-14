# 部署到 shelf.taaze.tw（點餐趣）

本文件假設：**主機已安裝 Docker Engine + Docker Compose plugin**，且 **`shelf.taaze.tw` 的 DNS（A/AAAA）已指向該主機**。無法從開發機代為登入你的伺服器，請在主機上依序執行下列步驟。

## 1. 取得程式碼

```bash
cd /opt   # 或你慣用的目錄
git clone <你的-repo-URL> odoo_pos
cd odoo_pos
git pull
```

## 2. 後端環境變數 `deploy/.env.api`

```bash
cp deploy/.env.api.example deploy/.env.api
```

編輯 `deploy/.env.api`，至少確認：

| 變數 | 說明 |
|------|------|
| `ENV` | `production` |
| `CORS_ORIGINS` | 必須包含瀏覽器實際開啟的來源，例如 `https://shelf.taaze.tw`（若暫時用 http 測試則一併列入）。逗號分隔、**不要**結尾 `/`。 |
| `JWT_SECRET` | 強隨機字串（≥32 字元），勿用範例預設值。 |
| `SECRETS_ENCRYPTION_KEY` | Fernet 金鑰；可用 `python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"` 產生。 |

`docker-compose.prod.yml` 會覆寫 `DATABASE_URL`、`REDIS_URL`、`ENV`、`UPLOAD_DIR`，與範例檔中同名欄位以 compose 為準。

## 3. 建置管理後台靜態檔

在**有 Node.js 20+** 的機器上（可為開發機或同一台伺服器）：

```bash
cd apps/admin
npm ci
npm run build
```

產物目錄為 `apps/admin/dist/`。`docker-compose.prod.yml` 會把此目錄掛進 Nginx 容器；若你在別台 build，請把整個 `dist/` 同步到伺服器上對應路徑。

**顧客掃碼點餐（可選）**：若要掛 `/customer/`，請依 `安裝手冊.md` 建置 `apps/customer_order_web`，並設定 `deploy/shelf.taaze.tw.caddyfile.example` 內註解的 `handle_path /customer*`。

## 4. 啟動正式用 Compose

在 repo 根目錄：

```bash
docker compose -f docker-compose.prod.yml up -d --build
```

- 後台 + 同源 API 反代：主機 **`127.0.0.1:9088`**（對外請勿直接開 9088 給公網，改由 Caddy 終止 TLS 並反代）。
- 顧客靜態（若有啟用）：`127.0.0.1:9089`。

本機自測 API 是否為本專案 FastAPI（在 API 容器內，略過 Nginx 前綴）：

```bash
docker exec pos_api_prod curl -sS http://127.0.0.1:8000/health
docker exec pos_api_prod curl -sS http://127.0.0.1:8000/readyz
```

對外瀏覽器僅能透過 **`https://shelf.taaze.tw/api/...`**（由 Nginx 轉發）；注意 FastAPI 的 `/health` 在**根路徑**，未掛在 `/api` 下，因此 **`/api/health` 可能不成立**；對外健康檢查可改為檢查首頁或只從容器內測 `/health`。

## 5. Caddy（HTTPS）反代到 9088

參考 **`deploy/shelf.taaze.tw.caddyfile.example`**，將 `shelf.taaze.tw { ... }` 合併進主機 Caddy 設定後 reload。

確認瀏覽器開啟 **`https://shelf.taaze.tw`** 能載入登入頁，且 Network 中 `POST .../api/auth/admin-login` 回應為 JSON（非空 body 的 403）以利除錯。

## 6. 資料庫種子（僅第一次或空庫）

API 容器啟動時會執行 `alembic upgrade head`。若需示範租戶，請進入 API 容器執行 seed（指令以你主機上的 container 名為準）：

```bash
docker exec -it pos_api_prod python -m app.scripts.seed
```

依終端輸出變更平台超管密碼；租戶代號預設為 `demo`。

## 7. Admin 與顧客端網址（建置時環境變數）

- 後台列印 QR 用的顧客網址：在 build `apps/admin` 前於 `.env.production` 或指令前綴設定，例如：  
  `VITE_CUSTOMER_BASE_URL=https://shelf.taaze.tw/customer`（若已掛顧客靜態）。
- 後台 API 請維持**相對路徑** `/api`（不要設 `VITE_API_BASE_URL`），以便與 Nginx 的 `location /api/` 一致。

## 8. 常見問題

- **403、回應 body 為空、Server 顯示 aiohttp**：代表請求可能沒進到本 repo 的 Uvicorn（例如被其他服務或錯誤埠佔用）。請確認 Caddy `reverse_proxy` 目標為 **`127.0.0.1:9088`**，且 `docker compose ps` 顯示 `pos_web_prod`、`pos_api_prod` 皆為 Up。
- **CORS 錯誤**：檢查 `CORS_ORIGINS` 是否包含 `https://shelf.taaze.tw`（與瀏覽器網址列完全一致，含 http/https）。
