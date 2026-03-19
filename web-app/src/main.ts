import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import router from './router'
import { useAuthStore } from './stores/auth'
import './assets/mobile.css'

import { vTitleCase } from './directives/titlecase'

const app = createApp(App)
const pinia = createPinia()

app.use(pinia)
app.use(router)

app.directive('titlecase', vTitleCase)

// Global Error Boundaries
app.config.errorHandler = (err, _instance, info) => {
    console.error('Global error caught:', err, info)
    // Don't let errors propagate and break navigation
}

app.config.warnHandler = (msg, _instance, trace) => {
    console.warn('Global warn:', msg, trace)
}

// Handle unhandled promise rejections:
window.addEventListener('unhandledrejection', (event) => {
    if (
        event.reason?.name === 'AbortError' ||
        event.reason?.message?.includes('aborted')
    ) {
        event.preventDefault()
        console.debug('AbortError suppressed — safe navigation abort')
        return
    }
    console.warn('Unhandled rejection:', event.reason)
})

// Initialize Auth before mounting
const authStore = useAuthStore()
authStore.initialize().then(() => {
    app.mount('#app')
})
