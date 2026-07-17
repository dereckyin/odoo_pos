from pathlib import Path
import time

p = Path("/etc/caddy/Caddyfile")
text = p.read_text(encoding="utf-8")
if "handle_path /shopping" in text:
    print("Caddy already has /shopping")
else:
    needle = (
        "\thandle_path /market* {\n"
        "\t\treverse_proxy http://127.0.0.1:9090\n"
        "\t\tencode gzip\n"
        "\t}\n"
    )
    insert = needle + (
        "\thandle_path /shopping* {\n"
        "\t\treverse_proxy http://127.0.0.1:9092\n"
        "\t\tencode gzip\n"
        "\t}\n"
    )
    if needle not in text:
        raise SystemExit("market block not found; abort Caddy patch")
    bak = p.with_suffix(f".bak.{int(time.time())}")
    bak.write_text(text, encoding="utf-8")
    p.write_text(text.replace(needle, insert, 1), encoding="utf-8")
    print(f"Caddyfile patched with /shopping; backup={bak}")
