import os
import uuid
from pathlib import Path

from fastapi import APIRouter, File, HTTPException, UploadFile, status

from ...core.deps import StoreAdminDep

router = APIRouter(prefix="/uploads", tags=["uploads"])

UPLOAD_DIR = Path(os.getenv("UPLOAD_DIR", "uploads"))
ALLOWED_TYPES = {"image/jpeg", "image/png", "image/gif", "image/webp"}
MAX_SIZE = 5 * 1024 * 1024


@router.post("/images")
async def upload_image(
    scope: StoreAdminDep, file: UploadFile = File(...)
) -> dict:
    if file.content_type not in ALLOWED_TYPES:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, f"unsupported type: {file.content_type}")

    data = await file.read()
    if len(data) > MAX_SIZE:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "file too large (max 5MB)")

    ext = file.filename.rsplit(".", 1)[-1] if file.filename and "." in file.filename else "jpg"
    filename = f"{uuid.uuid4().hex}.{ext}"

    # Store under per-tenant subdirectory so future per-tenant lifecycle
    # (cleanup on tenant deletion, signed URLs) is straightforward.
    tenant_dir = UPLOAD_DIR / (scope.tenant_id or "_platform")
    tenant_dir.mkdir(parents=True, exist_ok=True)
    dest = tenant_dir / filename
    dest.write_bytes(data)

    url = f"/uploads/{tenant_dir.name}/{filename}"
    return {"url": url, "filename": filename}
