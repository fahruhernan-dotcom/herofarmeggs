import { toTitleCase } from '../utils/formatters'
import type { Directive } from 'vue'

export const vTitleCase: Directive<HTMLElement> = {
    mounted(el) {
        // Determine if the element itself is input/textarea or if it contains one
        const input = (el.tagName === 'INPUT' || el.tagName === 'TEXTAREA')
            ? (el as HTMLInputElement | HTMLTextAreaElement)
            : el.querySelector<HTMLInputElement | HTMLTextAreaElement>('input, textarea')

        if (!input) return

        // Format on blur (when user finishes typing) to prevent immediate disruption
        input.addEventListener('blur', () => {
            const formatted = toTitleCase(input.value)
            if (formatted !== input.value) {
                input.value = formatted
                // Update any v-model bindings attached to this input
                input.dispatchEvent(new Event('input', { bubbles: true }))
                input.dispatchEvent(new Event('change', { bubbles: true }))
            }
        })
    }
}
