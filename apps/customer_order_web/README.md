# Customer Order Web (顧客掃碼點餐前端)

A small Vue 3 + Vite SPA used by customers who scan the QR Code printed on
each table. Loads a public read-only menu and submits a "guest order" that
is then accepted by the kitchen via the Flutter POS KDS mode and finally
paid for **at the counter** (this app intentionally has no payment flow).

## Quick start

```bash
cd apps/customer_order_web
npm install
npm run dev   # http://localhost:5174
```

The app expects a backend reachable at `/api`. By default the dev server
proxies `/api` to `http://localhost:8000`. For non-default backends, set
`VITE_API_BASE` in `.env`.

## Routing

- `/?t=<public_token>` — 會 **帶著 t 一併** 導向 `/order?t=...`（勿用會丟失 query 的硬轉址）
- `/order?t=<public_token>` — 菜單
- `/cart?t=<public_token>` — cart + submit
- `/status/:orderId?t=<public_token>` — status polling
- `/no-token` — when no `t=` is given (defensive)

The QR code printed in the admin (`apps/admin`) encodes
`${VITE_CUSTOMER_BASE_URL}/order?t=<public_token>`.

## Build

```bash
npm run build
```

- **開發**：`npm run dev`，`base` 為 `/`，路由如 `http://localhost:5174/order?t=…`
- **正式**：`vite build` 的 `base` 為 **`/customer/`**（與管理後台同網域時必用，避免兩套 SPA 搶根路徑）
- 產出 `dist/` 可交 Caddy `file_server`，掛在 **`https://你的網域/customer/`**。Caddy 設定片段見 repo **`deploy/caddy-pos-snippet.caddyfile`**。
- 與 API 同網域時建議建置前設 **`VITE_API_BASE=https://你的網域/api`**，並確認後端 **`CORS_ORIGINS`** 含你的網域。

後台 QR 的基底網址請設 **`https://你的網域/customer`**（不要尾隨 `/`），列印網址為  
`https://你的網域/customer/order?t=<public_token>`。

**不要**在正式環境把瀏覽器指到 Vite 的 **5174**；5174 僅本機開發用。
