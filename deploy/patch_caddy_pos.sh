#!/usr/bin/env bash
set -euo pipefail
CFG=/etc/caddy/Caddyfile
if grep -q 'handle_path /pos' "$CFG"; then
  echo "pos route already configured"
  exit 0
fi
sudo cp "$CFG" "${CFG}.bak.$(date +%s)"
sudo python3 <<'PY'
from pathlib import Path
p = Path("/etc/caddy/Caddyfile")
text = p.read_text()
block = (
    "\thandle_path /pos* {\n"
    "\t\treverse_proxy http://127.0.0.1:9091\n"
    "\t\tencode gzip\n"
    "\t}\n"
)
if "handle_path /pos" in text:
    raise SystemExit(0)
needle = "\thandle {\n"
if needle not in text:
    raise SystemExit("could not find default handle block")
text = text.replace(needle, block + needle, 1)
p.write_text(text)
print("patched")
PY
sudo caddy validate --config "$CFG"
sudo systemctl reload caddy
echo "Caddy reloaded with /pos route."
