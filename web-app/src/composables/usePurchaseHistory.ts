import { ref, computed } from 'vue'
import { supabase } from '../lib/supabase'

export function usePurchaseHistory() {
  const purchases = ref<any[]>([])
  const isLoading = ref(false)
  const error = ref<string | null>(null)

  const totalPembelian = computed(() =>
    purchases.value.reduce((sum, p) => sum + (p.total_cost || 0), 0)
  )

  const totalButir = computed(() =>
    purchases.value
      .filter(p => p.isEgg)
      .reduce((sum, p) => sum + (p.total_eggs_bought || 0), 0)
  )

  const totalDebt = computed(() =>
    purchases.value.reduce((sum, p) => sum + (p.remaining_debt || 0), 0)
  )

  const monthlyTotal = computed(() => {
    const now = new Date()
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1).toISOString()
    return purchases.value
      .filter(p => (p.created_at || p.purchase_date || '') >= startOfMonth)
      .reduce((sum, p) => sum + (p.total_cost || 0), 0)
  })

  async function fetchPurchases(limit = 50, signal?: AbortSignal) {
    isLoading.value = true
    error.value = null

    try {
      const { data, error: err } = await supabase
        .from('stock_logs')
        .select(`
          id,
          change,
          unit_price,
          notes,
          note,
          created_at,
          egg_type,
          inventory:egg_type (
            id,
            label
          )
        `)
        .eq('log_type', 'arrival')
        .order('created_at', { ascending: false })
        .limit(limit)
        .abortSignal(signal as AbortSignal)

      if (err) throw err

      if (data) {
        purchases.value = data.map((log: any) => {
          const reason = log.notes || log.note || ''
          const totalHarga = (log.unit_price || 0) * Math.abs(log.change || 0)

          // Parse supplier dari notes
          let supplier = 'Supplier'
          if (reason.includes('Supplier:')) {
            supplier = reason.split('Supplier:')[1].trim()
          } else if (reason.startsWith('[')) {
            supplier = reason.slice(1, -1).trim()
          } else if (reason) {
            supplier = reason
          }

          // Flag isEgg: exclude anything with 'packaging'
          const eggType = (log.egg_type || '').toLowerCase()
          const isEgg = !eggType.includes('packaging')

          return {
            id: log.id,
            created_at: log.created_at,
            purchase_date: log.created_at,
            supplier,
            product_label: log.inventory?.label || log.egg_type || 'Produk',
            total_eggs_bought: Math.abs(log.change || 0),
            price_per_egg: log.unit_price || 0,
            total_cost: totalHarga,
            status: 'lunas',
            remaining_debt: 0,
            inventory: log.inventory,
            egg_type: log.egg_type,
            isEgg
          }
        })
      }
    } catch (e: any) {
      error.value = e.message || 'Failed to fetch purchases'
    } finally {
      isLoading.value = false
    }
  }

  return {
    purchases,
    totalPembelian,
    totalButir,
    totalDebt,
    monthlyTotal,
    isLoading,
    error,
    fetchPurchases
  }
}
