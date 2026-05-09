from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from ...core.audit import audit
from ...core.deps import DbSession, TenantScope, ensure_same_tenant
from ...integrations.invoice import (
    InvoiceIssueRequest,
    InvoiceVoidRequest,
    tenant_invoice_driver_for,
)
from ...integrations.invoice.base import InvoiceLine
from ...models import Invoice, Order
from ...schemas.invoice import InvoiceRead, IssueInvoiceRequest, VoidInvoiceRequest

router = APIRouter(prefix="/invoices", tags=["invoices"])


@router.post("/issue", response_model=InvoiceRead, status_code=201)
async def issue_invoice(
    payload: IssueInvoiceRequest, db: DbSession, scope: TenantScope
) -> Invoice:
    order = (
        await db.execute(
            select(Order).where(Order.id == payload.order_id).options(selectinload(Order.lines))
        )
    ).scalar_one_or_none()
    if not order:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "order not found")
    ensure_same_tenant(scope, order)

    existing = (
        await db.execute(select(Invoice).where(Invoice.order_id == order.id))
    ).scalar_one_or_none()
    if existing and existing.status == "issued":
        return existing

    invoice = existing or Invoice(
        tenant_id=order.tenant_id,
        order_id=order.id,
        total_cents=order.total_cents,
        tax_cents=order.tax_cents,
        tax_type=payload.tax_type,
        carrier_type=payload.carrier_type,
        carrier_code=payload.carrier_code,
        tax_id=payload.tax_id,
        company_name=payload.company_name,
        donation_code=payload.donation_code,
        gateway=payload.gateway,
    )
    if not existing:
        db.add(invoice)
    await db.flush()

    drv = await tenant_invoice_driver_for(db, scope.tenant_id, payload.gateway)
    lines = [
        InvoiceLine(
            name=ln.product_name,
            qty=float(ln.qty),
            unit_price_cents=ln.unit_price_cents,
            amount_cents=ln.line_total_cents,
        )
        for ln in order.lines
    ]
    res = await drv.issue(
        InvoiceIssueRequest(
            order_id=order.id,
            total_cents=order.total_cents,
            tax_cents=order.tax_cents,
            tax_type=payload.tax_type,
            carrier_type=payload.carrier_type,
            carrier_code=payload.carrier_code,
            tax_id=payload.tax_id,
            company_name=payload.company_name,
            donation_code=payload.donation_code,
            email=payload.email,
            lines=lines,
        )
    )
    if res.status == "issued":
        invoice.status = "issued"
        invoice.invoice_number = res.invoice_number
        invoice.invoice_date = res.invoice_date or datetime.now(timezone.utc)
        invoice.gateway_response = res.raw
        order.invoice_number = res.invoice_number
    else:
        invoice.status = "failed"
        invoice.last_error = str(res.raw)

    await audit(db, scope, action="invoice_issue", resource_type="invoice",
                resource_id=invoice.id, flush=False)
    await db.commit()
    await db.refresh(invoice)
    return invoice


@router.post("/void", response_model=InvoiceRead)
async def void_invoice(
    payload: VoidInvoiceRequest, db: DbSession, scope: TenantScope
) -> Invoice:
    invoice = await db.get(Invoice, payload.invoice_id)
    if not invoice:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "invoice not found")
    ensure_same_tenant(scope, invoice)
    if invoice.status not in ("issued",):
        raise HTTPException(status.HTTP_409_CONFLICT, "invoice not issued")
    if not invoice.gateway or not invoice.invoice_number:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "missing gateway or invoice_number")
    drv = await tenant_invoice_driver_for(db, scope.tenant_id, invoice.gateway)
    res = await drv.void(
        InvoiceVoidRequest(invoice_number=invoice.invoice_number, reason=payload.reason)
    )
    if res.status == "voided":
        invoice.status = "voided"
        invoice.gateway_response = res.raw
    else:
        invoice.last_error = str(res.raw)
    await audit(db, scope, action="invoice_void", resource_type="invoice",
                resource_id=invoice.id, flush=False)
    await db.commit()
    await db.refresh(invoice)
    return invoice
