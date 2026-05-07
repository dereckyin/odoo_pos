import os
import uuid
from pathlib import Path

from fastapi import APIRouter, File, HTTPException, UploadFile, status

from ...core.deps import AdminDep

router = APIRouter(prefix="/uploads", tags=["uploads"])

UPLOAD_DIR = Path(os.getenv("UPLOAD_DIR", "uploads"))
ALLOWED_TYPES = {"image/jpeg", "image/png", "image/gif", "image/webp"}
MAX_SIZE = 5 * 1024 * 1024


@router.post("/images")
async def upload_image(_: AdminDep, file: UploadFile = File(...)) -> dict:
    if file.content_type not in ALLOWED_TYPES:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, f"unsupported type: {file.content_type}")

    data = await file.read()
    if len(data) > MAX_SIZE:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "file too large (max 5MB)")

    ext = file.filename.rsplit(".", 1)[-1] if file.filename and "." in file.filename else "jpg"
    filename = f"{uuid.uuid4().hex}.{ext}"

    UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
    dest = UPLOAD_DIR / filename
    dest.write_bytes(data)

    url = f"/uploads/{filename}"
    return {"url": url, "filename": filename}
