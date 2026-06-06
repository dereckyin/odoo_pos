from datetime import datetime, timezone
from uuid import uuid4

from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from ...core.audit import audit
from ...core.deps import DbSession, StoreAdminDep, TenantAdminDep, TenantScope
from ...models import InventoryLevel, InventoryMovement, Product, Tenant
from ...schemas.book import (
    BookLookupRead,
    BookProductRead,
    BookReceiveRequest,
    BookScanRequest,
    ConsignmentBooksSettingsRead,
    ConsignmentBooksSettingsUpdate,
    ConsignmentPosConfig,
    DiscountPreset,
)
from ...services.book_catalog import (
    ensure_consignment_category,
    product_to_book_read,
    search_books,
    upsert_book_from_barcode,
)
from ...services.book_lookup import (
    BookLookupNotFoundError,
    UnsupportedBarcodeError,
    lookup_barcode,
)
from ...services.consignment_books import (
    assert_consignment_module,
    assert_store_allowed,
    get_consignment_settings,
    is_consignment_enabled_for_store,
    read_consignment_settings,
    write_consignment_settings,
)
from ...api.v1.inventories import _apply_movement, _ensure_store_in_tenant, _resolve_store_id

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
    db: DbSession, scope: TenantScope, barcode: str = Query(min_length=1)
):
    await assert_store_allowed(db, scope.tenant_id, scope.store_id)
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
    return [BookProductRead(**product_to_book_read(p, on_hand)) for p, on_hand in rows]


@router.post("/scan", response_model=BookProductRead)
async def scan_book(payload: BookScanRequest, db: DbSession, scope: TenantScope):
    await assert_store_allowed(db, scope.tenant_id, scope.store_id)
    try:
        lookup = lookup_barcode(payload.barcode)
    except UnsupportedBarcodeError as e:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, str(e)) from e
    except BookLookupNotFoundError as e:
        raise HTTPException(status.HTTP_404_NOT_FOUND, str(e)) from e
    product = await upsert_book_from_barcode(db, scope.tenant_id, payload.barcode, lookup)
    on_hand = None
    if scope.store_id:
        level = (
            await db.execute(
                select(InventoryLevel).where(
                    InventoryLevel.store_id == scope.store_id,
                    InventoryLevel.product_id == product.id,
                )
            )
        ).scalar_one_or_none()
        on_hand = float(level.on_hand) if level else 0.0
    await audit(
        db, scope, action="book_scan_upsert",
        resource_type="product", resource_id=product.id, flush=False,
    )
    await db.commit()
    product = (
        await db.execute(
            select(Product)
            .where(Product.id == product.id)
            .options(selectinload(Product.barcodes), selectinload(Product.book_detail))
        )
    ).scalar_one()
    return BookProductRead(**product_to_book_read(product, on_hand))


@router.post("/receive", response_model=BookProductRead)
async def receive_book(payload: BookReceiveRequest, db: DbSession, scope: StoreAdminDep):
    await assert_consignment_module(db, scope.tenant_id)
    target_store = _resolve_store_id(scope, payload.store_id)
    await _ensure_store_in_tenant(db, scope, target_store)
    await assert_store_allowed(db, scope.tenant_id, target_store)

    product = (
        await db.execute(
            select(Product)
            .where(
                Product.id == payload.product_id,
                Product.tenant_id == scope.tenant_id,
                Product.product_kind == "consignment_book",
            )
            .options(selectinload(Product.barcodes), selectinload(Product.book_detail))
        )
    ).scalar_one_or_none()
    if not product:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "book product not found")

    m = InventoryMovement(
        id=str(uuid4()),
        tenant_id=scope.tenant_id,
        store_id=target_store,
        product_id=product.id,
        qty_delta=float(payload.qty),
        reason="consignment_receive",
        ref_type="book_receive",
        ref_id=product.id,
        user_id=scope.user_id,
    )
    db.add(m)
    await _apply_movement(db, m)
    await audit(
        db, scope, action="book_receive",
        resource_type="product", resource_id=product.id,
        extra={"qty": payload.qty, "store_id": target_store}, flush=False,
    )
    await db.commit()

    level = (
        await db.execute(
            select(InventoryLevel).where(
                InventoryLevel.store_id == target_store,
                InventoryLevel.product_id == product.id,
            )
        )
    ).scalar_one_or_none()
    on_hand = float(level.on_hand) if level else float(payload.qty)
    return BookProductRead(**product_to_book_read(product, on_hand))


@router.get("", response_model=list[BookProductRead])
async def list_books(
    db: DbSession,
    scope: TenantAdminDep,
    q: str | None = None,
    store_id: str | None = None,
    limit: int = Query(100, le=200),
):
    await assert_consignment_module(db, scope.tenant_id)
    query = q or ""
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
            .limit(limit)
        )
        products = (await db.execute(stmt)).scalars().unique().all()
        on_hand_map: dict[str, float] = {}
        if store_id:
            pids = [p.id for p in products]
            if pids:
                levels = (
                    await db.execute(
                        select(InventoryLevel).where(
                            InventoryLevel.store_id == store_id,
                            InventoryLevel.product_id.in_(pids),
                        )
                    )
                ).scalars().all()
                on_hand_map = {lv.product_id: float(lv.on_hand) for lv in levels}
        return [
            BookProductRead(**product_to_book_read(p, on_hand_map.get(p.id)))
            for p in products
        ]
    rows = await search_books(db, scope.tenant_id, query, store_id, limit=limit)
    return [BookProductRead(**product_to_book_read(p, on_hand)) for p, on_hand in rows]
