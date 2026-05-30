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
    path: '/signup',
    name: 'signup',
    component: () => import('@/views/auth/SignupView.vue'),
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
      { path: 'option-groups', name: 'option-groups', component: () => import('@/views/products/OptionGroupListView.vue') },
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
      { path: 'loyalty-settings', name: 'loyalty-settings', component: () => import('@/views/members/LoyaltySettingsView.vue') },
      { path: 'member-webhooks', name: 'member-webhooks', component: () => import('@/views/members/WebhookSettingsView.vue') },
      // Inventory
      { path: 'inventory', name: 'inventory', component: () => import('@/views/inventory/InventoryLevelView.vue') },
      { path: 'transfers', name: 'transfers', component: () => import('@/views/inventory/TransferListView.vue') },
      { path: 'purchasing/suppliers', name: 'supplier-list', component: () => import('@/views/purchasing/SupplierListView.vue') },
      { path: 'purchasing/orders', name: 'purchase-orders', component: () => import('@/views/purchasing/PurchaseOrderListView.vue') },
      { path: 'purchasing/orders/:id', name: 'purchase-order-detail', component: () => import('@/views/purchasing/PurchaseOrderDetailView.vue') },
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
      // Business intelligence
      { path: 'analytics/sales', name: 'analytics-sales', component: () => import('@/views/analytics/SalesAnalyticsView.vue') },
      { path: 'analytics/stores', name: 'analytics-stores', component: () => import('@/views/analytics/StorePerformanceView.vue') },
      { path: 'analytics/context', name: 'analytics-context', component: () => import('@/views/analytics/EnvironmentInsightsView.vue') },
      { path: 'analytics/members', name: 'analytics-members', component: () => import('@/views/members/MemberAnalyticsView.vue') },
      // Tenant self-service settings (payment / invoice / audit / usage)
      { path: 'tenant-settings', name: 'tenant-settings', component: () => import('@/views/tenant/TenantSettingsView.vue') },
      { path: 'marketplace-settings', name: 'marketplace-settings', component: () => import('@/views/tenant/MarketplaceSettingsView.vue') },
      // Platform super-admin
      {
        path: 'platform/marketplace',
        name: 'platform-marketplace',
        component: () => import('@/views/platform/MarketplaceApplicationsView.vue'),
        meta: { platformOnly: true },
      },
      {
        path: 'platform/applications',
        name: 'platform-applications',
        component: () => import('@/views/platform/ApplicationListView.vue'),
        meta: { platformOnly: true },
      },
      {
        path: 'platform/tenants',
        name: 'platform-tenants',
        component: () => import('@/views/platform/TenantListView.vue'),
        meta: { platformOnly: true },
      },
      {
        path: 'platform/alliances',
        name: 'platform-alliances',
        component: () => import('@/views/platform/AllianceListView.vue'),
        meta: { platformOnly: true },
      },
    ],
  },
]

export const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes,
})

router.beforeEach((to) => {
  const auth = useAuthStore()
  if (!to.meta.public && !auth.isAuthenticated) {
    return { name: 'login', query: { redirect: to.fullPath } }
  }
  if (to.meta.platformOnly && !auth.isPlatformSuper) {
    return { name: 'dashboard' }
  }
})
