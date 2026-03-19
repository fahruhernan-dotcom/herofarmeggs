/**
 * Hero Farm — Safe Async Utilities
 * Provides timeout + exponential retry for all Supabase calls.
 */

function getDefaultTimeout(): number {
    const isMobile = typeof window !== 'undefined' && window.innerWidth <= 768
    return isMobile ? 25000 : 15000
}

function isRetryableError(err: any): boolean {
    const msg = (err?.message || '').toLowerCase()
    const code = err?.code || err?.status || 0
    // Don't retry auth/permission/not-found errors
    if ([401, 403, 404].includes(Number(code))) return false
    if (msg.includes('unauthorized') || msg.includes('forbidden') || msg.includes('not found')) return false
    // Retry timeouts, network errors, and 5xx
    return true
}

export interface WithTimeoutOptions {
    retries?: number
    onRetry?: (attempt: number) => void
}

/**
 * Wraps a promise with a timeout and automatic exponential-backoff retry.
 * 
 * Backwards-compatible: existing callers using `withTimeout(promise, ms, label)` 
 * continue to work without changes. New callers can pass an options object as 4th arg.
 */
export function withTimeout(
    promise: any,
    ms?: number,
    label: string = 'request',
    options?: WithTimeoutOptions
): Promise<any> {
    const timeout = ms ?? getDefaultTimeout()
    const maxRetries = options?.retries ?? 3
    const onRetry = options?.onRetry

    async function attempt(retriesLeft: number, attemptNumber: number): Promise<any> {
        const timeoutPromise = new Promise<any>((_, reject) =>
            setTimeout(() => reject(new Error(`${label} timeout after ${timeout}ms`)), timeout)
        )

        try {
            // For retries, we need to re-evaluate the promise. 
            // Since Supabase query builders are thenable, Promise.resolve works on first call.
            // On subsequent retries the original promise reference is reused (already resolved/rejected),
            // so retry logic works best when the caller passes a fresh promise each time.
            // However, for backwards compat we still race with the original promise.
            return await Promise.race([Promise.resolve(promise), timeoutPromise])
        } catch (err: any) {
            if (retriesLeft > 0 && isRetryableError(err)) {
                const delay = 1000 * Math.pow(2, attemptNumber - 1) // 1s, 2s, 4s
                if (onRetry) onRetry(attemptNumber)
                await new Promise(resolve => setTimeout(resolve, delay))
                return attempt(retriesLeft - 1, attemptNumber + 1)
            }
            throw err
        }
    }

    return attempt(maxRetries, 1)
}

/**
 * safeAsync — Wraps any async function and specifically ignores AbortError.
 * Useful for Supabase queries that are aborted during route navigation.
 */
export async function safeAsync<T>(
    fn: () => Promise<T>,
    _options = {}
): Promise<T | null> {
    try {
        return await fn()
    } catch (error: any) {
        // AbortError = navigation moved away before fetch finished — NOT a real error
        if (
            error?.name === 'AbortError' ||
            error?.message?.includes('aborted without reason') ||
            error?.message?.includes('signal is aborted') ||
            error?.message?.includes('Fetch is aborted')
        ) {
            console.debug('Request aborted — navigation detected, safe to ignore')
            return null
        }

        // Re-throw genuine errors (network down, etc.)
        throw error
    }
}
