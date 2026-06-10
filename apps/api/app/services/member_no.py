"""Per-tenant sequential member number generation.

Member numbers follow the format ``M`` + zero-padded running serial (6 digits),
e.g. ``M000001``. The serial is derived from the current maximum numeric suffix
for the tenant so it stays stable even if rows are soft-deleted. Callers should
generate inside the same transaction that inserts the member and retry on the
unique-constraint violation (``uq_member_tenant_no``) to be concurrency safe.
"""

from __future__ import annotations

import re

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..models import Member

PREFIX = "M"
_PAD = 6
_NUM_RE = re.compile(r"^M0*(\d+)$")


def format_member_no(serial: int) -> str:
    return f"{PREFIX}{serial:0{_PAD}d}"


async def next_member_no(db: AsyncSession, tenant_id: str) -> str:
    """Return the next member number for ``tenant_id``.

    Scans existing ``member_no`` values (including soft-deleted) to find the
    highest serial so reused numbers don't clash with historical members.
    """
    rows = (
        await db.execute(
            select(Member.member_no).where(
                Member.tenant_id == tenant_id,
                Member.member_no.is_not(None),
            )
        )
    ).scalars().all()
    max_serial = 0
    for no in rows:
        if not no:
            continue
        m = _NUM_RE.match(no.strip())
        if m:
            try:
                max_serial = max(max_serial, int(m.group(1)))
            except ValueError:
                continue
    return format_member_no(max_serial + 1)
