SELECT u.username, u.role, u.is_active::text, COALESCE(s.code, '-') AS store_code
FROM users u
JOIN tenants t ON t.id = u.tenant_id
LEFT JOIN stores s ON s.id = u.store_id
WHERE t.code = 'ohmygod'
ORDER BY u.username;

SELECT s.code AS store_code, s.name
FROM stores s
JOIN tenants t ON t.id = s.tenant_id
WHERE t.code = 'ohmygod';

SELECT term.code AS terminal_code
FROM terminals term
JOIN stores s ON s.id = term.store_id
JOIN tenants t ON t.id = s.tenant_id
WHERE t.code = 'ohmygod';
