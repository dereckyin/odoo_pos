#!/usr/bin/env bash
# 改由 nginx（9088）提供 /readme/ 時，從 Caddy 移除獨立靜態區塊
set -euo pipefail
CFG=/etc/caddy/Caddyfile
if ! grep -q 'handle_path /readme' "$CFG"; then
  echo "No readme block in Caddy — nothing to do."
  exit 0
fi
sudo cp "$CFG" "${CFG}.bak.$(date +%s)"
sudo awk '
  /handle_path \/readme\* \{/ { skip=1; next }
  skip && /^\t\}/ { skip=0; next }
  !skip { print }
' "$CFG" | sudo tee "${CFG}.new" >/dev/null
sudo mv "${CFG}.new" "$CFG"
sudo caddy validate --config "$CFG"
sudo systemctl reload caddy
echo "Removed Caddy /readme block; use nginx on :9088 instead."
