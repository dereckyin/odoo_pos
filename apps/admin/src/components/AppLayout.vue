<template>
  <a-layout style="min-height: 100vh">
    <a-layout-sider v-model:collapsed="collapsed" collapsible :trigger="null" breakpoint="lg" class="app-sider" @collapse="collapsed = $event">
      <div class="logo">
        <span v-if="!collapsed">點餐趣｜後台</span>
        <span v-else>點</span>
      </div>
      <a-menu v-model:selectedKeys="selectedKeys" v-model:openKeys="openKeys" theme="dark" mode="inline">
        <a-menu-item key="dashboard" @click="$router.push({ name: 'dashboard' })">
          <template #icon><DashboardOutlined /></template>
          <span>總覽</span>
        </a-menu-item>
        <a-sub-menu key="product-group">
          <template #icon><ShoppingOutlined /></template>
          <template #title>產品管理</template>
          <a-menu-item key="products" @click="$router.push({ name: 'products' })">商品列表</a-menu-item>
          <a-menu-item key="categories" @click="$router.push({ name: 'categories' })">分類管理</a-menu-item>
          <a-menu-item key="option-groups" @click="$router.push({ name: 'option-groups' })">選項庫</a-menu-item>
          <a-menu-item key="product-import" @click="$router.push({ name: 'product-import' })">CSV 匯入</a-menu-item>
        </a-sub-menu>
        <a-sub-menu key="marketing-group">
          <template #icon><GiftOutlined /></template>
          <template #title>行銷方案</template>
          <a-menu-item key="promotions" @click="$router.push({ name: 'promotions' })">促銷活動</a-menu-item>
          <a-menu-item key="coupons" @click="$router.push({ name: 'coupons' })">優惠券</a-menu-item>
        </a-sub-menu>
        <a-sub-menu key="member-group">
          <template #icon><TeamOutlined /></template>
          <template #title>會員管理</template>
          <a-menu-item key="members" @click="$router.push({ name: 'members' })">會員列表</a-menu-item>
          <a-menu-item key="member-levels" @click="$router.push({ name: 'member-levels' })">等級管理</a-menu-item>
          <a-menu-item key="loyalty-settings" @click="$router.push({ name: 'loyalty-settings' })">忠誠度設定</a-menu-item>
          <a-menu-item key="member-webhooks" @click="$router.push({ name: 'member-webhooks' })">Webhook</a-menu-item>
        </a-sub-menu>
        <a-sub-menu key="inventory-group">
          <template #icon><InboxOutlined /></template>
          <template #title>庫存管理</template>
          <a-menu-item key="inventory" @click="$router.push({ name: 'inventory' })">庫存水位</a-menu-item>
          <a-menu-item key="transfers" @click="$router.push({ name: 'transfers' })">調撥管理</a-menu-item>
          <a-menu-item key="supplier-list" @click="$router.push({ name: 'supplier-list' })">供應商</a-menu-item>
          <a-menu-item key="purchase-orders" @click="$router.push({ name: 'purchase-orders' })">採購單</a-menu-item>
        </a-sub-menu>
        <a-sub-menu key="store-group">
          <template #icon><ShopOutlined /></template>
          <template #title>門店帳號</template>
          <a-menu-item key="stores" @click="$router.push({ name: 'stores' })">門店管理</a-menu-item>
          <a-menu-item v-if="modules.onlineOrdering" key="tables" @click="$router.push({ name: 'tables' })">桌位管理</a-menu-item>
          <a-menu-item key="users" @click="$router.push({ name: 'users' })">使用者管理</a-menu-item>
        </a-sub-menu>
        <a-sub-menu v-if="modules.onlineOrdering" key="table-order-group">
          <template #icon><QrcodeOutlined /></template>
          <template #title>桌邊點餐</template>
          <a-menu-item
            v-if="modules.guestOrdersEnabled"
            key="guest-orders"
            @click="$router.push({ name: 'guest-orders' })"
          >
            {{ modules.onlineOrdering && modules.marketplace ? '桌邊/網路訂單' : '桌邊訂單' }}
          </a-menu-item>
        </a-sub-menu>
        <a-sub-menu v-if="modules.marketplace" key="marketplace-group">
          <template #icon><ShopOutlined /></template>
          <template #title>市集上架</template>
          <a-menu-item key="marketplace-settings" @click="$router.push({ name: 'marketplace-settings' })">市集設定</a-menu-item>
          <a-menu-item
            v-if="modules.guestOrdersEnabled && !modules.onlineOrdering"
            key="guest-orders"
            @click="$router.push({ name: 'guest-orders' })"
          >
            網路訂單
          </a-menu-item>
        </a-sub-menu>
        <a-sub-menu key="order-group">
          <template #icon><FileTextOutlined /></template>
          <template #title>訂單報表</template>
          <a-menu-item key="orders" @click="$router.push({ name: 'orders' })">訂單查詢</a-menu-item>
          <a-menu-item key="reports" @click="$router.push({ name: 'reports' })">銷售報表</a-menu-item>
        </a-sub-menu>
        <a-sub-menu v-if="modules.businessIntelligence" key="bi-group">
          <template #icon><BarChartOutlined /></template>
          <template #title>商業智慧</template>
          <a-menu-item key="analytics-sales" @click="$router.push({ name: 'analytics-sales' })">銷售分析</a-menu-item>
          <a-menu-item key="analytics-stores" @click="$router.push({ name: 'analytics-stores' })">門店績效</a-menu-item>
          <a-menu-item key="analytics-context" @click="$router.push({ name: 'analytics-context' })">環境洞察</a-menu-item>
          <a-menu-item key="analytics-members" @click="$router.push({ name: 'analytics-members' })">會員分析</a-menu-item>
        </a-sub-menu>
        <a-menu-item v-if="auth.isPureTenantUser || auth.actingTenantId" key="tenant-settings" @click="$router.push({ name: 'tenant-settings' })">
          <template #icon><SafetyOutlined /></template>
          <span>租戶設定</span>
        </a-menu-item>
      </a-menu>
      <div class="sider-footer">
        <span v-if="!collapsed" class="sider-version">{{ APP_VERSION }}</span>
        <span v-else class="sider-version sider-version--mini">{{ APP_VERSION }}</span>
      </div>
    </a-layout-sider>
    <a-layout>
      <a-alert
        v-if="auth.isPlatformSuper && auth.actingTenantId"
        type="info"
        show-icon
        banner
        :message="`您正在代管：${auth.actingTenantName}`"
      >
        <template #action>
          <a-button size="small" type="primary" ghost @click="exitTenantMode">返回平台營運</a-button>
        </template>
      </a-alert>
      <a-layout-header class="app-header">
        <a-button type="text" @click="collapsed = !collapsed">
          <template #icon>
            <MenuUnfoldOutlined v-if="collapsed" />
            <MenuFoldOutlined v-else />
          </template>
        </a-button>
        <a-breadcrumb :style="{ flex: 1, marginLeft: '16px' }">
          <a-breadcrumb-item v-for="item in breadcrumbs" :key="item">{{ item }}</a-breadcrumb-item>
        </a-breadcrumb>
        <a-dropdown>
          <a class="user-link" @click.prevent>
            <UserOutlined style="margin-right: 6px" />{{ auth.displayName || auth.username }}
          </a>
          <template #overlay>
            <a-menu>
              <a-menu-item @click="handleLogout">登出</a-menu-item>
            </a-menu>
          </template>
        </a-dropdown>
        <a-tag v-if="auth.isPlatformSuper && auth.actingTenantId" color="blue" style="margin-left: 12px">代管模式</a-tag>
        <a-tag v-else-if="!auth.isPlatformSuper" color="green" style="margin-left: 12px">商家後台</a-tag>
        <span class="header-version">{{ APP_VERSION }}</span>
      </a-layout-header>
      <a-layout-content class="app-content">
        <router-view />
      </a-layout-content>
    </a-layout>
  </a-layout>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useTenantModulesStore } from '@/stores/tenantModules'
