"""Image upload validation shared by tenant and platform upload endpoints.

The client-supplied Content-Type and filename are both attacker controlled;
files are served back from ``/uploads`` on the API origin, so an ``.html`` or
``.svg`` saved there would be stored XSS. Only the file's magic bytes decide
whether it is accepted and which extension it gets.
"""
from fastapi import HTTPException, status

MAX_IMAGE_BYTES = 5 * 1024 * 1024


def sniff_image_ext(data: bytes) -> str | None:
    if data.startswith(b"\xff\xd8\xff"):
        return "jpg"
    if data.startswith(b"\x89PNG\r\n\x1a\n"):
        return "png"
    if data[:6] in (b"GIF87a", b"GIF89a"):
        return "gif"
    if len(data) >= 12 and data[:4] == b"RIFF" and data[8:12] == b"WEBP":
        return "webp"
    return None


def validated_image_ext(data: bytes) -> str:
    if len(data) > MAX_IMAGE_BYTES:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "file too large (max 5MB)")
    ext = sniff_image_ext(data)
    if ext is None:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "unsupported image (jpeg/png/gif/webp only)")
    return ext
