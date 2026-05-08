import { createRouter, createWebHistory, type RouteRecordRaw } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const routes: RouteRecordRaw[] = [
  {
    path: '/login',
    name: 'login',
    component: () => import('@/views/auth/LoginView.vue'),
    meta: { public: true },
  },
  {
    path: '/',
    component: () => import('@/components/AppLayout.vue'),
    children: [
      { path: '', name: 'dashboard', component: () => import('@/views/dashboard/DashboardView.vue') },
      // Products
      { path: 'products', name: 'products', component: () => import('@/views/products/ProductListView.vue') },
      { path: 'products/create', name: 'product-create', component: () => import('@/views/products/ProductFormView.vue') },
      { path: 'products/:id/edit', name: 'product-edit', component: () => import('@/views/products/ProductFormView.vue') },
      { path: 'products/import', name: 'product-import', component: () => import('@/views/products/ProductImportView.vue') },
      { path: 'categories', name: 'categories', component: () => import('@/views/products/CategoryListView.vue') },
      // Promotions
      { path: 'promotions', name: 'promotions', component: () => import('@/views/promotions/PromotionListView.vue') },
      { path: 'promotions/create', name: 'promotion-create', component: () => import('@/views/promotions/PromotionFormView.vue') },
      { path: 'promotions/:id/edit', name: 'promotion-edit', component: () => import('@/views/promotions/PromotionFormView.vue') },
      // Coupons
      { path: 'coupons', name: 'coupons', component: () => import('@/views/coupons/CouponListView.vue') },
      { path: 'coupons/create', name: 'coupon-create', component: () => import('@/views/coupons/CouponFormView.vue') },
      // Members
      { path: 'members', name: 'members', component: () => import('@/views/members/MemberListView.vue') },
      { path: 'members/:id', name: 'member-detail', component: () => import('@/views/members/MemberDetailView.vue') },
      { path: 'member-levels', name: 'member-levels', component: () => import('@/views/members/MemberLevelView.vue') },
      // Inventory
      { path: 'inventory', name: 'inventory', component: () => import('@/views/inventory/InventoryLevelView.vue') },
      { path: 'transfers', name: 'transfers', component: () => import('@/views/inventory/TransferListView.vue') },
      // Stores
      { path: 'stores', name: 'stores', component: () => import('@/views/stores/StoreListView.vue') },
      // Dining tables (QR ordering)
      { path: 'tables', name: 'tables', component: () => import('@/views/stores/TableListView.vue') },
      { path: 'tables/print', name: 'tables-print', component: () => import('@/views/stores/TablePrintView.vue') },
      // Guest orders monitor
      { path: 'guest-orders', name: 'guest-orders', component: () => import('@/views/stores/GuestOrderListView.vue') },
      // Users
      { path: 'users', name: 'users', component: () => import('@/views/stores/UserListView.vue') },
      // Orders
      { path: 'orders', name: 'orders', component: () => import('@/views/orders/OrderListView.vue') },
      { path: 'orders/:id', name: 'order-detail', component: () => import('@/views/orders/OrderDetailView.vue') },
      // Reports
      { path: 'reports', name: 'reports', component: () => import('@/views/reports/ReportsView.vue') },
    ],
  },
]

export const router = createRouter({
  history: createWebHistory(),
  routes,
})

router.beforeEach((to) => {
  const auth = useAuthStore()
  if (!to.meta.public && !auth.isAuthenticated) {
    return { name: 'login', query: { redirect: to.fullPath } }
  }
})
