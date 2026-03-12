import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useAppStore = defineStore('app', () => {
    const globalLoading = ref(false)
    const loadingLabel = ref('')
    const loadingTimers = new Map<string, ReturnType<typeof setTimeout>>()

    function startLoading(key: string, label = 'Loading...') {
        globalLoading.value = true
        loadingLabel.value = label

        // Auto-reset after 10 seconds no matter what
        if (loadingTimers.has(key)) clearTimeout(loadingTimers.get(key))

        loadingTimers.set(key, setTimeout(() => {
            console.warn(`Auto-reset loading: ${key}`)
            stopLoading(key)
        }, 10000))
    }

    function stopLoading(key: string) {
        if (loadingTimers.has(key)) {
            clearTimeout(loadingTimers.get(key)!)
            loadingTimers.delete(key)
        }
        if (loadingTimers.size === 0) {
            globalLoading.value = false
            loadingLabel.value = ''
        }
    }

    return { globalLoading, loadingLabel, startLoading, stopLoading }
})
