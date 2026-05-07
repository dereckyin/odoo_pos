from datetime import datetime
from typing import Generic, TypeVar

from pydantic import BaseModel

T = TypeVar("T")


class DeltaPage(BaseModel, Generic[T]):
    items: list[T]
    server_time: datetime
    next_since: datetime
