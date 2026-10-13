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

# LOGCODE (18), ISBN (13) and TAAZE prodId (11), one row each.
IMPORT_CSV_SAMPLE_BARCODES = ["978986136514524119", "9789571347653", "11101042331"]


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


async def sample_store_code(
    db: AsyncSession, tenant_id: str, scope_store_id: str | None, allowed_store_ids: list[str]
) -> str:
    """Pick a real store code for the template: the session's store, else a store open
    for consignment, preferring physical bookstores."""
    stores = (
        await db.execute(
            select(Store)
            .where(Store.tenant_id == tenant_id, Store.deleted_at.is_(None))
            .order_by(Store.name)
        )
    ).scalars().all()
    if scope_store_id:
        stores = [s for s in stores if s.id == scope_store_id] or stores
    elif allowed_store_ids:
        stores = [s for s in stores if s.id in allowed_store_ids] or stores
    stores = sorted(stores, key=lambda s: s.store_kind != "bookstore")
    return stores[0].code if stores else "S001"


def render_book_import_template_csv(store_code: str = "S001") -> str:
    buf = StringIO()
    writer = csv.DictWriter(buf, fieldnames=IMPORT_CSV_COLUMNS, lineterminator="\n")
    writer.writeheader()
    for barcode in IMPORT_CSV_SAMPLE_BARCODES:
        writer.writerow({"barcode": barcode, "qty": "1", "store_id": "", "store_code": store_code})
    return "\ufeff" + buf.getvalue()


class BookImportFormatError(ValueError):
    pass


def parse_book_import_csv(raw: bytes) -> list[dict[str, str]]:
    """Accept comma / tab / semicolon files from Excel, UTF-8 (with or without BOM) or Big5."""
    try:
        text = raw.decode("utf-8-sig")
    except UnicodeDecodeError:
        text = raw.decode("cp950", errors="replace")
    first_line = text.lstrip().split("\n", 1)[0]
    delimiter = max((",", "\t", ";"), key=first_line.count)
    reader = csv.DictReader(StringIO(text), delimiter=delimiter)
    if not reader.fieldnames or "barcode" not in {
        (f or "").strip().lower() for f in reader.fieldnames
    }:
        raise BookImportFormatError(
            "找不到 barcode 欄位，請確認第一列為 barcode,qty,store_id,store_code（逗號或 Tab 分隔皆可）"
        )
    return [
        {(k or "").strip().lower(): (v or "") for k, v in row.items() if k is not None}
        for row in reader
    ]


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
