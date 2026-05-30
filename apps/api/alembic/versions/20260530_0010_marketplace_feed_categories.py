"""20260530_0010 — marketplace feed categories + product override."""

from typing import Union
from uuid import uuid4

import sqlalchemy as sa
from alembic import op

revision: str = "20260530_0010"
down_revision: Union[str, None] = "20260530_0009"
branch_labels = None
depends_on = None

# Stable IDs for seed data
CAT_BENTO = "11111111-1111-4111-8111-111111111001"
CAT_DRINKS = "11111111-1111-4111-8111-111111111002"
CAT_COFFEE = "11111111-1111-4111-8111-111111111003"
CAT_NOODLES = "11111111-1111-4111-8111-111111111004"
CAT_RICE = "11111111-1111-4111-8111-111111111005"
CAT_FRIED = "11111111-1111-4111-8111-111111111006"
CAT_BBQ = "11111111-1111-4111-8111-111111111007"
CAT_DESSERT = "11111111-1111-4111-8111-111111111008"
CAT_BREAKFAST = "11111111-1111-4111-8111-111111111009"
CAT_SNACK = "11111111-1111-4111-8111-11111111100a"
CAT_OTHER = "11111111-1111-4111-8111-11111111100b"

CATEGORIES = [
    (CAT_BENTO, "bento", "便當", "🍱", 10),
    (CAT_DRINKS, "drinks", "飲料", "🥤", 20),
    (CAT_COFFEE, "coffee_tea", "咖啡茶飲", "☕", 30),
    (CAT_NOODLES, "noodles", "麵食", "🍜", 40),
    (CAT_RICE, "rice", "飯類", "🍚", 50),
    (CAT_FRIED, "fried", "炸物", "🍗", 60),
    (CAT_BBQ, "bbq_braised", "燒烤滷味", "🍢", 70),
    (CAT_DESSERT, "dessert", "甜點", "🍰", 80),
    (CAT_BREAKFAST, "breakfast", "早餐", "🥐", 90),
    (CAT_SNACK, "snack", "小吃", "🥟", 100),
    (CAT_OTHER, "other", "其他", "📦", 999),
]

ALIASES = [
    ("便當", CAT_BENTO),
    ("便當/熟食", CAT_BENTO),
    ("主餐", CAT_BENTO),
    ("熟食", CAT_BENTO),
    ("飲料", CAT_DRINKS),
    ("drinks", CAT_DRINKS),
    ("咖啡", CAT_COFFEE),
    ("茶飲", CAT_COFFEE),
    ("咖啡茶飲", CAT_COFFEE),
    ("麵", CAT_NOODLES),
    ("麵食", CAT_NOODLES),
    ("飯", CAT_RICE),
    ("飯類", CAT_RICE),
    ("炸物", CAT_FRIED),
    ("炸雞", CAT_FRIED),
    ("滷味", CAT_BBQ),
    ("燒烤", CAT_BBQ),
    ("燒烤滷味", CAT_BBQ),
    ("甜點", CAT_DESSERT),
    ("蛋糕", CAT_DESSERT),
    ("早餐", CAT_BREAKFAST),
    ("小吃", CAT_SNACK),
    ("零食", CAT_SNACK),
    ("點心", CAT_SNACK),
    ("生活用品", CAT_OTHER),
    ("煙酒", CAT_OTHER),
    ("其他", CAT_OTHER),
]


def _normalize(alias: str) -> str:
    return alias.strip().lower()


def upgrade() -> None:
    op.create_table(
        "marketplace_categories",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("slug", sa.String(64), nullable=False),
        sa.Column("name", sa.String(64), nullable=False),
        sa.Column("icon", sa.String(16)),
        sa.Column("sort_order", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.text("true")),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.UniqueConstraint("slug", name="uq_marketplace_category_slug"),
    )
    op.create_table(
        "marketplace_category_aliases",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("alias", sa.String(128), nullable=False),
        sa.Column("alias_normalized", sa.String(128), nullable=False),
        sa.Column("marketplace_category_id", sa.String(36), sa.ForeignKey("marketplace_categories.id"), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.UniqueConstraint("alias_normalized", name="uq_marketplace_category_alias"),
    )
    op.create_index("ix_marketplace_category_aliases_category", "marketplace_category_aliases", ["marketplace_category_id"])

    op.add_column(
        "products",
        sa.Column("marketplace_category_id", sa.String(36), sa.ForeignKey("marketplace_categories.id"), nullable=True),
    )
    op.create_index("ix_products_marketplace_category_id", "products", ["marketplace_category_id"])

    cat_table = sa.table(
        "marketplace_categories",
        sa.column("id", sa.String),
        sa.column("slug", sa.String),
        sa.column("name", sa.String),
        sa.column("icon", sa.String),
        sa.column("sort_order", sa.Integer),
        sa.column("is_active", sa.Boolean),
    )
    op.bulk_insert(
        cat_table,
        [
            {"id": cid, "slug": slug, "name": name, "icon": icon, "sort_order": sort, "is_active": True}
            for cid, slug, name, icon, sort in CATEGORIES
        ],
    )

    alias_table = sa.table(
        "marketplace_category_aliases",
        sa.column("id", sa.String),
        sa.column("alias", sa.String),
        sa.column("alias_normalized", sa.String),
        sa.column("marketplace_category_id", sa.String),
    )
    op.bulk_insert(
        alias_table,
        [
            {
                "id": str(uuid4()),
                "alias": alias,
                "alias_normalized": _normalize(alias),
                "marketplace_category_id": cat_id,
            }
            for alias, cat_id in ALIASES
        ],
    )


def downgrade() -> None:
    op.drop_index("ix_products_marketplace_category_id", table_name="products")
    op.drop_column("products", "marketplace_category_id")
    op.drop_index("ix_marketplace_category_aliases_category", table_name="marketplace_category_aliases")
    op.drop_table("marketplace_category_aliases")
    op.drop_table("marketplace_categories")
