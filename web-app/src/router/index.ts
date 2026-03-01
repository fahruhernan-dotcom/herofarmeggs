import { createRouter, createWebHistory } from 'vue-router'
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
                    path: 'orders',
                    name: 'orders',
                    component: () => import('../views/Orders.vue'),
                    meta: { requiresAuth: true }
                },
                {
                    path: 'suppliers',
                    name: 'suppliers',
                    component: () => import('../views/Suppliers.vue'),
                    meta: { requiresAuth: true, requiresAdmin: true }
                },
                {
                    path: 'employees',
                    name: 'employees',
                    component: () => import('../views/Employees.vue'),
                    meta: { requiresAuth: true, requiresAdmin: true }
                },
                {
                    path: 'profile',
                    name: 'profile',
                    component: () => import('../views/Profile.vue'),
                    meta: { requiresAuth: true }
                }
            ]
        }
    ]
})

import { useAuthStore } from '../stores/auth';

// Navigation Guard
router.beforeEach(async (to, _from, next) => {
    const authStore = useAuthStore();

    // Ensure auth is initialized
    if (authStore.loading) {
        await authStore.initialize();
    }

    const isLoggedIn = !!authStore.user;

    // 1. If trying to access login page while logged in, redirect home
    if (to.path === '/login' && isLoggedIn) {
        return next('/');
    }

    // 2. If trying to access protected page while NOT logged in, redirect login
    if (to.meta.requiresAuth && !isLoggedIn) {
        return next('/login');
    }

    // 3. If trying to access admin page and user is NOT admin, redirect home
    if (to.meta.requiresAdmin) {
        if (!authStore.isAdmin) {
            return next('/');
        }
    }

    next();
});

export default router;
