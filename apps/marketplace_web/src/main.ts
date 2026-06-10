import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import { router } from './router'
import { registerMemberTokenGetter } from './api'
import { getMemberToken } from './stores/member'
import './styles/main.css'

registerMemberTokenGetter(getMemberToken)

createApp(App).use(createPinia()).use(router).mount('#app')
