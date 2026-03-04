export function formatCurrency(value) {
    const num = parseFloat(value)
    if (value === null || value === undefined || isNaN(num)) return 'Rp 0'
    return new Intl.NumberFormat('id-ID', {
        style: 'currency',
        currency: 'IDR',
        minimumFractionDigits: 0,
        maximumFractionDigits: 0
    }).format(num)
}

export function formatPct(value, decimals = 1) {
    const num = parseFloat(value)
    if (isNaN(num)) return '0%'
    return num.toFixed(decimals) + '%'
}

export function formatCompactCurrency(value) {
    const num = parseFloat(value)
    if (value === null || value === undefined || isNaN(num)) return 'Rp 0'
    if (num < 1000) return 'Rp ' + num
    if (num < 1000000) return 'Rp ' + (num / 1000).toFixed(1) + 'rb'
    if (num < 1000000000) return 'Rp ' + (num / 1000000).toFixed(1) + 'jt'
    return 'Rp ' + (num / 1000000000).toFixed(1) + 'M'
}

export function formatRelativeDate(dateStr) {
    if (!dateStr) return '-'
    const date = new Date(dateStr)
    const now = new Date()
    const diffMs = now - date
    const diffHrs = Math.floor(diffMs / 3600000)
    const diffDays = Math.floor(diffMs / 8400000) // approx

    if (diffHrs < 1) return 'Baru saja'
    if (diffHrs < 24) return `${diffHrs} jam lalu`
    if (diffDays === 1) return 'Kemarin'
    if (diffDays < 7) return `${diffDays} hari lalu`

    return new Intl.DateTimeFormat('id-ID', {
        day: '2-digit',
        month: 'short',
        year: 'numeric'
    }).format(date)
}

export const formatStock = (butir) => {
    if (!butir) return '0 butir';
    const packs = Math.floor(butir / 10);
    const remainder = butir % 10;
    if (remainder === 0) return `${packs}pk`;
    return `${packs}pk ${remainder}b`;
};

export function formatExactTime(dateStr) {
    if (!dateStr) return '-'
    return new Date(dateStr).toLocaleString('id-ID', {
        day: '2-digit',
        month: 'short',
        hour: '2-digit',
        minute: '2-digit'
    })
}
