"""Seed marketplace feed categories (used by tests when DB has no migration data)."""

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..models import MarketplaceCategory, MarketplaceCategoryAlias
from .marketplace_category import normalize_alias

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


async def ensure_marketplace_feed_categories(db: AsyncSession) -> None:
    existing = (await db.execute(select(MarketplaceCategory.id).limit(1))).scalar_one_or_none()
    if existing:
        return
    for cid, slug, name, icon, sort in CATEGORIES:
        db.add(
            MarketplaceCategory(
                id=cid,
                slug=slug,
                name=name,
                icon=icon,
                sort_order=sort,
                is_active=True,
            )
        )
    await db.flush()
    for alias, cat_id in ALIASES:
        db.add(
            MarketplaceCategoryAlias(
                alias=alias,
                alias_normalized=normalize_alias(alias),
                marketplace_category_id=cat_id,
            )
        )
    await db.commit()
