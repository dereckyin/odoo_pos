#!/usr/bin/env bash
set -euo pipefail
CFG=/etc/caddy/Caddyfile
if grep -q 'handle_path /readme' "$CFG"; then
  echo "readme route already configured"
  exit 0
fi
sudo cp "$CFG" "${CFG}.bak.$(date +%s)"
sudo awk '
  /pos\.myvnc\.com \{/ {
    print
    print "\thandle_path /readme* {"
    print "\t\troot * /var/www/pos-readme"
    print "\t\tfile_server"
    print "\t}"
    next
  }
  { print }
' "$CFG" | sudo tee "${CFG}.new" >/dev/null
sudo mv "${CFG}.new" "$CFG"
sudo caddy validate --config "$CFG"
sudo systemctl reload caddy
echo "Caddy reloaded with /readme static site."
