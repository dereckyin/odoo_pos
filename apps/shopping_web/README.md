# Shopping Web（統一點餐／消費者入口）

獨立於 `/market` 的單店點餐 SPA：內用／外帶／外送三合一，UI 依 `餐飲點餐前端` 交接稿。

**不做**：取代 marketplace、WebUSB 列印、LINE LIFF／金流 SDK（付款與發票區塊為示意；真實建單走 marketplace API）。

## Quick start

```bash
cd apps/shopping_web
npm install
npm run dev   # http://localhost:5176
```

- 無 `store`：示範菜單（食光麵舖），可走完整流程、不下真實單  
- 有畫面參數：`?store=<marketplace-slug>&mode=takeout`  
- 內用：`?store=<slug>&mode=dinein&table=A5`

開發伺服器將 `/api` 代理到 `http://localhost:8000`。可設 `VITE_API_BASE`。

## 路由

| 路徑 | 說明 |
|---|---|
| `/` | 菜單 |
| `/cart` | 購物車 |
| `/checkout` | 結帳 |
| `/done` | 完成 |

正式建置 `base=/shopping/`，對外網址例如：

- `https://你的網域/shopping/?store=xxx&mode=takeout`
- `https://你的網域/shopping/?store=xxx&mode=dinein&table=A5`

## Build / Deploy

```bash
npm run build
```

產出 `dist/`。正式環境由 Docker `shopping_web`（埠 `127.0.0.1:9092`）提供，Caddy：

```
handle_path /shopping* {
    reverse_proxy http://127.0.0.1:9092
    encode gzip
}
```

關閉入口模擬器：建置前設 `VITE_SHOW_ENTRY_SIMULATOR=0`。
