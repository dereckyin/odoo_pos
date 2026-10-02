# 實體書店（讀冊 App 自助結帳）台南大遠百試營檢查表

架構：讀冊 App → my_api `/api/v1/bookstore/*`（驗會員 JWT、換成 customer_ref）→ 點餐趣 `/partner/bookstore/*`（庫存、計價、訂單、金流、發票）。
金流回呼直接打點餐趣 `/public/bookstore/payments/ecpay/notify`。

## 1. 環境設定

### 點餐趣 `apps/api/.env`

| 變數 | 說明 |
|---|---|
| `BOOKSTORE_PARTNER_TENANT_CODE` | 書店租戶代碼 |
| `BOOKSTORE_PARTNER_KEY_SHA256` | partner key 的 SHA-256（只放雜湊；逗號分隔可輪替） |
| `BOOKSTORE_PARTNER_ALLOWED_IPS` | my_api 對外 IP/CIDR（正式環境必填） |
| `BOOKSTORE_SIGNING_SECRET` | ≥ 32 字元隨機字串 |
| `BOOKSTORE_PUBLIC_BASE_URL` | 付款頁與金流回呼的對外網址 |
| `BOOKSTORE_RETURN_URL_PREFIXES` | 允許的付款完成導回網址前綴 |

產生金鑰：`python -c "import hashlib,secrets;k=secrets.token_urlsafe(32);print(k);print(hashlib.sha256(k.encode()).hexdigest())"`
明文給 my_api，雜湊給點餐趣。

### my_api `.env`

| 變數 | 說明 |
|---|---|
| `BOOKSTORE_ENABLED=true` | 開關 |
| `BOOKSTORE_POS_BASE_URL` | 點餐趣 API 網址 |
| `BOOKSTORE_PARTNER_KEY` | 上面的明文 key |
| `BOOKSTORE_CUSTOMER_REF_SECRET` | ≥ 32 字元；**上線後不可更換**（換了舊訂單會查不到） |
| `BOOKSTORE_PAYMENT_RETURN_URL` | 選填，須符合點餐趣的 prefix 白名單 |

## 2. 後台設定

- [ ] 平台管理 → 租戶 → 開啟「實體書店」模組
- [ ] 門店 → 新增「台南大遠百店」，門店類型選「實體書店」
- [ ] 門店列表 →「門口 QR」→ 列印貼在入口與櫃檯（遺失或外流就按「重新產生」，舊 QR 立即失效）
- [ ] 金流設定填入綠界（先用 stage 帳號），電子發票設定填入（ECPay 或 ezPay）
- [ ] 店員帳號可進「實體書店核銷」頁

## 3. 入庫

- [ ] 用寄賣入庫／商品管理建立書籍，ISBN 與書背條碼都要有（掃碼靠 `ProductBarcode`／`BookDetail.barcode`／ISBN）
- [ ] 該店 `InventoryLevel.on_hand` 正確
- [ ] App 選店可看到書、分類、庫存標籤（店內有書／最後一本／已售完）

## 4. 沙箱金流與發票

- [ ] App：掃門口 QR → 掃書 → 結帳 → 付款頁（綠界 stage 測試卡 4311-9522-2222-2222）
- [ ] 回到 App 自動跳「出門憑證」，庫存扣 1，點餐趣有一張訂單（備註「讀冊 App 實體書店」）
- [ ] 電子發票開立成功（手機條碼／統編／捐贈各一次）
- [ ] 店員在「實體書店核銷」掃 QR 或輸入 6 碼 → 有效；再掃一次 → 已使用

## 5. 資安驗證

自動化測試（`apps/api/tests/test_bookstore.py`、my_api `tests/test_bookstore_proxy.py`）已涵蓋，試營前在 staging 再跑一次：

| 情境 | 預期 | 驗證方式 |
|---|---|---|
| 同時搶最後一本 | 只有 1 人成功，其餘 409 | `python scripts/bookstore_last_copy_race.py ...`（PostgreSQL） |
| 竄改價格／總額 | 伺服器忽略，照店內價格計算 | 自動化測試 + 手動改封包 |
| 讀別人的結帳 | 404 | 自動化測試 |
| 沒掃門口 QR 就結帳 | 403 presence_required | 自動化測試 |
| 金流通知竄改／金額不符／重送 | 拒絕或只處理一次 | 自動化測試 |
| 付款後導回惡意網址 | 400 | 自動化測試（my_api 也固定 return_url） |
| 出門憑證重複使用／截圖 | 第二次「已使用」；畫面有即時時鐘與跳動點 | 自動化測試 + 店員訓練 |
| 錯誤 partner key／非白名單 IP | 401／403；App 端只看到「暫時無法使用」 | 自動化測試 |
| 5 分鐘未付款 | 庫存自動釋放 | 自動化測試 |

## 6. 退貨

- [ ] 店長在「實體書店核銷」→ 退貨：庫存回補、訂單轉已退貨、發票作廢
- [ ] **信用卡退刷目前需到綠界廠商後台手動辦理**（系統會提示）
- [ ] 顧客 App 購買紀錄顯示「已退貨」

## 7. 正式上線前

- [ ] 綠界、發票切正式帳號；確認 `SimulatePaid` 不會被接受
- [ ] `BOOKSTORE_PARTNER_ALLOWED_IPS` 只留 my_api 正式 IP
- [ ] 兩邊金鑰與 secret 都不進版控，並記錄輪替程序
- [ ] 確認合約允許自有收銀、金流與發票開立主體（業務處理）

## 已知限制

- 點餐趣 Flutter POS 尚無出門核銷畫面，先用後台網頁（平板／手機瀏覽器）
- 不做 NFC、出口閘門、顧客自助退貨，也不回拋銷售資料給遠百 POS
