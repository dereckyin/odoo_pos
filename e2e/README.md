# Playwright E2E（demo 店 · pos.myvnc.com）

針對生產環境 **demo** 租戶的瀏覽器端對端測試，涵蓋：

- 網頁收銀 [`/pos`](/pos)
- 桌邊 QR 全流程（`/customer` + KDS）
- 管理後台權限（`/`）
- 商品 CRUD（新增／編輯／上下架／刪除）
- CSV 匯入、分類指派、新建商品 POS 可見性

## 快速開始

```bash
cd e2e
cp .env.example .env
# 編輯 .env，填入 POS_TERMINAL_API_KEY
npm install
npx playwright install chromium
npm test
```

## 環境變數

| 變數 | 說明 |
|------|------|
| `BASE_URL` | 預設 `https://pos.myvnc.com` |
| `POS_TERMINAL_API_KEY` | demo / S001 / T01 終端金鑰（**必填**） |
| `POS_CASHIER_PASSWORD` | 預設 `cashier123` |
| `ADMIN_PASSWORD` | 預設 `admin123` |

未設定 `POS_TERMINAL_API_KEY` 時，POS 相關案例會自動 `skip`。

## 指令

```bash
npm run test:pos      # 僅 /pos
npm run test:qr       # QR 全流程 + 商品 POS 可見性
npm run test:admin    # 管理後台（含 ADM-05~08 商品 CRUD）
npm run report        # 開啟 HTML 報告
```

## GitHub Actions

手動觸發 workflow **e2e-smoke**，需在 repo Secrets 設定：

- `POS_TERMINAL_API_KEY`
- `POS_CASHIER_PASSWORD`（若已改密碼）
- `ADMIN_PASSWORD`（若已改密碼）

QR 全流程與開桌測試預設不在 CI smoke 內（避免污染 demo 資料），可本機執行 `npm run test:qr`。

## 注意事項

- 結帳測試**不開立電子發票**，避免觸發外部金流。
- 測試會在 demo 店建立真實訂單／桌次，建議定期於後台清理。
- 並行度設為 `workers: 1`，避免多測試搶同一班次。
