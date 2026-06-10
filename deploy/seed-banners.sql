INSERT INTO marketplace_banners (id, title, subtitle, image_url, link_type, link_target, sort_order, is_active)
VALUES
  (gen_random_uuid()::text, '新會員首單 9 折', '註冊登入立即享受專屬優惠', '/uploads/_platform/banner-welcome.png', 'none', NULL, 1, true),
  (gen_random_uuid()::text, '假日外送免運費', '週末點餐免外送費，吃好料更划算', '/uploads/_platform/banner-delivery.png', 'none', NULL, 2, true),
  (gen_random_uuid()::text, '人氣美食市集開幕', '集結各店招牌料理，一次品嚐', '/uploads/_platform/banner-opening.png', 'none', NULL, 3, true);
