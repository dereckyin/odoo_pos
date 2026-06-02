-- UTF-8 only data repair script for tenant: ohmygod
-- Usage (on server):
--   psql -U pos -d pos -f /tmp/ohmygod_utf8_fix.sql

-- 1) Fix category names if they were corrupted into question marks.
UPDATE categories
SET name = '飲料'
WHERE tenant_id = (SELECT id FROM tenants WHERE code = 'ohmygod')
  AND deleted_at IS NULL
  AND name = '??';

UPDATE categories
SET name = '便當/熟食'
WHERE tenant_id = (SELECT id FROM tenants WHERE code = 'ohmygod')
  AND deleted_at IS NULL
  AND name = '??/??';

UPDATE categories
SET name = '生活用品'
WHERE tenant_id = (SELECT id FROM tenants WHERE code = 'ohmygod')
  AND deleted_at IS NULL
  AND name = '????';

-- 2) Fix product names by SKU.
UPDATE products SET name = '可口可樂 350ml' WHERE tenant_id = (SELECT id FROM tenants WHERE code = 'ohmygod') AND sku = '4710001000017' AND deleted_at IS NULL;
UPDATE products SET name = '雪碧 350ml'     WHERE tenant_id = (SELECT id FROM tenants WHERE code = 'ohmygod') AND sku = '4710001000024' AND deleted_at IS NULL;
UPDATE products SET name = '礦泉水 600ml'   WHERE tenant_id = (SELECT id FROM tenants WHERE code = 'ohmygod') AND sku = '4710001000031' AND deleted_at IS NULL;
UPDATE products SET name = '舒跑 350ml'     WHERE tenant_id = (SELECT id FROM tenants WHERE code = 'ohmygod') AND sku = '4710001000048' AND deleted_at IS NULL;
UPDATE products SET name = '樂事洋芋片'     WHERE tenant_id = (SELECT id FROM tenants WHERE code = 'ohmygod') AND sku = '4710002000016' AND deleted_at IS NULL;
UPDATE products SET name = '波卡洋芋片'     WHERE tenant_id = (SELECT id FROM tenants WHERE code = 'ohmygod') AND sku = '4710002000023' AND deleted_at IS NULL;
UPDATE products SET name = '義美夾心酥'     WHERE tenant_id = (SELECT id FROM tenants WHERE code = 'ohmygod') AND sku = '4710002000030' AND deleted_at IS NULL;
UPDATE products SET name = '御便當-雞腿'    WHERE tenant_id = (SELECT id FROM tenants WHERE code = 'ohmygod') AND sku = '4710003000015' AND deleted_at IS NULL;
UPDATE products SET name = '御便當-排骨'    WHERE tenant_id = (SELECT id FROM tenants WHERE code = 'ohmygod') AND sku = '4710003000022' AND deleted_at IS NULL;
UPDATE products SET name = '三角飯糰'       WHERE tenant_id = (SELECT id FROM tenants WHERE code = 'ohmygod') AND sku = '4710003000039' AND deleted_at IS NULL;
UPDATE products SET name = '舒潔面紙'       WHERE tenant_id = (SELECT id FROM tenants WHERE code = 'ohmygod') AND sku = '4710004000014' AND deleted_at IS NULL;
UPDATE products SET name = '盤尼西林牙膏'   WHERE tenant_id = (SELECT id FROM tenants WHERE code = 'ohmygod') AND sku = '4710004000021' AND deleted_at IS NULL;
UPDATE products SET name = '台啤經典 350ml' WHERE tenant_id = (SELECT id FROM tenants WHERE code = 'ohmygod') AND sku = '4710005000013' AND deleted_at IS NULL;
UPDATE products SET name = '黑松沙士 600ml' WHERE tenant_id = (SELECT id FROM tenants WHERE code = 'ohmygod') AND sku = '4710005000020' AND deleted_at IS NULL;
UPDATE products SET name = '茶葉蛋'         WHERE tenant_id = (SELECT id FROM tenants WHERE code = 'ohmygod') AND sku = '4710006000012' AND deleted_at IS NULL;

-- 3) Fix units.
UPDATE products
SET unit = '個'
WHERE tenant_id = (SELECT id FROM tenants WHERE code = 'ohmygod')
  AND deleted_at IS NULL
  AND sku <> '4710001000017';

UPDATE products
SET unit = '杯'
WHERE tenant_id = (SELECT id FROM tenants WHERE code = 'ohmygod')
  AND deleted_at IS NULL
  AND sku = '4710001000017';

-- 4) Verification output.
SELECT sku, name, unit
FROM products
WHERE tenant_id = (SELECT id FROM tenants WHERE code = 'ohmygod')
  AND deleted_at IS NULL
ORDER BY sku;
