from datetime import date, datetime, time, timezone

from fastapi import APIRouter, File, HTTPException, Query, UploadFile, status
from fastapi.responses import Response
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from ...core.audit import audit
from ...core.deps import DbSession, StoreAdminDep, TenantAdminDep, TenantScope
from ...models import Product, Tenant
from ...schemas.book import (
    BookImportResultRead,
    BookLookupRead,
    BookProductRead,
    BookReceiveRequest,
    ConsignmentBooksSettingsRead,
    ConsignmentBooksSettingsUpdate,
    ConsignmentPosConfig,
    DiscountPreset,
)
from ...services.book_catalog import (
    book_last_received_by_product,
    book_on_hand_by_product,
    ensure_consignment_category,
    product_to_book_read,
    render_books_export_csv,
    search_books,
)
from ...services.book_import import (
    BookImportFormatError,
    import_books_from_csv,
    parse_book_import_csv,
    render_book_import_template_csv,
    sample_store_code,
)
from ...services.book_lookup import (
    BookLookupNotFoundError,
    UnsupportedBarcodeError,
    lookup_barcode,
)
from ...services.book_receive import product_read_after_receive, receive_book_by_barcode
from ...services.consignment_books import (
    assert_consignment_module,
    assert_store_allowed,
    get_consignment_settings,
    is_consignment_enabled_for_store,
    read_consignment_settings,
    write_consignment_settings,
)
from ...api.v1.inventories import _ensure_store_in_tenant, _resolve_store_id

router = APIRouter(prefix="/books", tags=["books"])


def _settings_read(tenant: Tenant) -> ConsignmentBooksSettingsRead:
    cfg = read_consignment_settings(tenant.settings)
    presets = [DiscountPreset(**p) for p in cfg["discount_presets"]]
    return ConsignmentBooksSettingsRead(
        book_share_pct=cfg["book_share_pct"],
        store_ids=cfg["store_ids"],
        discount_presets=presets,
    )


@router.get("/settings", response_model=ConsignmentBooksSettingsRead)
async def get_settings(db: DbSession, scope: TenantAdminDep):
    await assert_consignment_module(db, scope.tenant_id)
    tenant = await db.get(Tenant, scope.tenant_id)
    if not tenant:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    return _settings_read(tenant)


@router.patch("/settings", response_model=ConsignmentBooksSettingsRead)
async def update_settings(
    payload: ConsignmentBooksSettingsUpdate, db: DbSession, scope: TenantAdminDep
):
    await assert_consignment_module(db, scope.tenant_id)
    tenant = await db.get(Tenant, scope.tenant_id)
    if not tenant:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    try:
        tenant.settings = write_consignment_settings(
            tenant.settings,
            payload.model_dump(exclude_unset=True),
        )
    except ValueError as e:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, str(e)) from e
    await audit(
        db, scope, action="consignment_books_settings_update",
        resource_type="tenant", resource_id=tenant.id, flush=False,
    )
    await db.commit()
    await db.refresh(tenant)
    return _settings_read(tenant)


@router.get("/pos-config", response_model=ConsignmentPosConfig)
async def pos_config(db: DbSession, scope: TenantScope):
    enabled = await is_consignment_enabled_for_store(db, scope.tenant_id, scope.store_id)
    cfg = await get_consignment_settings(db, scope.tenant_id)
    category_id = None
    if enabled:
        cat = await ensure_consignment_category(db, scope.tenant_id)
        category_id = cat.id
    presets = [DiscountPreset(**p) for p in cfg["discount_presets"]]
    return ConsignmentPosConfig(
        enabled=enabled,
        book_share_pct=cfg["book_share_pct"],
        discount_presets=presets,
        category_id=category_id,
    )


