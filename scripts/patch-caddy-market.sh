#!/usr/bin/env bash
set -euo pipefail
sudo cp /etc/caddy/Caddyfile "/etc/caddy/Caddyfile.bak.$(date +%s)"
sudo python3 <<'PY'
from pathlib import Path
import re

block = """pos.myvnc.com {
\thandle_path /customer* {
\t\treverse_proxy http://127.0.0.1:9089
\t\tencode gzip
\t}
\thandle_path /market* {
\t\treverse_proxy http://127.0.0.1:9090
\t\tencode gzip
\t}
\thandle_path /shopping* {
\t\treverse_proxy http://127.0.0.1:9092
\t\tencode gzip
\t}
\thandle {
\t\treverse_proxy http://127.0.0.1:9088
\t\tencode gzip
\t}
}"""
p = Path("/etc/caddy/Caddyfile")
text = p.read_text(encoding="utf-8")
pat = re.compile(r"pos\.myvnc\.com\s*\{.*?\n\}", re.DOTALL)
text2, n = pat.subn(block, text, count=1)
if n != 1:
    raise SystemExit(f"Expected 1 pos.myvnc.com block replaced, got {n}")
p.write_text(text2, encoding="utf-8")
print("Caddyfile updated.")
PY
sudo caddy validate --config /etc/caddy/Caddyfile
sudo systemctl reload caddy
echo "Caddy reloaded."
