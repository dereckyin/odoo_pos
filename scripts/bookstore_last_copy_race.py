"""試營前在 staging（PostgreSQL）驗證「最後一本」只會被一個人鎖到。

用法（需在 BOOKSTORE_PARTNER_ALLOWED_IPS 允許的機器上執行）：
    python scripts/bookstore_last_copy_race.py \
        --base https://staging.example.com/api \
        --key <partner key 明文> \
        --door-qr "TAAZEBK1:..." \
        --store <store_id> --product <product_id> --buyers 20

事前把該商品在該店的可售庫存調成 1。預期結果：成功 1 筆，其餘 409 insufficient_stock。
跑完會把成功的那筆取消，釋放庫存。
"""
import argparse
import asyncio
import secrets
from collections import Counter

import httpx


async def buyer(client: httpx.AsyncClient, args, idx: int, start: asyncio.Event):
    ref = f"racetest_{idx:03d}_{secrets.token_hex(6)}"
    headers = {"X-Partner-Key": args.key, "X-Customer-Ref": ref}
    r = await client.post("/partner/bookstore/door-qr/resolve", json={"content": args.door_qr}, headers=headers)
    r.raise_for_status()
    presence = r.json()["presence_token"]
    body = {
        "store_id": args.store,
        "presence_token": presence,
        "client_request_id": secrets.token_hex(12),
        "lines": [{"product_id": args.product, "qty": 1}],
    }
    await start.wait()
    r = await client.post("/partner/bookstore/checkouts", json=body, headers=headers)
    detail = r.json().get("detail") if r.status_code >= 400 else None
    code = detail.get("code") if isinstance(detail, dict) else detail
    return r.status_code, code, (r.json()["id"] if r.status_code == 201 else None), headers


async def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--base", required=True)
    p.add_argument("--key", required=True)
    p.add_argument("--door-qr", required=True)
    p.add_argument("--store", required=True)
    p.add_argument("--product", required=True)
    p.add_argument("--buyers", type=int, default=20)
    args = p.parse_args()

    start = asyncio.Event()
    async with httpx.AsyncClient(base_url=args.base.rstrip("/"), timeout=30) as client:
        tasks = [asyncio.create_task(buyer(client, args, i, start)) for i in range(args.buyers)]
        await asyncio.sleep(2)
        start.set()
        results = await asyncio.gather(*tasks)

        tally = Counter((status, code) for status, code, _, _ in results)
        for (status, code), n in sorted(tally.items(), key=lambda kv: str(kv[0])):
            print(f"{status} {code or ''}: {n}")

        winners = [(cid, h) for status, _, cid, h in results if status == 201]
        for cid, headers in winners:
            await client.post(f"/partner/bookstore/checkouts/{cid}/cancel", headers=headers)

    ok = len(winners) == 1
    print("PASS：只有一人鎖到最後一本" if ok else f"FAIL：{len(winners)} 人同時鎖到")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(asyncio.run(main()))
