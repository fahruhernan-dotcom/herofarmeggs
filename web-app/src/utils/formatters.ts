/**
 * Hero Farm — Shared Formatters
 * Used across all dashboard components to prevent NaN/undefined display bugs.
 * 
 * DESIGN TOKEN RULES:
 * - ALL money values → formatCurrency()
 * - ALL numbers → DM Mono font
 * - Grade names: Hero / Medium / Small (NEVER Standard Size, Telur Asin, Salted)
 */

/**
 * Capitalize each word — Indonesian-aware
 * Examples:
 *   "ibu sari"        → "Ibu Sari"
 *   "boyolali eggs"   → "Boyolali Eggs"
 *   "stok telah habis"→ "Stok Telah Habis"
 *   "FAS-TOP"         → "Fas-Top"  (handles hyphen)
 *   "  spasi  lebih " → "Spasi Lebih"  (trims + cleans)
 */
export function toTitleCase(str: string | null | undefined): string {
    if (!str) return ''
    return str
        .trim()
        .toLowerCase()
        .replace(/\s+/g, ' ')           // collapse multiple spaces
        .split(' ')
        .map(word =>
            word
                .split('-')                  // handle hyphenated words
                .map(part => part.charAt(0).toUpperCase() + part.slice(1))
                .join('-')
        )
        .join(' ')
}

/**
 * Format a value as Indonesian Rupiah currency.
 * Returns "Rp 0" for NaN, null, or undefined values.
 */
export function formatCurrency(value: number | string | null | undefined): string {
    const num = typeof value === 'string' ? parseFloat(value) : value
    if (num === null || num === undefined || isNaN(num)) return 'Rp 0'
    return new Intl.NumberFormat('id-ID', {
        style: 'currency',
        currency: 'IDR',
        minimumFractionDigits: 0,
        maximumFractionDigits: 0
    }).format(num)
}

/**
 * Format currency in compact form: "Rp 70rb", "Rp 1,2jt"
 */
export function formatCompactCurrency(value: number | null | undefined): string {
    const num = value ?? 0
    if (isNaN(num)) return 'Rp 0'
    if (Math.abs(num) >= 1_000_000) {
        return `Rp ${(num / 1_000_000).toFixed(1).replace('.0', '')}jt`
    }
    if (Math.abs(num) >= 1_000) {
        return `Rp ${(num / 1_000).toFixed(0)}rb`
    }
    return `Rp ${num.toLocaleString('id-ID')}`
}

/**
 * Format percentage. Returns "0%" for NaN.
 */
export function formatPct(value: number | null | undefined): string {
    const num = value ?? 0
    if (isNaN(num)) return '0%'
    return `${num.toFixed(1)}%`
}

/**
 * GRADE CONSTANTS — Single source of truth
 * NEVER use: 'Standard Size', 'Telur Asin', 'Hero Size (>65G)', 'Salted', 'STD', 'ASIN'
 */
export const GRADES = {
    hero: {
        id: 'hero_size',
        display: 'Hero',
        accent: '#f59e0b',
        size: '>65g'
    },
    medium: {
        id: 'standard_size',
        display: 'Medium',
        accent: '#8b5cf6',
        size: '55-65g'
    },
    small: {
        id: 'salted_egg',
        display: 'Small',
        accent: '#38bdf8',
        size: '<55g'
    }
} as const

/**
 * Get display name from inventory ID
 */
export const GRADE_LABELS: Record<string, string> = {
    'hero_size': 'Hero',
    'standard_size': 'Medium',
    'salted_egg': 'Small',
    'hero': 'Hero',
    'medium': 'Medium',
    'small': 'Small'
}

export function getGradeLabel(id: string): string {
    return GRADE_LABELS[id] || id
}

/**
 * Get grade accent color from inventory ID
 */
export function getGradeAccent(id: string): string {
    if (id === 'hero_size' || id === 'hero') return '#f59e0b'
    if (id === 'standard_size' || id === 'medium') return '#8b5cf6'
    if (id === 'salted_egg' || id === 'small') return '#38bdf8'
    return '#64748b'
}

/**
 * Format a date string to Indonesian short format
 */
export function formatDateShort(dateStr: string): string {
    return new Date(dateStr).toLocaleDateString('id-ID', {
        day: 'numeric',
        month: 'short'
    })
}

/**
 * Format stock number with Indonesian separator
 */
export function formatStock(value: number | null | undefined): string {
    if (value === null || value === undefined || isNaN(value)) return '0'
    return value.toLocaleString('id-ID')
}

/**
 * Format date relatively (e.g. "2 jam yang lalu")
 */
export function formatRelativeDate(dateStr: string | null | undefined): string {
    if (!dateStr) return '-'
    const date = new Date(dateStr)
    const now = new Date()
    const diffInSeconds = Math.floor((now.getTime() - date.getTime()) / 1000)

    if (diffInSeconds < 60) return 'Baru saja'
    if (diffInSeconds < 3600) return `${Math.floor(diffInSeconds / 60)} menit lalu`
    if (diffInSeconds < 86400) return `${Math.floor(diffInSeconds / 3600)} jam lalu`
    if (diffInSeconds < 172800) return 'Kemarin'

    return date.toLocaleDateString('id-ID', {
        day: 'numeric',
        month: 'short'
    })
}

/**
 * Format exact time with day and month
 */
export function formatExactTime(dateStr: string | null | undefined): string {
    if (!dateStr) return '-'
    return new Date(dateStr).toLocaleString('id-ID', {
        day: '2-digit',
        month: 'short',
        hour: '2-digit',
        minute: '2-digit'
    })
}
