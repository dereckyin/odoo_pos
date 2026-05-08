<template>
  <a-layout style="min-height: 100vh">
    <a-layout-sider v-model:collapsed="collapsed" collapsible :trigger="null" breakpoint="lg" @collapse="collapsed = $event">
      <div class="logo">
        <span v-if="!collapsed">POS 管理後台</span>
        <span v-else>POS</span>
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
        </a-sub-menu>
        <a-sub-menu key="inventory-group">
          <template #icon><InboxOutlined /></template>
          <template #title>庫存管理</template>
          <a-menu-item key="inventory" @click="$router.push({ name: 'inventory' })">庫存水位</a-menu-item>
          <a-menu-item key="transfers" @click="$router.push({ name: 'transfers' })">調撥管理</a-menu-item>
        </a-sub-menu>
        <a-sub-menu key="store-group">
          <template #icon><ShopOutlined /></template>
          <template #title>門店帳號</template>
          <a-menu-item key="stores" @click="$router.push({ name: 'stores' })">門店管理</a-menu-item>
          <a-menu-item key="tables" @click="$router.push({ name: 'tables' })">桌位管理</a-menu-item>
          <a-menu-item key="users" @click="$router.push({ name: 'users' })">使用者管理</a-menu-item>
        </a-sub-menu>
        <a-sub-menu key="qr-group">
          <template #icon><QrcodeOutlined /></template>
          <template #title>QR 點餐</template>
          <a-menu-item key="guest-orders" @click="$router.push({ name: 'guest-orders' })">桌邊訂單</a-menu-item>
        </a-sub-menu>
        <a-sub-menu key="order-group">
          <template #icon><FileTextOutlined /></template>
          <template #title>訂單報表</template>
          <a-menu-item key="orders" @click="$router.push({ name: 'orders' })">訂單查詢</a-menu-item>
          <a-menu-item key="reports" @click="$router.push({ name: 'reports' })">銷售報表</a-menu-item>
        </a-sub-menu>
      </a-menu>
    </a-layout-sider>
    <a-layout>
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
      </a-layout-header>
      <a-layout-content class="app-content">
        <router-view />
      </a-layout-content>
    </a-layout>
  </a-layout>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import {
  DashboardOutlined, ShoppingOutlined, GiftOutlined, TeamOutlined,
  InboxOutlined, ShopOutlined, FileTextOutlined, UserOutlined,
  MenuFoldOutlined, MenuUnfoldOutlined, QrcodeOutlined,
} from '@ant-design/icons-vue'

const collapsed = ref(false)
const auth = useAuthStore()
const route = useRoute()
const router = useRouter()

const nameMap: Record<string, string> = {
  dashboard: '總覽',
  products: '商品列表', 'product-create': '新增商品', 'product-edit': '編輯商品', 'product-import': 'CSV 匯入',
  categories: '分類管理',
  promotions: '促銷活動', 'promotion-create': '新增活動', 'promotion-edit': '編輯活動',
  coupons: '優惠券', 'coupon-create': '新增優惠券',
  members: '會員列表', 'member-detail': '會員詳情', 'member-levels': '等級管理',
  inventory: '庫存水位', transfers: '調撥管理',
  stores: '門店管理', users: '使用者管理',
  tables: '桌位管理', 'tables-print': 'QR 列印',
  'guest-orders': '桌邊訂單',
  orders: '訂單查詢', 'order-detail': '訂單詳情', reports: '銷售報表',
}

const selectedKeys = ref<string[]>([])
const openKeys = ref<string[]>([])

const breadcrumbs = computed(() => {
  const name = route.name as string
  return name ? [nameMap[name] || name] : []
})

watch(() => route.name, (name) => {
  if (name) selectedKeys.value = [name as string]
}, { immediate: true })

function handleLogout() {
  auth.logout()
  router.push({ name: 'login' })
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
</style>
