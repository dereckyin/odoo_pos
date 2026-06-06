import { createRouter, createWebHistory, type RouteRecordRaw } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useTenantModulesStore } from '@/stores/tenantModules'

const ONLINE_ORDERING_ROUTES = new Set([
  'guest-orders',
  'tables',
  'tables-print',
])

const MARKETPLACE_ROUTES = new Set([
  'marketplace-settings',
  'guest-orders',
])

const BUSINESS_INTELLIGENCE_ROUTES = new Set([
  'analytics-sales',
  'analytics-stores',
  'analytics-context',
  'analytics-members',
])

const CONSIGNMENT_BOOKS_ROUTES = new Set([
  'books',
  'book-receive',
  'book-settings',
  'book-reports',
])

const merchantChildren: RouteRecordRaw[] = [
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
  { path: 'tables', name: 'tables', component: () => import('@/views/stores/TableListView.vue') },
  { path: 'tables/print', name: 'tables-print', component: () => import('@/views/stores/TablePrintView.vue') },
  { path: 'guest-orders', name: 'guest-orders', component: () => import('@/views/stores/GuestOrderListView.vue') },
  { path: 'users', name: 'users', component: () => import('@/views/stores/UserListView.vue') },
  // Orders
  { path: 'orders', name: 'orders', component: () => import('@/views/orders/OrderListView.vue') },
  { path: 'orders/:id', name: 'order-detail', component: () => import('@/views/orders/OrderDetailView.vue') },
  { path: 'reports', name: 'reports', component: () => import('@/views/reports/ReportsView.vue') },
  { path: 'books', name: 'books', component: () => import('@/views/books/BookListView.vue') },
  { path: 'books/receive', name: 'book-receive', component: () => import('@/views/books/BookReceiveView.vue') },
  { path: 'books/settings', name: 'book-settings', component: () => import('@/views/books/ConsignmentSettingsView.vue') },
  { path: 'books/reports', name: 'book-reports', component: () => import('@/views/books/ConsignmentReportView.vue') },
  // Business intelligence
  { path: 'analytics/sales', name: 'analytics-sales', component: () => import('@/views/analytics/SalesAnalyticsView.vue') },
  { path: 'analytics/stores', name: 'analytics-stores', component: () => import('@/views/analytics/StorePerformanceView.vue') },
  { path: 'analytics/context', name: 'analytics-context', component: () => import('@/views/analytics/EnvironmentInsightsView.vue') },
  { path: 'analytics/members', name: 'analytics-members', component: () => import('@/views/members/MemberAnalyticsView.vue') },
  { path: 'tenant-settings', name: 'tenant-settings', component: () => import('@/views/tenant/TenantSettingsView.vue') },
  { path: 'marketplace-settings', name: 'marketplace-settings', component: () => import('@/views/tenant/MarketplaceSettingsView.vue') },
]

const platformChildren: RouteRecordRaw[] = [
  { path: '', name: 'platform-dashboard', component: () => import('@/views/platform/PlatformDashboardView.vue'), meta: { platformOnly: true } },
  { path: 'applications', name: 'platform-applications', component: () => import('@/views/platform/ApplicationListView.vue'), meta: { platformOnly: true } },
  { path: 'tenants', name: 'platform-tenants', component: () => import('@/views/platform/TenantListView.vue'), meta: { platformOnly: true } },
  { path: 'plans', name: 'platform-plans', component: () => import('@/views/platform/PlanListView.vue'), meta: { platformOnly: true } },
  { path: 'marketplace', name: 'platform-marketplace', component: () => import('@/views/platform/MarketplaceApplicationsView.vue'), meta: { platformOnly: true } },
  { path: 'alliances', name: 'platform-alliances', component: () => import('@/views/platform/AllianceListView.vue'), meta: { platformOnly: true } },
]

const routes: RouteRecordRaw[] = [
  { path: '/login', name: 'login', component: () => import('@/views/auth/LoginView.vue'), meta: { public: true } },
  { path: '/signup', name: 'signup', component: () => import('@/views/auth/SignupView.vue'), meta: { public: true } },
  {
    path: '/platform',
    component: () => import('@/components/PlatformLayout.vue'),
    meta: { platformShell: true },
    children: platformChildren,
  },
  {
    path: '/',
    component: () => import('@/components/AppLayout.vue'),
    meta: { merchantShell: true },
    children: merchantChildren,
  },
]

export const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes,
})

function isPlatformRoute(to: { path: string; meta: Record<string, unknown> }) {
  return to.path.startsWith('/platform') || !!to.meta.platformOnly
}

function isMerchantRoute(to: { path: string; meta: Record<string, unknown>; name?: string | symbol | null }) {
  if (to.meta.public) return false
  if (isPlatformRoute(to)) return false
  return to.name !== 'login' && to.name !== 'signup'
}

router.beforeEach(async (to) => {
  const auth = useAuthStore()
  if (!to.meta.public && !auth.isAuthenticated) {
    return { name: 'login', query: { redirect: to.fullPath } }
  }

  if (isPlatformRoute(to) && !auth.isPlatformSuper) {
    return { name: 'dashboard' }
  }

  if (auth.isPlatformSuper && !auth.actingTenantId && isMerchantRoute(to)) {
    return { name: 'platform-dashboard' }
  }

  const routeName = to.name as string | undefined
  if (
    routeName &&
    isMerchantRoute(to) &&
    (
      ONLINE_ORDERING_ROUTES.has(routeName) ||
      MARKETPLACE_ROUTES.has(routeName) ||
      BUSINESS_INTELLIGENCE_ROUTES.has(routeName) ||
      CONSIGNMENT_BOOKS_ROUTES.has(routeName)
    )
  ) {
    const modules = useTenantModulesStore()
    if (!modules.loaded) {
      await modules.fetch()
    }
    if (routeName === 'guest-orders' && !modules.guestOrdersEnabled) {
      return { name: 'dashboard' }
    }
    if (
      (routeName === 'tables' || routeName === 'tables-print') &&
      !modules.onlineOrdering
    ) {
      return { name: 'dashboard' }
    }
    if (routeName === 'marketplace-settings' && !modules.marketplace) {
      return { name: 'dashboard' }
    }
    if (BUSINESS_INTELLIGENCE_ROUTES.has(routeName) && !modules.businessIntelligence) {
      return { name: 'dashboard' }
    }
    if (CONSIGNMENT_BOOKS_ROUTES.has(routeName) && !modules.consignmentBooks) {
      return { name: 'dashboard' }
    }
  }
})

export function postLoginRoute(auth: ReturnType<typeof useAuthStore>, redirect?: string | null) {
  if (redirect && redirect !== '/') return redirect
  if (auth.isPlatformSuper && !auth.actingTenantId) return '/platform'
  return '/'
}
