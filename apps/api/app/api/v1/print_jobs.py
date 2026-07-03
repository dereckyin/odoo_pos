"""Print job queue for web POS clients and in-store print agents."""
from __future__ import annotations

from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import select

from ...core.deps import DbSession, TenantScope, apply_tenant, ensure_same_tenant
from ...models import PrintJob
from ...schemas.print_job import (
    PrintJobCreate,
    PrintJobFailRequest,
    PrintJobPendingResponse,
    PrintJobRead,
)

router = APIRouter(prefix="/print-jobs", tags=["print-jobs"])

_MAX_RETRIES = 3
_CLAIM_STALE_MINUTES = 5


def _now() -> datetime:
    return datetime.now(timezone.utc)


@router.post("", response_model=PrintJobRead, status_code=201)
async def create_print_job(
    payload: PrintJobCreate, db: DbSession, scope: TenantScope
) -> PrintJob:
    scope.require_tenant()
    store_id = payload.store_id or scope.store_id
    if not store_id:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "store_id required")
    if scope.store_id and store_id != scope.store_id and not scope.is_tenant_admin:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "store_id mismatch")

    job_kwargs = dict(
        tenant_id=scope.tenant_id,
        store_id=store_id,
        printer_role=payload.printer_role,
        doc_type=payload.doc_type,
        payload=payload.payload,
        status="pending",
    )
    if payload.id:
        job_kwargs["id"] = payload.id
    job = PrintJob(**job_kwargs)
    db.add(job)
    await db.commit()
    await db.refresh(job)
    return job


@router.get("/pending", response_model=PrintJobPendingResponse)
async def poll_pending_jobs(
    db: DbSession,
    scope: TenantScope,
    store_id: str | None = Query(default=None),
    limit: int = Query(default=10, le=50),
) -> PrintJobPendingResponse:
    """Print agent polls this endpoint; claimed jobs move to ``printing``."""
    scope.require_tenant()
    target_store = store_id or scope.store_id
    if not target_store:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "store_id required")

    now = _now()
    stale_before = now.timestamp() - (_CLAIM_STALE_MINUTES * 60)

    # Re-queue stale "printing" jobs (agent crashed mid-job).
    stale_rows = (
        await db.execute(
            apply_tenant(
                select(PrintJob).where(
                    PrintJob.store_id == target_store,
                    PrintJob.status == "printing",
                    PrintJob.claimed_at.is_not(None),
                ),
                PrintJob,
                scope,
            )
        )
    ).scalars().all()
    for row in stale_rows:
        if row.claimed_at and row.claimed_at.timestamp() < stale_before:
            if row.retry_count < _MAX_RETRIES:
                row.status = "pending"
                row.claimed_at = None
            else:
                row.status = "failed"
                row.last_error = row.last_error or "claim timeout"
    if stale_rows:
        await db.flush()

    stmt = (
        apply_tenant(
            select(PrintJob).where(
                PrintJob.store_id == target_store,
                PrintJob.status == "pending",
            ),
            PrintJob,
            scope,
        )
        .order_by(PrintJob.created_at)
        .limit(limit)
        .with_for_update(skip_locked=True)
    )
    rows = (await db.execute(stmt)).scalars().all()
    claimed: list[PrintJob] = []
    for job in rows:
        job.status = "printing"
        job.claimed_at = now
        claimed.append(job)
    if claimed:
        await db.commit()
        for job in claimed:
            await db.refresh(job)
    return PrintJobPendingResponse(items=[PrintJobRead.model_validate(j) for j in claimed])


async def _load_job(db: DbSession, scope: TenantScope, job_id: str) -> PrintJob:
    job = await db.get(PrintJob, job_id)
    if not job:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "print job not found")
    ensure_same_tenant(scope, job)
    return job


@router.post("/{job_id}/complete", response_model=PrintJobRead)
async def complete_print_job(job_id: str, db: DbSession, scope: TenantScope) -> PrintJob:
    job = await _load_job(db, scope, job_id)
    if job.status not in ("printing", "pending"):
        raise HTTPException(status.HTTP_409_CONFLICT, f"job status is {job.status}")
    job.status = "done"
    job.completed_at = _now()
    job.last_error = None
    await db.commit()
    await db.refresh(job)
    return job


@router.post("/{job_id}/fail", response_model=PrintJobRead)
async def fail_print_job(
    job_id: str,
    payload: PrintJobFailRequest,
    db: DbSession,
    scope: TenantScope,
) -> PrintJob:
    job = await _load_job(db, scope, job_id)
    if job.status not in ("printing", "pending"):
        raise HTTPException(status.HTTP_409_CONFLICT, f"job status is {job.status}")
    job.retry_count += 1
    job.last_error = payload.error[:2000]
    if job.retry_count >= _MAX_RETRIES:
        job.status = "failed"
    else:
        job.status = "pending"
        job.claimed_at = None
    await db.commit()
    await db.refresh(job)
    return job
