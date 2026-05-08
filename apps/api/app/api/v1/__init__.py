from fastapi import APIRouter

from . import (
    auth,
    stores,
    products,
    categories,
    members,
    coupons,
    promotions,
    inventories,
    orders,
    refunds,
    payments,
    invoices,
    sync,
    uploads,
    users,
    reports,
    dashboard,
    dining_tables,
    guest_orders,
    public_orders,
)

api_router = APIRouter()
api_router.include_router(auth.router)
api_router.include_router(stores.router)
api_router.include_router(products.router)
api_router.include_router(categories.router)
api_router.include_router(members.router)
api_router.include_router(coupons.router)
api_router.include_router(promotions.router)
api_router.include_router(inventories.router)
api_router.include_router(orders.router)
api_router.include_router(refunds.router)
api_router.include_router(payments.router)
api_router.include_router(invoices.router)
api_router.include_router(sync.router)
api_router.include_router(uploads.router)
api_router.include_router(users.router)
api_router.include_router(reports.router)
api_router.include_router(dashboard.router)
api_router.include_router(dining_tables.router)
api_router.include_router(guest_orders.router)
api_router.include_router(public_orders.router)
