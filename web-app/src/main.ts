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
    console.error('Global error:', err, info)
    // Don't crash — just log
}

app.config.warnHandler = (msg, _instance, _trace) => {
    console.warn('Global warn:', msg)
    // Suppress non-critical warnings
}

// Handle unhandled promise rejections:
window.addEventListener('unhandledrejection', (event) => {
    if (event.reason?.name === 'AbortError') {
        event.preventDefault() // Silence audio play/pause conflicts
        return
    }
    console.error('Unhandled promise rejection:', event.reason)
    event.preventDefault() // Prevent console error spam
})

// Initialize Auth before mounting
const authStore = useAuthStore()
authStore.initialize().then(() => {
    app.mount('#app')
})
