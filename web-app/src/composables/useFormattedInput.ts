import { ref } from 'vue'
import { toTitleCase } from '../utils/formatters'

/**
 * Drop-in replacement for ref() on text fields that auto-formats to Title Case
 * Usage:
 *   const customerName = useTitleCaseInput('')
 *   <input v-model="customerName" />
 */
export function useTitleCaseInput(initialValue = '') {
    const value = ref(toTitleCase(initialValue))
    return value
}

/**
 * For objects with multiple fields. Returns reactive form
 * and a getFormatted() helper to retrieve sanitized output on submit.
 * Usage:
 *   const { form, getFormatted } = useTitleCaseForm({ name: '', address: '', notes: '' })
 */
export function useTitleCaseForm<T extends Record<string, any>>(fields: T) {
    const form = ref({ ...fields })

    function getFormatted() {
        const result = {} as any
        for (const [key, val] of Object.entries(form.value)) {
            result[key] = typeof val === 'string' ? toTitleCase(val) : val
        }
        return result as T
    }

    return { form, getFormatted }
}
