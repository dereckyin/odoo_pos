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

- `/?t=<public_token>` — landing on a table redirects to `/order`
- `/order?t=<public_token>` — menu
- `/cart?t=<public_token>` — cart + submit
- `/status/:orderId?t=<public_token>` — status polling
- `/no-token` — when no `t=` is given (defensive)

The QR code printed in the admin (`apps/admin`) encodes
`${VITE_CUSTOMER_BASE_URL}/order?t=<public_token>`.

## Build

```bash
npm run build
```

Output goes to `dist/` and can be served by any static host or behind the
same domain as the API (recommended in production).