import { APP_VERSION } from '@/version'
import {
  DashboardOutlined, ShoppingOutlined, GiftOutlined, TeamOutlined,
  InboxOutlined, ShopOutlined, FileTextOutlined, BarChartOutlined, UserOutlined,
  MenuFoldOutlined, MenuUnfoldOutlined, QrcodeOutlined,
  SafetyOutlined,
} from '@ant-design/icons-vue'

const collapsed = ref(false)
const auth = useAuthStore()
const modules = useTenantModulesStore()
const route = useRoute()
const router = useRouter()

const nameMap: Record<string, string> = {
  dashboard: '總覽',
  products: '商品列表', 'product-create': '新增商品', 'product-edit': '編輯商品', 'product-import': 'CSV 匯入',
  categories: '分類管理', 'option-groups': '選項庫',
  promotions: '促銷活動', 'promotion-create': '新增活動', 'promotion-edit': '編輯活動',
  coupons: '優惠券', 'coupon-create': '新增優惠券',
  members: '會員列表', 'member-detail': '會員詳情', 'member-levels': '等級管理',
  inventory: '庫存水位', transfers: '調撥管理',
  'supplier-list': '供應商', 'purchase-orders': '採購單', 'purchase-order-detail': '採購單詳情',
  stores: '門店管理', users: '使用者管理',
  tables: '桌位管理', 'tables-print': 'QR 列印',
  'guest-orders': '桌邊訂單',
  orders: '訂單查詢', 'order-detail': '訂單詳情', reports: '銷售報表',
  'analytics-sales': '銷售分析', 'analytics-stores': '門店績效', 'analytics-context': '環境洞察',
  'tenant-settings': '租戶設定',
  'platform-applications': '店家申請審核', 'platform-tenants': '租戶管理',
  'platform-marketplace': '市集上架審核', 'platform-alliances': '聯盟管理',
  'platform-plans': '訂閱方案', 'platform-dashboard': '營運總覽',
  'marketplace-settings': '市集上架', 'analytics-members': '會員分析',
}

