from sqlalchemy import Boolean, ForeignKey, Integer, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..core.db import Base
from ._mixins import SoftDelete, Timestamped, UUIDPrimaryKey


class OptionGroup(Base, UUIDPrimaryKey, Timestamped, SoftDelete):
    __tablename__ = "option_groups"
    __table_args__ = (UniqueConstraint("tenant_id", "name", name="uq_option_group_tenant_name"),)

    tenant_id: Mapped[str] = mapped_column(ForeignKey("tenants.id"), index=True, nullable=False)
    name: Mapped[str] = mapped_column(String(128))
    selection_type: Mapped[str] = mapped_column(String(16), default="single")  # single | multi
    is_required: Mapped[bool] = mapped_column(Boolean, default=True)
    min_selections: Mapped[int] = mapped_column(Integer, default=0)
    max_selections: Mapped[int | None] = mapped_column(Integer, nullable=True)
    sort_order: Mapped[int] = mapped_column(Integer, default=0)

    choices: Mapped[list["OptionChoice"]] = relationship(
        back_populates="option_group", cascade="all, delete-orphan", order_by="OptionChoice.sort_order"
    )


class OptionChoice(Base, UUIDPrimaryKey, Timestamped, SoftDelete):
    __tablename__ = "option_choices"

    option_group_id: Mapped[str] = mapped_column(ForeignKey("option_groups.id"), index=True, nullable=False)
    name: Mapped[str] = mapped_column(String(128))
    price_delta_cents: Mapped[int] = mapped_column(Integer, default=0)
    is_default: Mapped[bool] = mapped_column(Boolean, default=False)
    sort_order: Mapped[int] = mapped_column(Integer, default=0)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    option_group: Mapped[OptionGroup] = relationship(back_populates="choices")


class ProductOptionGroup(Base, UUIDPrimaryKey, Timestamped):
    __tablename__ = "product_option_groups"
    __table_args__ = (
        UniqueConstraint("product_id", "option_group_id", name="uq_product_option_group"),
    )

    product_id: Mapped[str] = mapped_column(ForeignKey("products.id"), index=True, nullable=False)
    option_group_id: Mapped[str] = mapped_column(ForeignKey("option_groups.id"), index=True, nullable=False)
    sort_order: Mapped[int] = mapped_column(Integer, default=0)
    is_required: Mapped[bool | None] = mapped_column(Boolean, nullable=True)

    option_group: Mapped[OptionGroup] = relationship(lazy="joined")


class ProductOptionChoiceOverride(Base, UUIDPrimaryKey, Timestamped):
    __tablename__ = "product_option_choice_overrides"
    __table_args__ = (
        UniqueConstraint("product_id", "option_choice_id", name="uq_product_option_choice_override"),
    )

    product_id: Mapped[str] = mapped_column(ForeignKey("products.id"), index=True, nullable=False)
    option_choice_id: Mapped[str] = mapped_column(ForeignKey("option_choices.id"), index=True, nullable=False)
    price_delta_cents: Mapped[int | None] = mapped_column(Integer, nullable=True)
    is_hidden: Mapped[bool] = mapped_column(Boolean, default=False)

    option_choice: Mapped[OptionChoice] = relationship(lazy="joined")
