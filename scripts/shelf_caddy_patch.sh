#!/usr/bin/env bash
set -euo pipefail
sudo cp /etc/caddy/Caddyfile "/etc/caddy/Caddyfile.bak.$(date +%s)"
sudo python3 <<'PY'
from pathlib import Path
import re

p = Path("/etc/caddy/Caddyfile")
text = p.read_text(encoding="utf-8")
old = re.compile(
    r"shelf\.taaze\.tw\s*\{[^}]*\}",
    re.MULTILINE | re.DOTALL,
)
new = """pos.myvnc.com {
    reverse_proxy http://127.0.0.1:9088
    encode gzip
}"""
text2, n = old.subn(new, text, count=1)
if n != 1:
    raise SystemExit(f"Expected 1 pos.myvnc.com block replaced, got {n}")
p.write_text(text2, encoding="utf-8")
print("Caddyfile updated.")
PY
sudo caddy validate --config /etc/caddy/Caddyfile
sudo systemctl reload caddy
echo "Caddy reloaded."
