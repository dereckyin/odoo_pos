import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { readFileSync } from 'fs'
import { resolve } from 'path'

const version = JSON.parse(
  readFileSync(resolve(__dirname, '../../version.json'), 'utf-8'),
) as { displayVersion: string; releaseDate: string; productName: string }

export default defineConfig({
  plugins: [vue()],
  define: {
    __APP_VERSION__: JSON.stringify(version.displayVersion),
    __APP_RELEASE_DATE__: JSON.stringify(version.releaseDate),
    __PRODUCT_NAME__: JSON.stringify(version.productName),
  },
  resolve: {
    alias: {
      '@': resolve(__dirname, 'src'),
    },
  },
  server: {
    port: 5173,
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
})
