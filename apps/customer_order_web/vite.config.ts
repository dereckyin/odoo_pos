import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { resolve } from 'path'

// 生產環境掛在主網域子路徑（與管理後台同 host），避免兩套 Vue 搶同一個 / 路由。
// 開發 `npm run dev` 仍用根路徑 /，方便直接開 http://localhost:5174/order?t=...
export default defineConfig(({ command }) => ({
  base: command === 'serve' ? '/' : '/customer/',
  plugins: [vue()],
  resolve: {
    alias: {
      '@': resolve(__dirname, 'src'),
    },
  },
  server: {
    port: 5174,
    host: true,
    proxy: {
      '/api': {
        target: 'http://localhost:8000',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api/, ''),
      },
      '/uploads': {
        target: 'http://localhost:8000',
        changeOrigin: true,
      },
    },
  },
}))
