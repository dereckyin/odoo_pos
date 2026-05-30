/// <reference types="vite/client" />
declare const __APP_VERSION__: string
declare const __APP_RELEASE_DATE__: string
declare const __PRODUCT_NAME__: string

declare module '*.vue' {
  import type { DefineComponent } from 'vue'
  const component: DefineComponent<{}, {}, any>
  export default component
}

interface ImportMetaEnv {
  readonly VITE_API_BASE_URL?: string
  readonly VITE_CUSTOMER_BASE_URL?: string
}
interface ImportMeta {
  readonly env: ImportMetaEnv
}
