import csv
from datetime import datetime, timezone
from io import StringIO

from fastapi import APIRouter, File, HTTPException, Query, UploadFile, status
from fastapi.responses import Response
from sqlalchemy import or_, select
from sqlalchemy.orm import selectinload

from ...core.audit import audit
from ...core.deps import (
    DbSession,
    StoreAdminDep,
    TenantAdminDep,
    TenantScope,
    apply_tenant,
    ensure_same_tenant,
)
from ...core.usage import assert_can_add_product
from ...models import BookDetail, Product, ProductBarcode
from ...schemas.product import ProductCreate, ProductRead, ProductUpdate
from ...services.category_tree import build_category_maps, descendant_ids, load_tenant_categories
from ...services.product_import import (
    export_products_csv,
    import_products_from_csv,
    render_import_template_csv,
)

router = APIRouter(prefix="/products", tags=["products"])


async def _ensure_barcodes(
    db, product: Product, barcodes: list[str], tenant_id: str
) -> None:
    existing = {b.barcode: b for b in product.barcodes}
    target = set(barcodes)
    for code, row in list(existing.items()):
        if code not in target:
            await db.delete(row)
    for code in target - set(existing.keys()):
        db.add(ProductBarcode(tenant_id=tenant_id, product_id=product.id, barcode=code))


def _product_load_options():
    return (
        selectinload(Product.barcodes),
        selectinload(Product.book_detail),
    )


@router.get("", response_model=list[ProductRead])
async def list_products(
    db: DbSession,
    scope: TenantScope,
    q: str | None = None,
    category_id: str | None = None,
    include_subcategories: bool = True,
    is_active: bool | None = None,
    limit: int = Query(50, le=200),
    offset: int = 0,
) -> list[ProductRead]:
    stmt = select(Product).where(Product.deleted_at.is_(None)).options(*_product_load_options())
    stmt = apply_tenant(stmt, Product, scope)
    if q:
        like = f"%{q}%"
        stmt = (
            stmt.outerjoin(ProductBarcode)
            .outerjoin(BookDetail, BookDetail.product_id == Product.id)
            .where(
                or_(
                    Product.name.ilike(like),
                    Product.sku.ilike(like),
                    ProductBarcode.barcode == q,
                    BookDetail.author.ilike(like),
                )
            )
            .distinct()
        )
    if category_id:
        if include_subcategories:
            cats = await load_tenant_categories(db, scope.tenant_id)
            _, children_map = build_category_maps(cats)
            ids = descendant_ids(category_id, children_map)
            stmt = stmt.where(Product.category_id.in_(ids))
        else:
            stmt = stmt.where(Product.category_id == category_id)
    if is_active is not None:
        stmt = stmt.where(Product.is_active == is_active)
    stmt = stmt.order_by(Product.updated_at.desc(), Product.name).limit(limit).offset(offset)
    rows = (await db.execute(stmt)).scalars().unique().all()
    return [ProductRead.from_orm_with_barcodes(r) for r in rows]


@router.post("", response_model=ProductRead, status_code=201)
async def create_product(
    payload: ProductCreate, db: DbSession, scope: StoreAdminDep
) -> ProductRead:
    await assert_can_add_product(db, scope.tenant_id)
    p = Product(tenant_id=scope.tenant_id, **payload.model_dump(exclude={"barcodes"}))
    db.add(p)
    await db.flush()
    for code in payload.barcodes:
        db.add(ProductBarcode(tenant_id=scope.tenant_id, product_id=p.id, barcode=code))
    await audit(db, scope, action="product_create", resource_type="product",
                resource_id=p.id, flush=False)
    await db.commit()
    p = (
        await db.execute(
            select(Product).where(Product.id == p.id).options(*_product_load_options())
        )
    ).scalar_one()
    return ProductRead.from_orm_with_barcodes(p)


@router.get("/import-csv/template")
async def download_import_csv_template(scope: TenantAdminDep) -> Response:
    """Download UTF-8 BOM CSV template with sample rows."""
    content = render_import_template_csv()
    return Response(
        content=content.encode("utf-8"),
        media_type="text/csv; charset=utf-8",
        headers={"Content-Disposition": 'attachment; filename="product-import-sample.csv"'},
    )


