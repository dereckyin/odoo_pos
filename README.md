# Enterprise POS System (odoo_pos)

企業級 POS 系統 monorepo：**多租戶 SaaS** 架構（申請審核制開店）、Flutter 收銀端、Vue 管理後台，以及 FastAPI + PostgreSQL + Redis 後端。

## 主要功能

- **多租戶隔離**：以 `tenant_id` 為主軸，商品／會員／訂單／同步／報表皆限於所屬租戶。
- **申請審核制**：公開申請 → Email OTP → 平台超管審核 → 自動開通租戶、預設店面與 Owner 帳號。
- **RBAC**：`platform_super`、`tenant_owner` / `tenant_admin`、`store_manager`、`cashier`、`kitchen` 等角色。
- **收銀與營運**：掃碼收銀、商品／庫存／會員／促銷、QR 桌邊點餐、訂單與報表。
- **Offline-First（POS）**：寫入先入本地佇列，背景同步雲端（依 `pos_app` 實作）。
- **金流／發票**：平台級 fallback 設定；生產環境建議於「租戶設定」中設定每租戶 Encrypted 金鑰。
- **安全強化**：終端註冊需管理員權限、POS 登入驗證 `terminal_api_key`、JWT 生產環境強制檢查、`/auth/*` 與公開端點限流。

## Repo 結構

```
apps/
  pos_app/              Flutter Desktop + Android 收銀端
  api/                  FastAPI 後端（v1 API、多租戶、平台／租戶端點）
  admin/                Vue 3 + Ant Design Vue 管理後台
  customer_order_web/   （可選）顧客點餐前端
packages/
  pos_domain/           Dart 領域模型與 repository 介面
  pos_core/             共用工具
  pos_ui_kit/           共用 UI
tools/seed/             種子資料產生器
docs/                   架構與協議文件
安裝手冊.md             環境建置與部署說明
操作手冊.md             登入、開店、POS、後台操作說明
```

## 快速開始

詳細步驟見 **[安裝手冊.md](./安裝手冊.md)**。後端環境變數完整範例與註解見 **`apps/api/.env.example`**。精簡版：

```bash
# 1. 資料庫與 Redis
docker compose up -d postgres redis

# 2. 後端
cd apps/api
python -m venv .venv
# Windows: .venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env   # 並依 安裝手冊 / .env.example 內註解調整變數
alembic upgrade head
python -m app.scripts.seed
uvicorn app.main:app --reload --port 8000
```

- API 文件：<http://localhost:8000/docs>
- 健康檢查：<http://localhost:8000/readyz>

```bash
# 3. 管理後台（另開終端）
cd apps/admin
npm install
npm run dev
# 預設 <http://localhost:5173>，/api 會 proxy 至 8000

# 4. Flutter POS（可選）
dart pub global activate melos
melos bootstrap
cd apps/pos_app
flutter run
```

日常操作（登入、開店、平台審核、POS）見 **[操作手冊.md](./操作手冊.md)**。

## 開發／測試用預設帳號（seed 後）

| 用途 | 帳號 | 密碼 | 租戶代號 | 說明 |
|------|------|------|----------|------|
| 平台超管 | `platform_super` | `platform-secret-CHANGE-ME` | 可留白 | 審核申請、租戶管理；登入後請立即改密碼 |
| 店家管理員 | `admin` | `admin123` | `demo` | 後台／租戶設定 |
| 收銀員 | `cashier` | `cashier123` | `demo` | POS 登入（需終端與 API Key） |

執行 `python -m app.scripts.seed` 後，終端機輸出會顯示 **示範 `terminal_api_key`**（請複製保存供 POS 使用）。

## 生產環境注意事項

- 必須設定強隨機 `JWT_SECRET`，且 **`ENV=production`（或 `prod`）時** 後端會拒絕使用預設弱密鑰。
- 必須設定 **Fernet 金鑰** `SECRETS_ENCRYPTION_KEY`（見 `apps/api/app/core/config.py` 註解產生方式），否則無法安全儲存各租戶金流／發票金鑰。
- 建議啟用 **Redis** 供限流與（若使用）其他快取；並設定 **CAPTCHA**、**SMTP** 以支援正式申請與寄信。

## 現有文件

- [架構](docs/architecture.md)
- [同步協議](docs/sync_protocol.md)
- [安裝手冊.md](./安裝手冊.md)
- [操作手冊.md](./操作手冊.md)

## 授權

僅作為範例專案使用。
