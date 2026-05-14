# 採購模組範圍（已定案）

## 本階段（MVP）已實作

- **供應商主檔**（`suppliers`）：租戶內代號唯一、聯絡資訊與備註。
- **採購單**（`purchase_orders` + `purchase_order_lines`）：草稿 → 已下單 → 依收貨產生 **部分入庫／全數入庫** 狀態。
- **收貨入庫**：每次收貨寫入 `inventory_movements`（`reason=receive`，`ref_type=purchase_order`，`ref_id` 指向採購單），並更新 `inventory_levels`（與現有調撥／手動異動一致）。
- **權限**：僅 **店長以上**（`StoreAdminDep`：店長、租戶管理員等）可維護供應商與採購／收貨。
- **稽核**：建立／狀態變更／收貨寫入 `audit_log`。

## 刻意延後（非本階段）

- **請購單（PR）**、多層簽核、總部彙總採購。
- **供應商對帳／發票三單匹配**、付款條件與應付帳款總帳串接。
- **價格履約／合約價**、多幣別、稅別細拆（僅備註欄可人工記錄）。
- **門市 POS 離線收貨**：收貨僅在 **Admin Web** 操作；不擴充 `sync_queue` 採購單型別（見 `docs/sync_protocol.md` 補充說明）。

## 後續可擴充方向

若未來要在門市平板收貨：需新增 sync 上傳 op、POS UI、與收貨 idempotency 鍵；仍建議最終落同一套 `InventoryMovement`。