@router.get("/lookup", response_model=BookLookupRead)
async def lookup_book(
    db: DbSession, scope: StoreAdminDep, barcode: str = Query(min_length=1)
):
    """Preview book metadata from TAAZE before inbound (does not write DB)."""
    await assert_consignment_module(db, scope.tenant_id)
    try:
        result = lookup_barcode(barcode)
    except UnsupportedBarcodeError as e:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, str(e)) from e
    except BookLookupNotFoundError as e:
        raise HTTPException(status.HTTP_404_NOT_FOUND, str(e)) from e
    return BookLookupRead(
        barcode=barcode.strip(),
        barcode_kind=result.barcode_kind,
        title=result.title,
        author=result.author,
        publisher=result.publisher,
        isbn=result.isbn,
        list_price_cents=result.list_price_cents,
        sale_price_cents=result.sale_price_cents,
        category_main=result.category_main,
        category_sub=result.category_sub,
        image_url=result.image_url,
        pages=result.pages,
        publish_date=result.publish_date,
        translator=result.translator,
        is_second_hand=result.is_second_hand,
        sale_disc=result.sale_disc,
        source=result.source,
    )


@router.get("/search", response_model=list[BookProductRead])
async def search_book_products(
    db: DbSession,
    scope: TenantScope,
    q: str = Query(min_length=1),
    store_id: str | None = None,
    limit: int = Query(50, le=100),
):
    await assert_consignment_module(db, scope.tenant_id)
    sid = scope.store_id or store_id
    if sid:
        await assert_store_allowed(db, scope.tenant_id, sid)
    rows = await search_books(db, scope.tenant_id, q, sid, limit=limit)
    return [
        BookProductRead(**product_to_book_read(p, on_hand, last_recv))
        for p, on_hand, last_recv in rows
    ]


@router.post("/receive", response_model=BookProductRead)
async def receive_book(payload: BookReceiveRequest, db: DbSession, scope: StoreAdminDep):
    """Inbound: TAAZE lookup → upsert catalog → add store inventory."""
    await assert_consignment_module(db, scope.tenant_id)
    target_store = _resolve_store_id(scope, payload.store_id)
    await _ensure_store_in_tenant(db, scope, target_store)
    await assert_store_allowed(db, scope.tenant_id, target_store)

    try:
        product, on_hand = await receive_book_by_barcode(
            db,
            scope.tenant_id,
            target_store,
            payload.barcode.strip(),
            payload.qty,
            scope.user_id,
        )
    except UnsupportedBarcodeError as e:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, str(e)) from e
    except BookLookupNotFoundError as e:
        raise HTTPException(status.HTTP_404_NOT_FOUND, str(e)) from e

    await audit(
        db, scope, action="book_receive",
        resource_type="product", resource_id=product.id,
        extra={"barcode": payload.barcode.strip(), "qty": payload.qty, "store_id": target_store},
        flush=False,
    )
    await db.commit()
    return BookProductRead(**product_read_after_receive(product, on_hand))


@router.get("/import-csv/template")
async def download_book_import_template(db: DbSession, scope: StoreAdminDep) -> Response:
    cfg = await get_consignment_settings(db, scope.tenant_id)
    store_code = await sample_store_code(db, scope.tenant_id, scope.store_id, cfg["store_ids"])
    content = render_book_import_template_csv(store_code)
    return Response(
        content=content.encode("utf-8"),
        media_type="text/csv; charset=utf-8",
        headers={"Content-Disposition": 'attachment; filename="book-import-sample.csv"'},
    )


@router.post("/import-csv", response_model=BookImportResultRead, status_code=201)
async def import_books_csv(
    db: DbSession,
    scope: StoreAdminDep,
    file: UploadFile = File(...),
) -> BookImportResultRead:
    await assert_consignment_module(db, scope.tenant_id)
    try:
        rows = parse_book_import_csv(await file.read())
    except BookImportFormatError as e:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, str(e)) from e
    result = await import_books_from_csv(db, scope.tenant_id, rows, scope.user_id)
    await audit(
        db,
        scope,
        action="book_import_csv",
        resource_type="product",
        extra=result.to_dict(),
        flush=False,
    )
    await db.commit()
    return BookImportResultRead(**result.to_dict())


def _day_start_utc(d: date) -> datetime:
    return datetime.combine(d, time.min, tzinfo=timezone.utc)


def _day_end_utc(d: date) -> datetime:
    return datetime.combine(d, time.max, tzinfo=timezone.utc)


