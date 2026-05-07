# Sync Protocol

## Goals

- Tolerate intermittent connectivity at the POS terminal.
- Never lose a sale, refund, or inventory movement.
- Resolve concurrent edits deterministically.

## Storage

- Local: SQLite via [drift](https://pub.dev/packages/drift).
- Remote: PostgreSQL via FastAPI.

## Identifiers

- All entity primary keys are **uuid v7** generated client-side.
- That makes inserts idempotent and naturally chronological.

## Write Path

Every write that needs to reach the server:

1. Begin a single drift transaction.
2. Insert/update the entity in its main table.
3. Insert a row into `sync_queue` (`op`, `payload_json`, `created_at`).
4. Commit.

The UI only depends on local data, so the cashier sees the result immediately.

## Sync Worker

A long-running worker (a dedicated isolate on Desktop, `flutter_background_service` + `workmanager` on Android) wakes on:

- App foreground.
- Connectivity change to "online" (`connectivity_plus`).
- Timer (every 30s while idle, 5s while pending > 0).

For each pending entry, in FIFO order:

```
GET /sync/health   (cheap probe with auth)
POST /sync/<endpoint>  with payload + Idempotency-Key: queue.id
```

On success:

- The server returns canonical fields (eg. `invoice_number` after issuing an invoice).
- The client patches the local row + sets `synced_at`.
- The queue entry is deleted.

On failure:

- Network → exponential backoff (1s, 5s, 30s, 5m, 30m, 1h max).
- 4xx with `idempotent=true` (eg. 409 Conflict for already-uploaded order) → mark queue entry as resolved.
- 4xx otherwise → mark `lastError` and surface to the diagnostic page; entry stays.
- 5xx → backoff.

## Read Path (delta pull)

Read-mostly entities (products, categories, members, promotions, inventory levels) are pulled with `?since=<iso8601>`:

```
GET /sync/products?since=2026-05-01T03:00:00Z&limit=500
```

Server returns rows where `updated_at > since` (including soft deletes via `deleted_at`). The client:

1. Upserts each row into local tables.
2. Updates `kv_meta('last_sync_<entity>')`.

## Conflict Resolution

- **Last-Write-Wins by `updated_at`** for product / category / member master data. Server stamps `updated_at` on every accepted upsert.
- **Append-only** for `inventory_movements`. The server reduces movements to canonical `inventories.on_hand` after each push.
- **Server-authoritative** for `orders`, `invoices`, `payments` once accepted; the POS may not edit a synced order.

## Clock

POS terminals do not trust their local wall clock for ordering. They:

- Emit `client_created_at` on every payload (informational).
- Use `Stopwatch`/monotonic time to order events within a session.
- The server stamps the canonical `created_at` for cross-terminal ordering.

## Idempotency

Every queue entry sends `Idempotency-Key: <queue_uuid>`. The server's middleware caches the response for 24h so retries return the same result.
