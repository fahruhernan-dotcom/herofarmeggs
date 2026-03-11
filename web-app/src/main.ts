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

// Initialize Auth before mounting
const authStore = useAuthStore()
authStore.initialize().then(() => {
    app.mount('#app')
})
