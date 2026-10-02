import os
import uuid
from pathlib import Path

from fastapi import APIRouter, File, UploadFile

from ...core.deps import StoreAdminDep
from ...core.uploads import MAX_IMAGE_BYTES, validated_image_ext

router = APIRouter(prefix="/uploads", tags=["uploads"])

UPLOAD_DIR = Path(os.getenv("UPLOAD_DIR", "uploads"))


@router.post("/images")
async def upload_image(
    scope: StoreAdminDep, file: UploadFile = File(...)
) -> dict:
    data = await file.read(MAX_IMAGE_BYTES + 1)
    ext = validated_image_ext(data)
    filename = f"{uuid.uuid4().hex}.{ext}"

    # Store under per-tenant subdirectory so future per-tenant lifecycle
    # (cleanup on tenant deletion, signed URLs) is straightforward.
    tenant_dir = UPLOAD_DIR / (scope.tenant_id or "_platform")
    tenant_dir.mkdir(parents=True, exist_ok=True)
    dest = tenant_dir / filename
    dest.write_bytes(data)

    url = f"/uploads/{tenant_dir.name}/{filename}"
    return {"url": url, "filename": filename}
