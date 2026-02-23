import { createRouter, createWebHistory } from 'vue-router'
import { supabase } from '../lib/supabase'
import MainLayout from '../layouts/MainLayout.vue'

const router = createRouter({
    history: createWebHistory(),
    routes: [
        {
            path: '/login',
            name: 'login',
            component: () => import('../views/Login.vue'),
            meta: { requiresAuth: false }
        },
        {
            path: '/',
            component: MainLayout,
            children: [
                {
                    path: '',
                    name: 'dashboard',
                    component: () => import('../views/Dashboard.vue'),
                    meta: { requiresAuth: true }
                },
                {
                    path: 'stock',
                    name: 'stock',
                    component: () => import('../views/Stock.vue'),
                    meta: { requiresAuth: true }
                },
                {
                    path: 'sales',
                    name: 'sales',
                    component: () => import('../views/Sales.vue'),
                    meta: { requiresAuth: true }
                },
                {
                    path: 'customers',
                    name: 'customers',
                    component: () => import('../views/Customers.vue'),
                    meta: { requiresAuth: true }
                },
                {
                    path: 'stickers',
                    name: 'stickers',
                    component: () => import('../views/StickerDesign.vue'),
                    meta: { requiresAuth: true }
                }
            ]
        }
    ]
})

// Authentication Guard
router.beforeEach(async (to, _from, next) => {
    const { data: { session } } = await supabase.auth.getSession()

    if (to.meta.requiresAuth && !session) {
        next('/login')
    } else if (to.path === '/login' && session) {
        next('/')
    } else {
        next()
    }
})

export default router