@router.get("/export-csv")
async def export_products_csv_endpoint(
    db: DbSession,
    scope: TenantAdminDep,
    q: str | None = None,
    category_id: str | None = None,
    include_subcategories: bool = True,
    is_active: bool | None = None,
) -> Response:
    """Export products as UTF-8 BOM CSV (same columns as import + is_active)."""
    stmt = select(Product).where(Product.deleted_at.is_(None)).options(*_product_load_options())
    stmt = apply_tenant(stmt, Product, scope)
    if q:
        like = f"%{q}%"
        stmt = (
            stmt.outerjoin(ProductBarcode)
            .outerjoin(BookDetail, BookDetail.product_id == Product.id)
            .where(
                or_(
                    Product.name.ilike(like),
                    Product.sku.ilike(like),
                    ProductBarcode.barcode == q,
                    BookDetail.author.ilike(like),
                )
            )
            .distinct()
        )
    if category_id:
        if include_subcategories:
            cats = await load_tenant_categories(db, scope.tenant_id)
            _, children_map = build_category_maps(cats)
            ids = descendant_ids(category_id, children_map)
            stmt = stmt.where(Product.category_id.in_(ids))
        else:
            stmt = stmt.where(Product.category_id == category_id)
    if is_active is not None:
        stmt = stmt.where(Product.is_active == is_active)
    stmt = stmt.order_by(Product.updated_at.desc(), Product.name)
    rows = (await db.execute(stmt)).scalars().unique().all()
    categories = await load_tenant_categories(db, scope.tenant_id)
    content = export_products_csv(rows, categories)
    return Response(
        content=content.encode("utf-8"),
        media_type="text/csv; charset=utf-8",
        headers={"Content-Disposition": 'attachment; filename="products-export.csv"'},
    )


@router.post("/import-csv", status_code=201)
async def import_products_csv(
    db: DbSession,
    scope: TenantAdminDep,
    file: UploadFile = File(...),
) -> dict:
    """CSV columns: sku,name,price_cents,category_path,barcode,is_weighted,unit"""
    raw = (await file.read()).decode("utf-8-sig")
    reader = csv.DictReader(StringIO(raw))
    result = await import_products_from_csv(db, scope.tenant_id, list(reader))
    await audit(
        db,
        scope,
        action="product_import_csv",
        resource_type="product",
        extra=result.to_dict(),
        flush=False,
    )
    await db.commit()
    return result.to_dict()


@router.get("/{pid}", response_model=ProductRead)
async def get_product(pid: str, db: DbSession, scope: TenantScope) -> ProductRead:
    p = (
        await db.execute(
            select(Product).where(Product.id == pid).options(*_product_load_options())
        )
    ).scalar_one_or_none()
    if not p or p.deleted_at:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    ensure_same_tenant(scope, p)
    return ProductRead.from_orm_with_barcodes(p)


@router.patch("/{pid}", response_model=ProductRead)
async def update_product(
    pid: str, payload: ProductUpdate, db: DbSession, scope: StoreAdminDep
) -> ProductRead:
    p = (
        await db.execute(
            select(Product).where(Product.id == pid).options(*_product_load_options())
        )
    ).scalar_one_or_none()
    if not p or p.deleted_at:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    ensure_same_tenant(scope, p)
    data = payload.model_dump(exclude_unset=True)
    barcodes = data.pop("barcodes", None)
    for k, v in data.items():
        setattr(p, k, v)
    if getattr(p, "product_kind", "regular") == "consignment_book":
        p.track_inventory = True
    if barcodes is not None:
        await _ensure_barcodes(db, p, barcodes, scope.tenant_id)
    await audit(db, scope, action="product_update", resource_type="product",
                resource_id=pid, flush=False)
    await db.commit()
    p = (
        await db.execute(
            select(Product).where(Product.id == pid).options(*_product_load_options())
        )
    ).scalar_one()
    return ProductRead.from_orm_with_barcodes(p)


@router.delete("/{pid}", status_code=204)
async def delete_product(pid: str, db: DbSession, scope: StoreAdminDep) -> None:
    p = await db.get(Product, pid)
    if not p:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    ensure_same_tenant(scope, p)
    p.deleted_at = datetime.now(timezone.utc)
    await audit(db, scope, action="product_delete", resource_type="product",
                resource_id=pid, flush=False)
    await db.commit()
