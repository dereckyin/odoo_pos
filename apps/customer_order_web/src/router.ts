import {
  createRouter,
  createWebHistory,
  type RouteLocationGeneric,
  type RouteLocationRaw,
} from 'vue-router'

function redirectToOrder(to: RouteLocationGeneric): RouteLocationRaw {
  return { path: '/order', query: { ...to.query } }
}

export const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    { path: '/', redirect: redirectToOrder },
    {
      path: '/order',
      name: 'order',
      component: () => import('@/views/MenuView.vue'),
    },
    {
      path: '/cart',
      name: 'cart',
      component: () => import('@/views/CartView.vue'),
    },
    {
      path: '/status/:orderId',
      name: 'status',
      component: () => import('@/views/StatusView.vue'),
      props: true,
    },
    {
      path: '/no-token',
      name: 'no-token',
      component: () => import('@/views/NoTokenView.vue'),
    },
    {
      path: '/:pathMatch(.*)*',
      redirect: redirectToOrder,
    },
  ],
})
