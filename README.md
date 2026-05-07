# Enterprise POS System (odoo_pos)

企業級 POS 系統 monorepo - Flutter Desktop + Android 收銀端，搭配 FastAPI + PostgreSQL 範例後端。

## Features

- **5 大模組**：收銀 / 商品 / 庫存 / 會員 / 行銷優惠引擎
- **Clean Architecture**：domain / data / presentation 分層，每個 feature 獨立
- **Offline-First**：所有寫入先入本地 SQLite，背景 Queue 同步至雲端
- **多店多機**：`store_id + terminal_id`，事件源 (movement-sourced) 庫存
- **真實整合介面**：LINE Pay / 信用卡 (NewebPay / ECPay) / 台灣電子發票
- **觸控友善 UI**：Material 3 + 深色模式 + 大按鈕 + 客顯子視窗
- **ESC/POS**：TCP 9100 / USB / 藍牙印表機抽象層
- **Barcode**：Android (mobile_scanner) + Desktop (HID keyboard wedge)

## Repo 結構

```
apps/
  pos_app/        Flutter Desktop + Android 應用
  api/            FastAPI 後端範例
packages/
  pos_domain/     Pure Dart 領域模型 / 介面
  pos_core/       共用工具 (errors, result, logger)
  pos_ui_kit/     共用 UI 元件
tools/seed/       種子資料產生器
docs/             架構與同步協議文件
```

## 開發環境

### 後端 (FastAPI)

```bash
docker compose up -d postgres redis
cd apps/api
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
alembic upgrade head
python -m app.scripts.seed   # 載入示範資料
uvicorn app.main:app --reload --port 8000
```

API 文件：http://localhost:8000/docs

### 前端 (Flutter)

```bash
dart pub global activate melos
melos bootstrap

cd apps/pos_app
flutter run -d macos       # 或 windows / linux / android
```

預設後端 URL 在 `apps/pos_app/lib/config/env.dart`，可被環境變數覆蓋。

## 預設帳號 (seed)

| 帳號     | 密碼      | 角色   |
| -------- | --------- | ------ |
| `admin`  | `admin123`| 管理員 |
| `cashier`| `cashier123` | 收銀員 |

## 文件

- [架構](docs/architecture.md)
- [同步協議](docs/sync_protocol.md)
- [API OpenAPI](docs/api_openapi.yaml)（後端啟動後 export）

## 授權

僅作為範例專案使用。
