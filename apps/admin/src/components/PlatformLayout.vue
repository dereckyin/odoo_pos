<template>
  <a-layout style="min-height: 100vh">
    <a-layout-sider v-model:collapsed="collapsed" collapsible :trigger="null" breakpoint="lg" class="app-sider" @collapse="collapsed = $event">
      <div class="logo">
        <span v-if="!collapsed">點餐趣｜平台營運</span>
        <span v-else>台</span>
      </div>
      <a-menu v-model:selectedKeys="selectedKeys" v-model:openKeys="openKeys" theme="dark" mode="inline">
        <a-menu-item key="platform-dashboard" @click="$router.push({ name: 'platform-dashboard' })">
          <template #icon><DashboardOutlined /></template>
          <span>營運總覽</span>
        </a-menu-item>
        <a-sub-menu key="onboard-group">
          <template #icon><ShopOutlined /></template>
          <template #title>商家入駐</template>
          <a-menu-item key="platform-applications" @click="$router.push({ name: 'platform-applications' })">申請審核</a-menu-item>
          <a-menu-item key="platform-tenants" @click="$router.push({ name: 'platform-tenants' })">租戶管理</a-menu-item>
          <a-menu-item key="platform-plans" @click="$router.push({ name: 'platform-plans' })">訂閱方案</a-menu-item>
        </a-sub-menu>
        <a-sub-menu key="market-group">
          <template #icon><QrcodeOutlined /></template>
          <template #title>美食市集</template>
          <a-menu-item key="platform-marketplace" @click="$router.push({ name: 'platform-marketplace' })">上架審核</a-menu-item>
          <a-menu-item key="platform-marketplace-banners" @click="$router.push({ name: 'platform-marketplace-banners' })">Banner／活動</a-menu-item>
        </a-sub-menu>
        <a-menu-item key="platform-alliances" @click="$router.push({ name: 'platform-alliances' })">
          <template #icon><TeamOutlined /></template>
          <span>聯盟管理</span>
        </a-menu-item>
      </a-menu>
      <div class="sider-footer">
        <span v-if="!collapsed" class="sider-version">{{ APP_VERSION }}</span>
        <span v-else class="sider-version sider-version--mini">{{ APP_VERSION }}</span>
      </div>
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
        <a-space>
          <a-button type="primary" ghost @click="tenantPickerOpen = true">進入商家後台</a-button>
          <a-tag color="purple">平台營運</a-tag>
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
        </a-space>
        <span class="header-version">{{ APP_VERSION }}</span>
      </a-layout-header>
      <a-layout-content class="app-content">
        <router-view />
      </a-layout-content>
    </a-layout>

    <TenantPickerModal v-model:open="tenantPickerOpen" />
  </a-layout>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { APP_VERSION } from '@/version'
import TenantPickerModal from '@/components/TenantPickerModal.vue'
import {
  DashboardOutlined, ShopOutlined, TeamOutlined, UserOutlined,
  MenuFoldOutlined, MenuUnfoldOutlined, QrcodeOutlined,
} from '@ant-design/icons-vue'

const collapsed = ref(false)
const auth = useAuthStore()
const route = useRoute()
const router = useRouter()
const tenantPickerOpen = ref(false)

const nameMap: Record<string, string> = {
  'platform-dashboard': '營運總覽',
  'platform-applications': '申請審核',
  'platform-tenants': '租戶管理',
  'platform-plans': '訂閱方案',
  'platform-marketplace': '市集上架審核',
  'platform-marketplace-banners': 'Banner／活動',
  'platform-alliances': '聯盟管理',
}

const selectedKeys = ref<string[]>([])
const openKeys = ref<string[]>(['onboard-group', 'market-group'])

const breadcrumbs = computed(() => {
  const name = route.name as string
  return name ? [nameMap[name] || name] : []
})

watch(() => route.name, (name) => {
  if (name) selectedKeys.value = [name as string]
  const n = name as string
  if (['platform-applications', 'platform-tenants', 'platform-plans'].includes(n)) {
    if (!openKeys.value.includes('onboard-group')) {
      openKeys.value = [...openKeys.value, 'onboard-group']
    }
  }
  if (n === 'platform-marketplace' && !openKeys.value.includes('market-group')) {
    openKeys.value = [...openKeys.value, 'market-group']
  }
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
  font-size: 15px;
  font-weight: 600;
  letter-spacing: 1px;
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
