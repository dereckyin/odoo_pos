"""CSV batch inbound for consignment books."""
from __future__ import annotations

import csv
from dataclasses import dataclass, field
from io import StringIO

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..models import Store
from .book_lookup import BookLookupNotFoundError, UnsupportedBarcodeError
from .book_receive import receive_book_by_barcode

IMPORT_CSV_COLUMNS = ["barcode", "qty", "store_id", "store_code"]

IMPORT_CSV_SAMPLE_ROWS = [
    {"barcode": "11101042331", "qty": "1", "store_id": "", "store_code": "main"},
    {"barcode": "12345678", "qty": "2", "store_id": "", "store_code": "main"},
]


@dataclass
class BookImportRowError:
    row: int
    barcode: str
    message: str


@dataclass
class BookImportResult:
    received: int = 0
    skipped: int = 0
    errors: list[BookImportRowError] = field(default_factory=list)

    def to_dict(self) -> dict:
        return {
            "received": self.received,
            "skipped": self.skipped,
            "errors": [
                {"row": e.row, "barcode": e.barcode, "message": e.message}
                for e in self.errors
            ],
        }


def render_book_import_template_csv() -> str:
    buf = StringIO()
    writer = csv.DictWriter(buf, fieldnames=IMPORT_CSV_COLUMNS, lineterminator="\n")
    writer.writeheader()
    for row in IMPORT_CSV_SAMPLE_ROWS:
        writer.writerow(row)
    return "\ufeff" + buf.getvalue()


async def _resolve_store_id(
    db: AsyncSession,
    tenant_id: str,
    store_id: str | None,
    store_code: str | None,
    store_by_id: dict[str, Store],
    store_by_code: dict[str, Store],
) -> tuple[str | None, str | None]:
    sid = (store_id or "").strip()
    if sid:
        if sid not in store_by_id:
            return None, f"門店 ID 不存在：{sid}"
        return sid, None
    code = (store_code or "").strip()
    if code:
        store = store_by_code.get(code)
        if not store:
            return None, f"門店代號不存在：{code}"
        return store.id, None
    return None, "請提供 store_id 或 store_code"


async def import_books_from_csv(
    db: AsyncSession,
    tenant_id: str,
    rows: list[dict[str, str]],
    user_id: str | None,
) -> BookImportResult:
    stores = (
        await db.execute(select(Store).where(Store.tenant_id == tenant_id))
    ).scalars().all()
    store_by_id = {s.id: s for s in stores}
    store_by_code = {s.code: s for s in stores}

    result = BookImportResult()
    for row_num, row in enumerate(rows, start=2):
        barcode = (row.get("barcode") or "").strip()
        if not barcode:
            continue

        qty_raw = (row.get("qty") or "").strip()
        try:
            qty = float(qty_raw)
            if qty <= 0:
                raise ValueError
        except ValueError:
            result.skipped += 1
            result.errors.append(
                BookImportRowError(row=row_num, barcode=barcode, message=f"qty 須為正數：{qty_raw}")
            )
            continue

        store_id, store_err = await _resolve_store_id(
            db,
            tenant_id,
            row.get("store_id"),
            row.get("store_code"),
            store_by_id,
            store_by_code,
        )
        if store_err:
            result.skipped += 1
            result.errors.append(
                BookImportRowError(row=row_num, barcode=barcode, message=store_err)
            )
            continue

        try:
            await receive_book_by_barcode(db, tenant_id, store_id, barcode, qty, user_id)
            result.received += 1
        except UnsupportedBarcodeError as e:
            result.skipped += 1
            result.errors.append(BookImportRowError(row=row_num, barcode=barcode, message=str(e)))
        except BookLookupNotFoundError as e:
            result.skipped += 1
            result.errors.append(BookImportRowError(row=row_num, barcode=barcode, message=str(e)))
        except Exception as e:
            result.skipped += 1
            result.errors.append(
                BookImportRowError(row=row_num, barcode=barcode, message=str(e) or "入庫失敗")
            )

    return result