const selectedKeys = ref<string[]>([])
const openKeys = ref<string[]>([])

const breadcrumbs = computed(() => {
  const name = route.name as string
  return name ? [nameMap[name] || name] : []
})

watch(() => route.name, (name) => {
  if (name) selectedKeys.value = [name as string]
  const n = name as string
  if (['inventory', 'transfers', 'supplier-list', 'purchase-orders', 'purchase-order-detail'].includes(n)) {
    if (!openKeys.value.includes('inventory-group')) {
      openKeys.value = [...openKeys.value, 'inventory-group']
    }
  }
  if (['orders', 'order-detail', 'reports'].includes(n)) {
    if (!openKeys.value.includes('order-group')) {
      openKeys.value = [...openKeys.value, 'order-group']
    }
  }
  if (['analytics-sales', 'analytics-stores', 'analytics-context'].includes(n)) {
    if (!openKeys.value.includes('bi-group')) {
      openKeys.value = [...openKeys.value, 'bi-group']
    }
  }
}, { immediate: true })

watch(
  () => [auth.isMerchantMode, auth.actingTenantId, auth.tenantId] as const,
  ([merchantMode]) => {
    if (merchantMode) {
      modules.fetch()
    } else {
      modules.reset()
    }
  },
  { immediate: true },
)

onMounted(() => {
  if (auth.isMerchantMode) {
    modules.fetch()
  }
})

function handleLogout() {
  auth.logout()
  router.push({ name: 'login' })
}

function exitTenantMode() {
  auth.exitTenantMode()
  router.push({ name: 'platform-dashboard' })
}
</script>

<style scoped>
.logo {
  height: 48px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #fff;
  font-size: 16px;
  font-weight: 600;
  letter-spacing: 2px;
  border-bottom: 1px solid rgba(255,255,255,.1);
}
.app-header {
  background: #fff;
  padding: 0 24px;
  display: flex;
  align-items: center;
  box-shadow: 0 1px 4px rgba(0,0,0,.08);
}
.app-content {
  margin: 16px;
  padding: 24px;
  background: #fff;
  border-radius: 8px;
  min-height: 360px;
}
.user-link {
  color: rgba(0,0,0,.65);
}
.app-sider {
  position: relative;
}
.app-sider :deep(.ant-layout-sider-children) {
  display: flex;
  flex-direction: column;
  min-height: 100%;
}
.app-sider :deep(.ant-menu) {
  flex: 1;
  overflow-y: auto;
}
.header-version {
  margin-left: 16px;
  font-size: 12px;
  color: rgba(0, 0, 0, 0.35);
  white-space: nowrap;
}
.sider-footer {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  padding: 12px 16px;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
  text-align: center;
}
.sider-version {
  font-size: 12px;
  color: rgba(255, 255, 255, 0.45);
  letter-spacing: 0.5px;
}
.sider-version--mini {
  font-size: 10px;
}
</style>
