import csv
from datetime import datetime, timezone
from io import StringIO

from fastapi import APIRouter, File, HTTPException, Query, UploadFile, status
from sqlalchemy import or_, select
from sqlalchemy.orm import selectinload

from ...core.deps import AdminDep, CurrentUserDep, DbSession
from ...models import Product, ProductBarcode
from ...schemas.product import ProductCreate, ProductRead, ProductUpdate

router = APIRouter(prefix="/products", tags=["products"])


async def _ensure_barcodes(db, product: Product, barcodes: list[str]) -> None:
    """Replace product barcodes with the supplied list."""
    existing = {b.barcode: b for b in product.barcodes}
    target = set(barcodes)
    for code, row in list(existing.items()):
        if code not in target:
            await db.delete(row)
    for code in target - set(existing.keys()):
        db.add(ProductBarcode(product_id=product.id, barcode=code))


@router.get("", response_model=list[ProductRead])
async def list_products(
    db: DbSession,
    _: CurrentUserDep,
    q: str | None = None,
    category_id: str | None = None,
    is_active: bool | None = None,
    limit: int = Query(50, le=200),
    offset: int = 0,
) -> list[ProductRead]:
    stmt = select(Product).where(Product.deleted_at.is_(None)).options(selectinload(Product.barcodes))
    if q:
        like = f"%{q}%"
        stmt = stmt.outerjoin(ProductBarcode).where(
            or_(Product.name.ilike(like), Product.sku.ilike(like), ProductBarcode.barcode == q)
        ).distinct()
    if category_id:
        stmt = stmt.where(Product.category_id == category_id)
    if is_active is not None:
        stmt = stmt.where(Product.is_active == is_active)
    stmt = stmt.order_by(Product.name).limit(limit).offset(offset)
    rows = (await db.execute(stmt)).scalars().unique().all()
    return [ProductRead.from_orm_with_barcodes(r) for r in rows]


@router.post("", response_model=ProductRead, status_code=201)
async def create_product(payload: ProductCreate, db: DbSession, _: AdminDep) -> ProductRead:
    p = Product(**payload.model_dump(exclude={"barcodes"}))
    db.add(p)
    await db.flush()
    for code in payload.barcodes:
        db.add(ProductBarcode(product_id=p.id, barcode=code))
    await db.commit()
    p = (
        await db.execute(select(Product).where(Product.id == p.id).options(selectinload(Product.barcodes)))
    ).scalar_one()
    return ProductRead.from_orm_with_barcodes(p)


@router.get("/{pid}", response_model=ProductRead)
async def get_product(pid: str, db: DbSession, _: CurrentUserDep) -> ProductRead:
    p = (
        await db.execute(select(Product).where(Product.id == pid).options(selectinload(Product.barcodes)))
    ).scalar_one_or_none()
    if not p or p.deleted_at:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    return ProductRead.from_orm_with_barcodes(p)


@router.patch("/{pid}", response_model=ProductRead)
async def update_product(pid: str, payload: ProductUpdate, db: DbSession, _: AdminDep) -> ProductRead:
    p = (
        await db.execute(select(Product).where(Product.id == pid).options(selectinload(Product.barcodes)))
    ).scalar_one_or_none()
    if not p or p.deleted_at:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    data = payload.model_dump(exclude_unset=True)
    barcodes = data.pop("barcodes", None)
    for k, v in data.items():
        setattr(p, k, v)
    if barcodes is not None:
        await _ensure_barcodes(db, p, barcodes)
    await db.commit()
    p = (
        await db.execute(select(Product).where(Product.id == pid).options(selectinload(Product.barcodes)))
    ).scalar_one()
    return ProductRead.from_orm_with_barcodes(p)


@router.delete("/{pid}", status_code=204)
async def delete_product(pid: str, db: DbSession, _: AdminDep) -> None:
    p = await db.get(Product, pid)
    if not p:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    p.deleted_at = datetime.now(timezone.utc)
    await db.commit()


@router.post("/import-csv", status_code=201)
async def import_products_csv(
    db: DbSession,
    _: AdminDep,
    file: UploadFile = File(...),
) -> dict:
    """CSV columns: sku,name,price_cents,category_id,barcode,is_weighted,unit"""
    raw = (await file.read()).decode("utf-8-sig")
    reader = csv.DictReader(StringIO(raw))
    created = 0
    updated = 0
    for row in reader:
        sku = (row.get("sku") or "").strip()
        if not sku:
            continue
        existing = (
            await db.execute(select(Product).where(Product.sku == sku))
        ).scalar_one_or_none()
        defaults = dict(
            sku=sku,
            name=(row.get("name") or sku).strip(),
            price_cents=int(row.get("price_cents") or 0),
            category_id=row.get("category_id") or None,
            is_weighted=str(row.get("is_weighted") or "").lower() in ("1", "true", "yes"),
            unit=row.get("unit") or "個",
            is_active=True,
        )
        if existing:
            for k, v in defaults.items():
                setattr(existing, k, v)
            p = existing
            updated += 1
        else:
            p = Product(**defaults)
            db.add(p)
            created += 1
        await db.flush()
        bc = (row.get("barcode") or "").strip()
        if bc:
            await _ensure_barcodes(db, p, [bc])
    await db.commit()
    return {"created": created, "updated": updated}
