<template>
  <div class="layout">
    <header class="topbar">
      <div class="brand">點餐趣 網頁收銀</div>
      <nav>
        <router-link to="/">收銀</router-link>
        <router-link to="/kds">KDS</router-link>
        <router-link to="/tables">開桌</router-link>
        <router-link to="/printer">
          印表機
          <span v-if="!printer.allReady" class="dot-warn" :title="printerHint"></span>
        </router-link>
      </nav>
      <div class="user">
        <span>{{ auth.displayName || auth.username }}</span>
        <button class="link" @click="logout">登出</button>
      </div>
    </header>
    <main class="main">
      <router-view />
    </main>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { usePrinterStore } from '@/stores/printer'

const auth = useAuthStore()
const router = useRouter()
const printer = usePrinterStore()

const printerHint = computed(() =>
  printer.supported ? '有印表機尚未配對，請到「印表機」頁面配對' : '此環境不支援 WebUSB 列印',
)

onMounted(() => {
  printer.start()
})

onUnmounted(() => {
  printer.stop()
})

function logout() {
  printer.stop()
  auth.logout()
  router.push('/login')
}
</script>

<style scoped>
.layout {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}
.topbar {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 10px 16px;
  background: #001529;
  color: #fff;
}
.brand {
  font-weight: 700;
}
nav {
  display: flex;
  gap: 12px;
  flex: 1;
}
nav a {
  color: rgba(255, 255, 255, 0.75);
  text-decoration: none;
  padding: 4px 8px;
  border-radius: 4px;
}
nav a.router-link-active {
  color: #fff;
  background: rgba(255, 255, 255, 0.12);
}
.dot-warn {
  display: inline-block;
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: #faad14;
  margin-left: 4px;
  vertical-align: middle;
}
.user {
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 0.9rem;
}
button.link {
  background: none;
  border: none;
  color: #91caff;
  padding: 0;
}
.main {
  flex: 1;
  min-height: 0;
}
</style>
