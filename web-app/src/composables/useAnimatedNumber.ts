import { ref, watch, onMounted } from 'vue'

/**
 * Composable for animating a number from 0 to its target value.
 * Uses requestAnimationFrame with easeOutExpo for smooth count-up.
 */
export function useAnimatedNumber(target: () => number, duration = 800) {
    const displayed = ref(0)
    let hasAnimated = false

    function easeOutExpo(t: number): number {
        return t === 1 ? 1 : 1 - Math.pow(2, -10 * t)
    }

    function animate(from: number, to: number) {
        const start = performance.now()
        const diff = to - from

        function step(now: number) {
            const elapsed = now - start
            const progress = Math.min(elapsed / duration, 1)
            displayed.value = Math.round(from + diff * easeOutExpo(progress))
            if (progress < 1) {
                requestAnimationFrame(step)
            }
        }

        requestAnimationFrame(step)
    }

    onMounted(() => {
        // Initial animation from 0 to target
        const val = target()
        if (val !== 0 && !hasAnimated) {
            hasAnimated = true
            animate(0, val)
        } else {
            displayed.value = val
        }
    })

    // Watch for subsequent changes (animate smoothly between values)
    watch(target, (newVal, oldVal) => {
        if (hasAnimated) {
            animate(oldVal ?? 0, newVal)
        } else {
            hasAnimated = true
            animate(0, newVal)
        }
    })

    return displayed
}
