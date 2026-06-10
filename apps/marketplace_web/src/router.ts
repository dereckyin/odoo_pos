import { createRouter, createWebHistory } from 'vue-router'

export const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    { path: '/', name: 'home', component: () => import('@/views/HomeView.vue') },
    { path: '/search', name: 'search', component: () => import('@/views/SearchView.vue') },
    { path: '/stores', name: 'stores', component: () => import('@/views/StoresView.vue') },
    { path: '/store/:slug', name: 'store', component: () => import('@/views/StoreView.vue') },
    { path: '/cart', name: 'cart', component: () => import('@/views/CartView.vue') },
    { path: '/checkout', name: 'checkout', component: () => import('@/views/CheckoutView.vue') },
    { path: '/orders/:orderId', name: 'order-status', component: () => import('@/views/OrderStatusView.vue') },
    { path: '/order-groups/:groupId', name: 'order-group', component: () => import('@/views/OrderGroupView.vue') },
    { path: '/member', name: 'member', component: () => import('@/views/MemberCenterView.vue') },
  ],
})
