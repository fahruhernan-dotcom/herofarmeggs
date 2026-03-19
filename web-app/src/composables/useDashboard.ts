import { ref, reactive, computed } from 'vue'
import { supabase } from '../lib/supabase'
import { toCanonicalId, normalizeGrade } from '../constants/grades'
import { useAuthStore } from '../stores/auth'
import { withTimeout } from '../utils/safeAsync'

/**
 * Hero Farm Dashboard — All data fetching + computed KPIs
 */
export function useDashboard() {
    const authStore = useAuthStore()
    const loading = ref(true)
    const inventory = ref<any[]>([])
    const allSales = ref<any[]>([])
    const customers = ref<any[]>([])
    const financeEntries = ref<any[]>([])
    const piutangList = ref<any[]>([])
    const kpiData = ref<any>({
        total_revenue: 0,
        gross_profit: 0,
        total_piutang: 0,
        total_utang: 0,
        stock_value: 0
    })

    // Reset logic
    const impactCounts = reactive({
        sales: 0,
        customers: 0,
        logs: 0,
        finance: 0
    })

    // ─── HELPERS ─────────────────────────
    function getPeriodStats(salesArr: any[], offsetMonths = 0) {
        const now = new Date()
        const start = new Date(now.getFullYear(), now.getMonth() - offsetMonths, 1)
        const end = new Date(now.getFullYear(), now.getMonth() - offsetMonths + 1, 0, 23, 59, 59)

        const filtered = salesArr.filter((s: any) => {
            if (!s.created_at) return false
            const d = new Date(s.created_at)
            return d >= start && d <= end
        })

        return {
            total: filtered.reduce((acc: number, s: any) => acc + (s.total_price || 0), 0),
            count: filtered.length,
            paid: filtered.filter((s: any) => s.payment_status === 'paid').reduce((acc: number, s: any) => acc + (s.total_price || 0), 0),
            pending: filtered.filter((s: any) => s.payment_status === 'pending').reduce((acc: number, s: any) => acc + (s.total_price || 0), 0),
            void: filtered.filter((s: any) => s.payment_status === 'voided').reduce((acc: number, s: any) => acc + (s.total_price || 0), 0),
            items: filtered.flatMap((s: any) => s.sale_items || [])
        }
    }

    function calculateGrowth(current: number, previous: number) {
        if (previous === 0) return current > 0 ? { val: 100, status: 'new' } : { val: 0, status: 'none' }
        const diff = ((current - previous) / previous) * 100
        return { val: Math.abs(diff).toFixed(1), status: diff >= 0 ? 'up' : 'down' }
    }

    // ─── COMPUTED ────────────────────────
    const eggInventory = computed(() => {
        const canonicalItems = ['hero', 'salted_egg']
        return inventory.value.filter((i: any) => canonicalItems.includes(i.id) || canonicalItems.includes(toCanonicalId(i.id)))
    })
    const packagingInventory = computed(() => inventory.value.filter((i: any) => i.item_type === 'packaging'))

    // Laba Kotor / Revenue - derived from sales this month
    const currentMonthSales = computed(() => {
        const now = new Date()
        const start = new Date(now.getFullYear(), now.getMonth(), 1)
        const end = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59)
        return allSales.value.filter((s: any) => {
            if (!s.created_at || s.payment_status === 'voided') return false
            const d = new Date(s.created_at)
            return d >= start && d <= end
        })
    })

    const totalRevenue = computed(() => {
        return currentMonthSales.value.reduce((sum: number, s: any) => sum + (s.total_price || 0), 0)
    })

    // Total Modal (HPP) = Sum of total_hpp from sales table
    const totalCost = computed(() => {
        return currentMonthSales.value.reduce((sum: number, s: any) => sum + (s.total_hpp || 0), 0)
    })

    // Laba Kotor = Revenue - HPP
    const grossProfit = computed(() => {
        return totalRevenue.value - totalCost.value
    })

    // Net Position = Revenue - HPP
    const netPosition = computed(() => {
        return totalRevenue.value - totalCost.value
    })

    // Persentase modal kembali
    const modalKembaliPct = computed(() => {
        const cost = totalCost.value
        if (cost === 0) return totalRevenue.value > 0 ? 100 : 0
        return Math.min((totalRevenue.value / cost) * 100, 100)
    })

    const revenueWidget = computed(() => {
        const current = getPeriodStats(allSales.value, 0)
        const previous = getPeriodStats(allSales.value, 1)
        const growth = calculateGrowth(current.total, previous.total)
        return { current, growth }
    })

    // Margin % = Net Profit / Revenue × 100
    const grossMarginPct = computed(() => {
        const rev = totalRevenue.value
        if (rev === 0) return 0
        return (grossProfit.value / rev) * 100
    })

    const totalTransaksi = computed(() => {
        return getPeriodStats(allSales.value, 0).count
    })

    const totalPacksSold = computed(() => {
        const items = getPeriodStats(allSales.value, 0).items
        return items.reduce((a: number, i: any) => a + (i.quantity || 0), 0)
    })

    // Sales chart data — precisely last 7 days
    const salesChartData = computed(() => {
        const today = new Date()
        const sevenDaysAgo = new Date()
        sevenDaysAgo.setDate(today.getDate() - 6)

        const labels: string[] = []
        const heroData: number[] = []
        const saltedData: number[] = []
        
        const hariNames = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']

        for (let i = 0; i < 7; i++) {
            const d = new Date(sevenDaysAgo)
            d.setDate(d.getDate() + i)
            const dateStr = d.toISOString().split('T')[0] as string
            labels.push(hariNames[d.getDay()]!)

            const daySales = allSales.value.filter((s: any) => {
                if (!s.created_at || s.payment_status === 'voided') return false
                return s.created_at?.startsWith(dateStr) ?? false
            })

            const dayItems = daySales.flatMap((s: any) => s.sale_items || [])
            heroData.push(dayItems.filter((i: any) => normalizeGrade(i.egg_type || i.inventory_id) === 'hero').reduce((a: number, i: any) => a + (i.revenue || i.subtotal || ((i.packs_sold || i.quantity || 0) * (i.price_per_pack || i.unit_price || 0))), 0))
            saltedData.push(dayItems.filter((i: any) => normalizeGrade(i.egg_type || i.inventory_id) === 'salted_egg').reduce((a: number, i: any) => a + (i.revenue || i.subtotal || ((i.packs_sold || i.quantity || 0) * (i.price_per_pack || i.unit_price || 0))), 0))
        }

        return { labels, heroData, saltedData }
    })

    // Top Customers (this month)
    const topCustomers = computed(() => {
        const customerMap: Record<string, { name: string; total: number }> = {}
        const now = new Date()
        allSales.value
            .filter((s: any) => {
                if (!s.created_at) return false
                const d = new Date(s.created_at)
                return d.getMonth() === now.getMonth() && d.getFullYear() === now.getFullYear() && s.payment_status !== 'voided'
            })
            .forEach((s: any) => {
                const cust = customers.value.find((c: any) => c?.id === s.customer_id)
                if (!s.customer_id || !cust) return
                if (!customerMap[s.customer_id]) {
                    customerMap[s.customer_id] = { name: cust.name, total: 0 }
                }
                const entry = customerMap[s.customer_id]
                if (entry) entry.total += s.total_price || 0
            })

        return Object.values(customerMap)
            .sort((a, b) => b.total - a.total)
            .slice(0, 5)
    })

    // Cash Flow (30 days)
    const cashFlowData = computed(() => {
        const dates: string[] = []
        const income: number[] = []
        const expense: number[] = []
        const today = new Date()

        for (let i = 29; i >= 0; i--) {
            const d = new Date(today)
            d.setDate(d.getDate() - i)
            const dateStr = d.toISOString().split('T')[0] as string
            dates.push(`${d.getDate()}/${d.getMonth() + 1}`)

            const dayFin = financeEntries.value.filter((f: any) => f.entry_date === dateStr)
            income.push(dayFin.filter((f: any) => f.entry_type === 'income').reduce((a: number, f: any) => a + Number(f.amount), 0))
            expense.push(dayFin.filter((f: any) => f.entry_type === 'expense').reduce((a: number, f: any) => a + Number(f.amount), 0))
        }

        const totalIncome = income.reduce((a, b) => a + b, 0)
        const totalExpense = expense.reduce((a, b) => a + b, 0)
        const net = totalIncome - totalExpense

        return { dates, income, expense, totalIncome, totalExpense, net }
    })

    // Piutang Aging — uses piutang table directly
    const piutangBuckets = computed(() => {
        const now = new Date()

        const buckets = {
            paid: { count: 0, total: 0 },
            week1: { count: 0, total: 0 },
            week2: { count: 0, total: 0 },
            overdue: { count: 0, total: 0 }
        }

        piutangList.value.forEach((p: any) => {
            const remaining = Number(p.remaining ?? p.remaining_amount ?? 0)
            if (remaining <= 0) {
                // Lunas
                buckets.paid.count++
                buckets.paid.total += Number(p.total_amount || 0)
            } else {
                // Active piutang — age by due_date or created_at
                const refDate = new Date(p.due_date || p.created_at)
                const diffDays = Math.floor((now.getTime() - refDate.getTime()) / (1000 * 3600 * 24))
                if (diffDays <= 7) {
                    buckets.week1.count++
                    buckets.week1.total += remaining
                } else if (diffDays <= 14) {
                    buckets.week2.count++
                    buckets.week2.total += remaining
                } else {
                    buckets.overdue.count++
                    buckets.overdue.total += remaining
                }
            }
        })

        return buckets
    })

    // Stock potential revenue
    const potentialRevenue = computed(() => {
        return eggInventory.value.reduce((total: number, item: any) => {
            const packs = Math.floor((item.current_stock || 0) / 10)
            const pricePerPack = item.base_price_per_pack || 0
            return total + (packs * pricePerPack)
        }, 0)
    })

    // ─── FETCH ──────────────────────────
    async function fetchData(signal?: AbortSignal) {
        loading.value = true
        try {
            const [
                { data: stocks },
                { data: sales },
                { data: cust },
                { data: fin },
                { data: kpis },
                { data: piutangData }
            ] = await withTimeout(Promise.all([
                supabase.from('inventory').select('*').abortSignal(signal as AbortSignal),
                supabase.from('sales').select('*, sale_items(*)').order('created_at', { ascending: false }).abortSignal(signal as AbortSignal),
                supabase.from('customers').select('*').eq('is_deleted', false).abortSignal(signal as AbortSignal),
                supabase.from('finance_entries').select('*').order('entry_date', { ascending: false }).abortSignal(signal as AbortSignal),
                supabase.rpc('get_dashboard_kpis').abortSignal(signal as AbortSignal),
                supabase.from('piutang').select('id, remaining, total_amount, customer_name, due_date, status, created_at').eq('status', 'belum_bayar').abortSignal(signal as AbortSignal)
            ]), 12000, 'dashboard-main-fetch')

            if (stocks) inventory.value = stocks
            if (sales) allSales.value = sales
            if (cust) customers.value = cust
            if (fin) financeEntries.value = fin
            if (kpis) kpiData.value = kpis
            if (piutangData) piutangList.value = piutangData

            if (authStore.isAdmin) {
                const [
                    { count: sCount },
                    { count: cCount },
                    { count: lCount },
                    { count: fCount }
                ] = await withTimeout(Promise.all([
                    supabase.from('sales').select('*', { count: 'exact', head: true }).abortSignal(signal as AbortSignal),
                    supabase.from('customers').select('*', { count: 'exact', head: true }).abortSignal(signal as AbortSignal),
                    supabase.from('stock_logs').select('*', { count: 'exact', head: true }).abortSignal(signal as AbortSignal),
                    supabase.from('finance_entries').select('*', { count: 'exact', head: true }).abortSignal(signal as AbortSignal)
                ]), 10000, 'dashboard-counts')
                impactCounts.sales = sCount || 0
                impactCounts.customers = cCount || 0
                impactCounts.logs = lCount || 0
                impactCounts.finance = fCount || 0
            }
        } finally {
            loading.value = false
        }
    }

    // ─── REALTIME ───────────────────────
    let inventorySubscription: any = null

    function setupRealtime() {
        inventorySubscription = supabase
            .channel('dashboard-updates')
            .on('postgres_changes', { event: '*', schema: 'public', table: 'inventory' }, () => fetchData())
            .on('postgres_changes', { event: '*', schema: 'public', table: 'sales' }, () => fetchData())
            .on('postgres_changes', { event: '*', schema: 'public', table: 'piutang' }, () => fetchData())
            .subscribe()
    }

    function cleanup() {
        if (inventorySubscription) inventorySubscription.unsubscribe()
    }

    return {
        loading,
        inventory,
        eggInventory,
        packagingInventory,
        allSales,
        customers,
        financeEntries,
        kpiData,
        impactCounts,
        netPosition,
        totalRevenue,
        totalCost,
        modalKembaliPct,
        revenueWidget,
        grossProfit,
        grossMarginPct,
        totalTransaksi,
        totalPacksSold,
        salesChartData,
        topCustomers,
        cashFlowData,
        piutangBuckets,
        potentialRevenue,
        fetchData,
        setupRealtime,
        cleanup
    }
}