def _filter_in_stock(rows: list[dict], in_stock_only: bool) -> list[dict]:
    if not in_stock_only:
        return rows
    return [r for r in rows if float(r.get("on_hand") or 0) > 0]


@router.get("/export-csv")
async def export_books_csv(
    db: DbSession,
    scope: TenantAdminDep,
    date_from: date = Query(..., description="進貨日期起（含）"),
    date_to: date = Query(..., description="進貨日期迄（含）"),
    q: str | None = None,
    store_id: str | None = None,
    in_stock_only: bool = Query(False, description="僅匯出目前有庫存者"),
) -> Response:
    """Export consignment books whose last receive falls in [date_from, date_to]."""
    await assert_consignment_module(db, scope.tenant_id)
    if date_to < date_from:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "結束日期不可早於開始日期")
    query = (q or "").strip()
    if query:
        triples = await search_books(db, scope.tenant_id, query, store_id, limit=2000)
        rows = [
            product_to_book_read(p, on_hand, last_recv)
            for p, on_hand, last_recv in triples
        ]
    else:
        stmt = (
            select(Product)
            .where(
                Product.tenant_id == scope.tenant_id,
                Product.deleted_at.is_(None),
                Product.product_kind == "consignment_book",
            )
            .options(selectinload(Product.barcodes), selectinload(Product.book_detail))
            .order_by(Product.name)
            .limit(5000)
        )
        products = (await db.execute(stmt)).scalars().unique().all()
        ids = [p.id for p in products]
        on_hand_map = await book_on_hand_by_product(db, scope.tenant_id, ids, store_id)
        recv_map = await book_last_received_by_product(db, scope.tenant_id, ids, store_id)
        rows = [
            product_to_book_read(p, on_hand_map.get(p.id, 0.0), recv_map.get(p.id))
            for p in products
        ]
    start = _day_start_utc(date_from)
    end = _day_end_utc(date_to)
    filtered: list[dict] = []
    for r in rows:
        ts = r.get("last_received_at")
        if ts is None:
            continue
        if ts.tzinfo is None:
            ts = ts.replace(tzinfo=timezone.utc)
        if start <= ts <= end:
            filtered.append(r)
    filtered = _filter_in_stock(filtered, in_stock_only)
    content = render_books_export_csv(filtered)
    fname = f"books-export-{date_from.isoformat()}_{date_to.isoformat()}.csv"
    return Response(
        content=content.encode("utf-8"),
        media_type="text/csv; charset=utf-8",
        headers={"Content-Disposition": f'attachment; filename="{fname}"'},
    )


@router.get("", response_model=list[BookProductRead])
async def list_books(
    db: DbSession,
    scope: TenantAdminDep,
    q: str | None = None,
    store_id: str | None = None,
    in_stock_only: bool = Query(True, description="僅列出目前有庫存者"),
    limit: int = Query(100, le=200),
):
    await assert_consignment_module(db, scope.tenant_id)
    query = q or ""
    # Fetch extra when filtering stock so page still fills after dropping zeros.
    fetch_limit = min(500, limit * 5) if in_stock_only else limit
    if not query:
        stmt = (
            select(Product)
            .where(
                Product.tenant_id == scope.tenant_id,
                Product.deleted_at.is_(None),
                Product.product_kind == "consignment_book",
            )
            .options(selectinload(Product.barcodes), selectinload(Product.book_detail))
            .order_by(Product.name)
            .limit(fetch_limit)
        )
        products = (await db.execute(stmt)).scalars().unique().all()
        ids = [p.id for p in products]
        on_hand_map = await book_on_hand_by_product(db, scope.tenant_id, ids, store_id)
        recv_map = await book_last_received_by_product(db, scope.tenant_id, ids, store_id)
        rows = [
            product_to_book_read(p, on_hand_map.get(p.id, 0.0), recv_map.get(p.id))
            for p in products
        ]
    else:
        triples = await search_books(db, scope.tenant_id, query, store_id, limit=fetch_limit)
        rows = [
            product_to_book_read(p, on_hand, last_recv)
            for p, on_hand, last_recv in triples
        ]
    filtered = _filter_in_stock(rows, in_stock_only)[:limit]
    return [BookProductRead(**r) for r in filtered]
