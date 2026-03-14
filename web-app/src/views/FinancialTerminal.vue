<template>
<div class="ft-root">

  <!-- PAGE HEADER -->
  <div class="ft-header">
    <div class="ft-header-left">
      <span class="ft-eyebrow">MANAGEMENT · FINANCE</span>
      <h1 class="ft-title">Financial Terminal</h1>
      <p class="ft-desc">Real-time P&L, arus kas, dan analisis profitabilitas</p>
    </div>
    <div class="ft-header-right">
      <div class="period-selector">
        <button v-for="p in periods" :key="p.value"
          class="period-btn" :class="{ active: selectedPeriod === p.value }"
          @click="selectedPeriod = p.value; fetchData()">
          {{ p.label }}
        </button>
      </div>
      <button class="sync-btn" @click="fetchData" :class="{ loading: isSyncing }">
        <span class="sync-icon">↻</span>
        {{ isSyncing ? 'SYNCING...' : 'SYNC DATA' }}
      </button>
    </div>
  </div>

  <!-- TAB BAR -->
  <div class="ft-tabs">
    <button v-for="tab in tabs" :key="tab.id"
      class="ft-tab" :class="{ active: activeTab === tab.id }"
      @click="activeTab = tab.id">
      <span>{{ tab.icon }}</span>
      <span>{{ tab.label }}</span>
    </button>
  </div>

  <!-- ═══════════ TAB: P&L OVERVIEW ═══════════ -->
  <div v-if="activeTab === 'pnl'" class="tab-content">

    <!-- KPI ROW 1: 4 cards -->
    <div class="kpi-grid-4">
      <div class="kpi-card" style="--accent: #f59e0b">
        <div class="kpi-top">
          <span class="kpi-label">TOTAL PENDAPATAN</span>
          <span class="kpi-icon">💰</span>
        </div>
        <p class="kpi-val" style="color:#f59e0b">{{ fmt(pnlData.totalRevenue) }}</p>
        <p class="kpi-sub">{{ allSalesData?.length ?? 0 }} transaksi periode ini</p>
      </div>

      <div class="kpi-card" :style="'--accent:' + (pnlData.grossProfit >= 0 ? '#10b981' : '#ef4444')">
        <div class="kpi-top">
          <span class="kpi-label">LABA KOTOR</span>
          <span class="kpi-icon">📈</span>
        </div>
        <p class="kpi-val" :style="'color:' + (pnlData.grossProfit >= 0 ? '#10b981' : '#ef4444')">
          {{ fmt(pnlData.grossProfit) }}
        </p>
        <p class="kpi-sub">Margin {{ pnlData.grossMargin }}% · HPP {{ fmt(pnlData.totalHPP) }}</p>
      </div>

      <div class="kpi-card" :style="'--accent:' + (totalUtang > 0 ? '#ef4444' : '#10b981')">
        <div class="kpi-top">
          <span class="kpi-label">UTANG SUPPLIER</span>
          <span class="kpi-icon">⚡</span>
        </div>
        <p class="kpi-val" :style="'color:' + (totalUtang > 0 ? '#ef4444' : 'rgba(255,255,255,0.3)')">
          {{ fmt(totalUtang) }}
        </p>
        <p class="kpi-sub">{{ totalUtang > 0 ? 'Ada kewajiban belum lunas' : 'Semua lunas ✓' }}</p>
      </div>

      <div class="kpi-card" :style="'--accent:' + (totalPiutang > 0 ? '#8b5cf6' : '#10b981')">
        <div class="kpi-top">
          <span class="kpi-label">PIUTANG AKTIF</span>
          <span class="kpi-icon">📋</span>
        </div>
        <p class="kpi-val" :style="'color:' + (totalPiutang > 0 ? '#8b5cf6' : 'rgba(255,255,255,0.3)')">
          {{ fmt(totalPiutang) }}
        </p>
        <p class="kpi-sub">{{ totalPiutang > 0 ? piutangList.length + ' invoice belum terbayar' : 'Semua lunas ✓' }}</p>
      </div>
    </div>

    <!-- KPI ROW 2: 2 cards -->
    <div class="kpi-grid-2">
      <div class="kpi-card" style="--accent:#38bdf8">
        <div class="kpi-top">
          <span class="kpi-label">NILAI STOK (ASET)</span>
          <span class="kpi-icon">📦</span>
        </div>
        <p class="kpi-val" style="color:#38bdf8">{{ fmt(nilaiStok) }}</p>
        <p class="kpi-sub">HPP × stok tersisa di gudang</p>
      </div>

      <div class="kpi-card" :style="'--accent:' + (netPosition >= 0 ? '#10b981' : '#ef4444')">
        <div class="kpi-top">
          <span class="kpi-label">NET POSITION</span>
          <span class="kpi-icon">⚖️</span>
        </div>
        <p class="kpi-val" :style="'color:' + (netPosition >= 0 ? '#10b981' : '#ef4444')">
          {{ netPosition >= 0 ? '+' : '' }}{{ fmt(netPosition) }}
        </p>
        <p class="kpi-sub">Revenue − HPP − Utang + Piutang + Stok</p>
      </div>
    </div>

    <!-- CHART -->
    <div class="chart-card">
      <div class="chart-head">
        <div>
          <h3 class="chart-title">Trend Kinerja Harian</h3>
          <p class="chart-sub">Revenue · HPP · Profit per hari dalam periode</p>
        </div>
        <div class="chart-legend">
          <span><span class="dot" style="background:#f59e0b"></span> Revenue</span>
          <span><span class="dot" style="background:#ef4444"></span> HPP</span>
          <span><span class="dot" style="background:#10b981"></span> Profit</span>
        </div>
      </div>
      <div v-if="!chartData.length || chartData.every(d => d.revenue === 0)" class="chart-empty">
        <div style="font-size:40px">📊</div>
        <p>Belum ada data penjualan di periode ini</p>
      </div>
      <div v-else class="chart-bars">
        <div v-for="d in chartData" :key="d.date" class="chart-bar-group">
          <div class="bar-wrap">
            <div class="bar revenue" :style="'height:' + barHeight(d.revenue) + 'px'" :title="fmt(d.revenue)"></div>
            <div class="bar hpp"     :style="'height:' + barHeight(d.hpp) + 'px'"     :title="fmt(d.hpp)"></div>
            <div class="bar profit"  :style="'height:' + barHeight(Math.max(d.profit,0)) + 'px'" :title="fmt(d.profit)"></div>
          </div>
          <span class="bar-label">{{ d.date }}</span>
        </div>
      </div>
    </div>

    <!-- P&L TABLE -->
    <div class="pnl-card">
      <div class="pnl-head">
        <h3 class="chart-title">Laporan Laba Rugi per Produk</h3>
        <span class="period-badge">{{ startDate }} — {{ endDate }}</span>
      </div>

      <div v-if="!productData.length" class="chart-empty">
        <div style="font-size:32px">📦</div>
        <p>Belum ada data produk di periode ini</p>
        <p style="font-size:11px;margin-top:4px">Pastikan sale_items.egg_type terisi dengan benar</p>
      </div>

      <table v-else class="data-table">
        <thead>
          <tr>
            <th>PRODUK</th>
            <th>PACK TERJUAL</th>
            <th>REVENUE</th>
            <th>HPP</th>
            <th>LABA KOTOR</th>
            <th>MARGIN</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="p in productData" :key="p.type">
            <td>
              <span class="product-chip" :class="p.type">{{ p.label }}</span>
            </td>
            <td class="mono">{{ p.packs }} pack</td>
            <td class="mono gold">{{ fmt(p.revenue) }}</td>
            <td class="mono red">{{ fmt(p.hpp) }}</td>
            <td class="mono" :class="p.profit >= 0 ? 'green' : 'red'">{{ fmt(p.profit) }}</td>
            <td>
              <div class="margin-bar">
                <div class="margin-fill" :style="'width:' + Math.min(p.margin, 100) + '%'"></div>
                <span class="margin-label">{{ p.margin }}%</span>
              </div>
            </td>
          </tr>
        </tbody>
      </table>

      <!-- Footer -->
      <div class="pnl-footer">
        <div>
          <p class="kpi-label">LABA KOTOR BERSIH</p>
          <p class="laba-big" :class="pnlData.grossProfit >= 0 ? 'green' : 'red'">
            {{ fmt(pnlData.grossProfit) }}
          </p>
        </div>
        <div style="text-align:right">
          <p class="kpi-label">MARGIN KESELURUHAN</p>
          <p class="laba-big gold">{{ pnlData.grossMargin }}%</p>
        </div>
      </div>
    </div>
  </div>

  <!-- ═══════════ TAB: CASH FLOW ═══════════ -->
  <div v-if="activeTab === 'cashflow'" class="tab-content">
    <div class="cf-grid">
      <!-- Money In -->
      <div class="cf-card">
        <div class="cf-head green-head">
          <span>↑ MONEY IN (PEMASUKAN)</span>
          <span class="mono">{{ fmt(totalMoneyIn) }}</span>
        </div>
        <div v-if="!moneyIn.length" class="chart-empty">
          <p>Belum ada pemasukan tunai tercatat</p>
        </div>
        <table v-else class="data-table">
          <thead><tr><th>TANGGAL</th><th>INVOICE</th><th>CUSTOMER</th><th>JUMLAH</th></tr></thead>
          <tbody>
            <tr v-for="s in moneyIn" :key="s.id">
              <td class="muted">{{ fmtDate(s.created_at) }}</td>
              <td class="mono" style="font-size:11px">{{ s.id?.substring(0,8) }}...</td>
              <td>{{ s.customers?.name ?? '—' }}</td>
              <td class="mono green">{{ fmt(s.total_revenue) }}</td>
            </tr>
          </tbody>
        </table>
        <div class="cf-total">
          <span>Subtotal Masuk</span>
          <span class="mono green">{{ fmt(totalMoneyIn) }}</span>
        </div>
      </div>

      <!-- Money Out -->
      <div class="cf-card">
        <div class="cf-head red-head">
          <span>↓ MONEY OUT (PENGELUARAN)</span>
          <span class="mono">{{ fmt(totalMoneyOut) }}</span>
        </div>
        <div v-if="!moneyOut.length" class="chart-empty">
          <p>Belum ada pembelian tercatat</p>
        </div>
        <table v-else class="data-table">
          <thead><tr><th>TANGGAL</th><th>SUPPLIER</th><th>TOTAL</th></tr></thead>
          <tbody>
            <tr v-for="p in moneyOut" :key="p.id">
              <td class="muted">{{ fmtDate(p.created_at) }}</td>
              <td>{{ p.suppliers?.name ?? '—' }}</td>
              <td class="mono red">{{ fmt(p.total_cost) }}</td>
            </tr>
          </tbody>
        </table>
        <div class="cf-total">
          <span>Subtotal Keluar</span>
          <span class="mono red">{{ fmt(totalMoneyOut) }}</span>
        </div>
      </div>
    </div>

    <!-- Net Cash Flow -->
    <div class="net-cf-card">
      <p class="kpi-label" style="text-align:center;margin-bottom:8px">NET CASH FLOW</p>
      <p class="laba-big" style="text-align:center;font-size:40px"
         :class="(totalMoneyIn - totalMoneyOut) >= 0 ? 'green' : 'red'">
        {{ (totalMoneyIn - totalMoneyOut) >= 0 ? '+' : '' }}{{ fmt(totalMoneyIn - totalMoneyOut) }}
      </p>
      <div class="cf-bar-wrap">
        <div class="cf-bar-in"  :style="'flex:' + totalMoneyIn"></div>
        <div class="cf-bar-out" :style="'flex:' + totalMoneyOut"></div>
      </div>
      <div class="cf-bar-labels">
        <span class="green">● Masuk {{ fmt(totalMoneyIn) }}</span>
        <span class="red">● Keluar {{ fmt(totalMoneyOut) }}</span>
      </div>
    </div>
  </div>

  <!-- ═══════════ TAB: RECEIVABLES ═══════════ -->
  <div v-if="activeTab === 'receivables'" class="tab-content">
    <div class="section-card">
      <div class="section-head">
        <h3 class="chart-title">Piutang Belum Terbayar</h3>
        <span class="kpi-val" style="color:#8b5cf6;font-size:20px">{{ fmt(totalPiutang) }}</span>
      </div>
      <div v-if="!piutangList.length" class="chart-empty">
        <div style="font-size:40px">🎉</div>
        <p>Tidak ada piutang aktif. Semua lunas!</p>
      </div>
      <table v-else class="data-table">
        <thead>
          <tr><th>CUSTOMER</th><th>JUMLAH</th><th>JATUH TEMPO</th><th>STATUS</th></tr>
        </thead>
        <tbody>
          <tr v-for="p in piutangList" :key="p.id">
            <td>{{ p.customer_name ?? '—' }}</td>
            <td class="mono violet">{{ fmt(p.remaining) }}</td>
            <td class="mono muted">{{ p.due_date ? fmtDate(p.due_date) : '—' }}</td>
            <td>
              <span class="status-chip" :class="getDueStatus(p.due_date)">
                {{ getDueLabel(p.due_date) }}
              </span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>

  <!-- ═══════════ TAB: PROFITABILITY MATRIX ═══════════ -->
  <div v-if="activeTab === 'profitability'" class="tab-content">
    <div class="section-card">
      <h3 class="chart-title" style="margin-bottom:20px">Matriks Profitabilitas Produk</h3>
      <div v-if="!productData.length" class="chart-empty">
        <div style="font-size:40px">📊</div>
        <p>Belum ada data produk untuk periode ini</p>
      </div>
      <div v-else class="product-matrix">
        <div v-for="p in productData" :key="p.type"
          class="matrix-card" :class="p.type">
          <div class="matrix-header">
            <span class="product-chip" :class="p.type">{{ p.label }}</span>
            <span class="mono" style="color:rgba(255,255,255,0.4);font-size:12px">{{ p.packs }} pack terjual</span>
          </div>
          <div class="matrix-stats">
            <div class="matrix-stat">
              <span class="kpi-label">REVENUE</span>
              <span class="mono gold">{{ fmt(p.revenue) }}</span>
            </div>
            <div class="matrix-stat">
              <span class="kpi-label">HPP</span>
              <span class="mono red">{{ fmt(p.hpp) }}</span>
            </div>
            <div class="matrix-stat">
              <span class="kpi-label">LABA KOTOR</span>
              <span class="mono" :class="p.profit >= 0 ? 'green' : 'red'">{{ fmt(p.profit) }}</span>
            </div>
            <div class="matrix-stat">
              <span class="kpi-label">MARGIN</span>
              <span class="mono" :class="p.margin >= 20 ? 'green' : p.margin >= 10 ? 'gold' : 'red'">
                {{ p.margin }}%
              </span>
            </div>
          </div>
          <div class="margin-bar" style="margin-top:16px;height:8px;border-radius:4px">
            <div class="margin-fill" :style="'width:' + Math.min(p.margin,100) + '%;height:100%;border-radius:4px;background:' + (p.margin >= 20 ? '#10b981' : p.margin >= 10 ? '#f59e0b' : '#ef4444')"></div>
          </div>
          <p style="font-size:11px;color:rgba(255,255,255,0.3);margin-top:4px">
            {{ p.margin >= 20 ? '✓ Margin sehat' : p.margin >= 10 ? '⚠ Margin tipis' : '✗ Margin kritis' }}
          </p>
        </div>
      </div>
    </div>
  </div>

</div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { supabase } from '../lib/supabase'

// ─── CONFIG ─────────────────────────
const periods = [
  { value: 'week',    label: 'Minggu' },
  { value: 'month',   label: 'Bulan' },
  { value: 'quarter', label: 'Kuartal' },
  { value: 'year',    label: 'Tahun' },
]

const tabs = [
  { id: 'pnl',           icon: '📊', label: 'P&L Overview' },
  { id: 'cashflow',      icon: '💳', label: 'Arus Kas' },
  { id: 'receivables',   icon: '📋', label: 'Piutang' },
  { id: 'profitability', icon: '🎯', label: 'Profitabilitas' },
]

// ─── STATE ──────────────────────────
const activeTab       = ref('pnl')
const selectedPeriod  = ref('month')
const isSyncing       = ref(false)
const pnlData         = ref({ totalRevenue: 0, totalHPP: 0, grossProfit: 0, grossMargin: 0, totalDiscount: 0 })
const chartData       = ref<any[]>([])
const productData     = ref<any[]>([])
const totalUtang      = ref(0)
const totalPiutang    = ref(0)
const piutangList     = ref<any[]>([])
const nilaiStok       = ref(0)
const moneyIn         = ref<any[]>([])
const moneyOut        = ref<any[]>([])
const totalMoneyOut   = ref(0)
const allSalesData    = ref<any[]>([])
const startDate       = ref('')
const endDate         = ref('')

// ─── COMPUTED ───────────────────────
const netPosition = computed(() =>
  pnlData.value.totalRevenue
  - pnlData.value.totalHPP
  - totalUtang.value
  + totalPiutang.value
  + nilaiStok.value
)

const totalMoneyIn = computed(() =>
  moneyIn.value.reduce((s: number, x: any) => s + (x.total_revenue ?? 0), 0)
)

const maxRev = computed(() => Math.max(...chartData.value.map((d: any) => d.revenue), 1))

// ─── HELPERS ────────────────────────
function barHeight(val: number) { return Math.max((val / maxRev.value) * 120, 2) }

function fmt(val: number | null | undefined) {
  if (!val) return 'Rp 0'
  return 'Rp ' + Math.round(val).toLocaleString('id-ID')
}

function fmtDate(d: string | null | undefined) {
  if (!d) return '—'
  return new Date(d).toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: '2-digit' })
}

function getDueStatus(due: string | null | undefined) {
  if (!due) return 'unknown'
  const days = Math.floor((new Date().getTime() - new Date(due).getTime()) / 86400000)
  if (days < 0)  return 'safe'
  if (days < 8)  return 'warn'
  return 'danger'
}

function getDueLabel(due: string | null | undefined) {
  if (!due) return 'No Due Date'
  const days = Math.floor((new Date().getTime() - new Date(due).getTime()) / 86400000)
  if (days < 0)  return `${Math.abs(days)}h lagi`
  if (days === 0) return 'Jatuh tempo hari ini'
  return `${days} hari lewat`
}

// ─── DATA FETCH ─────────────────────
async function fetchData() {
  isSyncing.value = true

  try {
    // ── Date range ──────────────────────────
    // ── Date range (Bug 1 Fix) ────────────────
    const now = new Date()
    const y = now.getFullYear()
    const m = now.getMonth()

    const startOfMonth = new Date(y, m, 1)
    const endOfMonth   = new Date(y, m + 1, 0)
    
    // Safely get YYYY-MM-DD from local date
    const getISO = (d: Date) => {
      const year = d.getFullYear()
      const month = String(d.getMonth() + 1).padStart(2, '0')
      const day = String(d.getDate()).padStart(2, '0')
      return `${year}-${month}-${day}`
    }

    const ranges: Record<string, { start: Date, end: Date }> = {
      week:    { start: new Date(now.getTime() - 7 * 86400000), end: now },
      month:   { start: startOfMonth, end: endOfMonth },
      quarter: { start: new Date(y, Math.floor(m / 3) * 3, 1), end: new Date(y, Math.floor(m / 3) * 3 + 3, 0) },
      year:    { start: new Date(y, 0, 1), end: new Date(y, 11, 31) }
    }
    const range = selectedPeriod.value in ranges 
      ? ranges[selectedPeriod.value] 
      : ranges.month;
    
    // Explicitly check for defined range to satisfy TS
    const startISO = range ? getISO(range.start) : getISO(now);
    const endISO   = range ? getISO(range.end) : getISO(now);
    
    startDate.value = startISO;
    endDate.value   = endISO;

    console.log('Date range:', startISO, '—', endISO)

    // ── 1. Sales query (Bug 2 Fix: Direct query) 
    const { data: sales, error: salesErr } = await supabase
      .from('sales')
      .select(`
        id, total_revenue, total_hpp, gross_profit, margin_pct,
        payment_type, created_at, customer_name, customer_id,
        sale_items ( egg_type, packs_sold, hpp_per_pack, revenue )
      `)
      .gte('created_at', startISO + 'T00:00:00')
      .lte('created_at', endISO   + 'T23:59:59')
      .order('created_at', { ascending: true })

    if (salesErr) throw salesErr

    // ── 2. Aggregate P&L ──────────────────────
    const totalRevenue  = sales?.reduce((s, x) => s + (x.total_revenue ?? 0), 0) ?? 0
    const totalHPP      = sales?.reduce((s, x) => s + (x.total_hpp     ?? 0), 0) ?? 0
    const totalDiscount = 0
    const grossProfit   = totalRevenue - totalHPP
    const grossMargin   = totalRevenue > 0
      ? parseFloat(((grossProfit / totalRevenue) * 100).toFixed(1)) : 0

    console.log('Sales found:', sales?.length)
    console.log('Revenue:', totalRevenue, 'HPP:', totalHPP)

    pnlData.value = { totalRevenue, totalHPP, grossProfit, grossMargin, totalDiscount }
    allSalesData.value = sales ?? []

    const productMap: Record<string, { packs: number, revenue: number, hpp: number }> = {}
    const dailyMap: Record<string, { revenue: number, hpp: number }> = {}

    sales?.forEach((sale: any) => {
      const day = sale.created_at.substring(0, 10)
      if (!dailyMap[day]) dailyMap[day] = { revenue: 0, hpp: 0 }
      
      const dayData = dailyMap[day]
      if (dayData) {
        dayData.revenue += sale.total_revenue ?? 0
      }

      sale.sale_items?.forEach((item: any) => {
        const hpp = (item.hpp_per_pack ?? 0) * (item.packs_sold ?? 0)
        if (dayData) {
          dayData.hpp += hpp
        }

        const type = item.egg_type
        if (type) {
          if (!productMap[type]) productMap[type] = { packs: 0, revenue: 0, hpp: 0 }
          productMap[type].packs   += item.packs_sold ?? 0
          productMap[type].revenue += item.revenue    ?? 0
          productMap[type].hpp     += hpp
        }
      })
    })

    // ── 3. Chart data ─────────────────────────
    const { eachDayOfInterval, format, parseISO } = await import('date-fns')
    const allDays = eachDayOfInterval({
      start: parseISO(startISO || ''), end: parseISO(endISO || '')
    })
    chartData.value = allDays.map(day => {
      const key = format(day, 'yyyy-MM-dd')
      const d   = dailyMap[key] ?? { revenue: 0, hpp: 0 }
      return { date: format(day, 'd MMM'), revenue: d.revenue, hpp: d.hpp, profit: d.revenue - d.hpp }
    })

    // ── 4. Product profitability ──────────────
    const LABELS: Record<string, string> = { hero: 'Telur Bebek Hero', salted_egg: 'Telur Asin' }
    productData.value = ['hero', 'salted_egg']
      .filter(t => productMap[t])
      .map(t => {
        const d = productMap[t]
        if (!d) return null // Type safety
        const gp = d.revenue - d.hpp
        return {
          type: t, label: LABELS[t] || t,
          packs: d.packs, revenue: d.revenue, hpp: d.hpp,
          profit: gp,
          margin: d.revenue > 0 ? parseFloat(((gp / d.revenue) * 100).toFixed(1)) : 0
        }
      })
      .filter(x => x !== null)

    // ── 5. Utang supplier ─────────────────────
    const { data: utangData } = await supabase
      .from('utang_supplier')
      .select('remaining_amount, suppliers(name)')
      .gt('remaining_amount', 0)
    totalUtang.value = utangData?.reduce((s: number, u: any) => s + (u.remaining_amount ?? 0), 0) ?? 0

    // ── 6. Piutang (use 'remaining' column) ───
    const { data: piutangData } = await supabase
      .from('piutang')
      .select('id, remaining, total_amount, customer_name, due_date, status, created_at')
      .eq('status', 'belum_bayar')
    totalPiutang.value = piutangData?.reduce((s: number, p: any) => s + (p.remaining ?? 0), 0) ?? 0
    piutangList.value  = piutangData ?? []

    // ── 7. Nilai Stok (confirmed columns) ─────
    const { data: invData } = await supabase
      .from('inventory')
      .select('id, label, current_stock, hpp_per_pack, pack_size, item_type')
      .eq('item_type', 'egg')
    nilaiStok.value = invData?.reduce((s: number, i: any) => {
      const packs = Math.floor((i.current_stock ?? 0) / (i.pack_size ?? 10))
      return s + (packs * (i.hpp_per_pack ?? 0))
    }, 0) ?? 0

    // ── 8. Cash flow purchases ─────────────────
    const { data: purchaseData } = await supabase
      .from('purchases')
      .select('id, total_cost, total_eggs, created_at, suppliers(name)')
      .gte('created_at', startISO + 'T00:00:00')
      .lte('created_at', endISO   + 'T23:59:59')
      .order('created_at', { ascending: false })
    moneyOut.value = purchaseData ?? []
    totalMoneyOut.value = purchaseData?.reduce((s: number, p: any) => s + (p.total_cost ?? 0), 0) ?? 0

    // Money In = tunai sales only (exclude piutang)
    moneyIn.value = (sales ?? []).filter((s: any) => s.payment_type !== 'piutang')



  } catch (err) {
    console.error('fetchData error:', err)
  } finally {
    isSyncing.value = false
  }
}

// ─── LIFECYCLE ──────────────────────
onMounted(fetchData)
watch(selectedPeriod, fetchData)
</script>

<style scoped>
* { box-sizing: border-box; }
.ft-root { width:100%; font-family:'Outfit',sans-serif; color:white; }

/* HEADER */
.ft-header { display:flex; justify-content:space-between; align-items:flex-start; gap:24px; margin-bottom:28px; flex-wrap:wrap; }
.ft-eyebrow { font-size:10px; font-weight:700; letter-spacing:2px; color:#f59e0b; text-transform:uppercase; display:block; margin-bottom:8px; }
.ft-title   { font-size:32px; font-weight:900; margin:0 0 4px; line-height:1.1; }
.ft-desc    { font-size:13px; color:rgba(255,255,255,0.4); margin:0; }
.ft-header-right { display:flex; flex-direction:column; align-items:flex-end; gap:10px; }

/* PERIOD SELECTOR */
.period-selector { display:flex; gap:4px; background:#141418; border:1px solid rgba(255,255,255,0.08); border-radius:10px; padding:4px; }
.period-btn { padding:6px 14px; border-radius:6px; font-size:12px; font-weight:600; background:none; border:none; cursor:pointer; color:rgba(255,255,255,0.4); transition:all 150ms; font-family:'Outfit',sans-serif; }
.period-btn.active { background:#f59e0b; color:#000; font-weight:700; }
.period-btn:not(.active):hover { color:white; background:rgba(255,255,255,0.06); }

/* SYNC BTN */
.sync-btn { display:flex; align-items:center; gap:8px; padding:10px 20px; background:#f59e0b; color:#000; border:none; border-radius:10px; font-weight:700; font-size:13px; cursor:pointer; transition:filter 150ms; font-family:'Outfit',sans-serif; }
.sync-btn:hover { filter:brightness(1.1); }
.sync-btn.loading { opacity:0.7; }
.sync-icon { font-size:16px; }

/* TABS */
.ft-tabs { display:flex; gap:2px; background:#141418; border:1px solid rgba(255,255,255,0.08); border-radius:12px; padding:4px; margin-bottom:28px; overflow-x:auto; }
.ft-tab  { display:flex; align-items:center; gap:8px; padding:9px 18px; border-radius:8px; font-size:13px; font-weight:600; background:none; border:none; cursor:pointer; color:rgba(255,255,255,0.4); white-space:nowrap; transition:all 150ms; font-family:'Outfit',sans-serif; }
.ft-tab.active { background:rgba(245,158,11,0.12); color:#f59e0b; border:1px solid rgba(245,158,11,0.20); }
.ft-tab:not(.active):hover { color:white; background:rgba(255,255,255,0.05); }

/* TAB CONTENT */
.tab-content { display:flex; flex-direction:column; gap:16px; }

/* KPI CARDS */
.kpi-grid-4 { display:grid; grid-template-columns:repeat(4,1fr); gap:16px; }
.kpi-grid-2 { display:grid; grid-template-columns:repeat(2,1fr); gap:16px; }
.kpi-card {
  background:#141418;
  border:1px solid rgba(255,255,255,0.08);
  border-left:3px solid var(--accent, rgba(255,255,255,0.15));
  border-radius:14px; padding:20px;
  transition:box-shadow 200ms;
}
.kpi-card:hover { box-shadow:0 4px 20px rgba(0,0,0,0.3); }
.kpi-top { display:flex; justify-content:space-between; align-items:center; margin-bottom:10px; }
.kpi-label { font-size:10px; font-weight:700; letter-spacing:1.5px; color:rgba(255,255,255,0.35); text-transform:uppercase; }
.kpi-icon  { font-size:18px; opacity:0.4; }
.kpi-val   { font-size:24px; font-weight:800; font-family:'DM Mono',monospace; margin:0 0 6px; line-height:1; }
.kpi-sub   { font-size:11px; color:rgba(255,255,255,0.30); margin:0; }

/* CHART */
.chart-card { background:#141418; border:1px solid rgba(255,255,255,0.08); border-radius:16px; padding:24px; }
.chart-head { display:flex; justify-content:space-between; align-items:flex-start; margin-bottom:20px; }
.chart-title { font-size:15px; font-weight:700; color:white; margin:0 0 4px; }
.chart-sub   { font-size:12px; color:rgba(255,255,255,0.35); margin:0; }
.chart-legend { display:flex; gap:16px; font-size:12px; color:rgba(255,255,255,0.5); }
.chart-legend span { display:flex; align-items:center; gap:6px; }
.dot { width:8px; height:8px; border-radius:50%; display:inline-block; }
.chart-empty { display:flex; flex-direction:column; align-items:center; justify-content:center; height:160px; gap:8px; color:rgba(255,255,255,0.3); font-size:13px; }

/* BAR CHART */
.chart-bars { display:flex; align-items:flex-end; gap:8px; height:160px; overflow-x:auto; padding-bottom:24px; }
.chart-bar-group { display:flex; flex-direction:column; align-items:center; gap:4px; min-width:40px; }
.bar-wrap { display:flex; gap:2px; align-items:flex-end; height:130px; }
.bar { width:10px; border-radius:3px 3px 0 0; transition:height 300ms; }
.bar.revenue { background:#f59e0b; opacity:0.8; }
.bar.hpp     { background:#ef4444; opacity:0.7; }
.bar.profit  { background:#10b981; opacity:0.9; }
.bar-label   { font-size:9px; color:rgba(255,255,255,0.3); white-space:nowrap; }

/* P&L TABLE */
.pnl-card { background:#141418; border:1px solid rgba(255,255,255,0.08); border-radius:16px; padding:24px; }
.pnl-head { display:flex; justify-content:space-between; align-items:center; margin-bottom:20px; padding-bottom:16px; border-bottom:1px solid rgba(255,255,255,0.06); }
.period-badge { font-size:12px; color:rgba(255,255,255,0.30); }
.pnl-footer { display:flex; justify-content:space-between; align-items:flex-end; padding-top:20px; border-top:2px solid rgba(255,255,255,0.08); margin-top:8px; }
.laba-big { font-size:36px; font-weight:900; font-family:'DM Mono',monospace; margin:4px 0 0; }

/* DATA TABLE */
.data-table { width:100%; border-collapse:collapse; }
.data-table th { font-size:10px; font-weight:700; letter-spacing:1.5px; color:rgba(255,255,255,0.30); text-transform:uppercase; padding:8px 14px; border-bottom:1px solid rgba(255,255,255,0.06); text-align:left; }
.data-table td { padding:14px 14px; font-size:13px; color:rgba(255,255,255,0.75); border-bottom:1px solid rgba(255,255,255,0.04); }
.data-table tr:last-child td { border-bottom:none; }
.data-table tr:hover td { background:rgba(255,255,255,0.02); }

/* PRODUCT CHIPS */
.product-chip { display:inline-block; padding:3px 10px; border-radius:20px; font-size:11px; font-weight:700; }
.product-chip.hero       { background:rgba(245,158,11,0.12); color:#f59e0b; border:1px solid rgba(245,158,11,0.25); }
.product-chip.salted_egg { background:rgba(56,189,248,0.12);  color:#38bdf8; border:1px solid rgba(56,189,248,0.25); }

/* MARGIN BAR */
.margin-bar { background:rgba(255,255,255,0.06); border-radius:4px; height:6px; position:relative; width:120px; }
.margin-fill { height:100%; border-radius:4px; background:#10b981; }
.margin-label { position:absolute; right:-36px; top:-3px; font-size:11px; font-family:'DM Mono',monospace; color:rgba(255,255,255,0.6); }

/* STATUS CHIPS */
.status-chip { display:inline-block; padding:2px 8px; border-radius:12px; font-size:11px; font-weight:700; }
.status-chip.safe    { background:rgba(16,185,129,0.12); color:#10b981; border:1px solid rgba(16,185,129,0.25); }
.status-chip.warn    { background:rgba(245,158,11,0.12); color:#f59e0b; border:1px solid rgba(245,158,11,0.25); }
.status-chip.danger  { background:rgba(239,68,68,0.12);  color:#ef4444; border:1px solid rgba(239,68,68,0.25); }
.status-chip.unknown { background:rgba(255,255,255,0.06); color:rgba(255,255,255,0.4); }

/* CASH FLOW */
.cf-grid { display:grid; grid-template-columns:1fr 1fr; gap:16px; }
.cf-card { background:#141418; border:1px solid rgba(255,255,255,0.08); border-radius:16px; overflow:hidden; }
.cf-head { display:flex; justify-content:space-between; align-items:center; padding:16px 20px; font-size:11px; font-weight:700; letter-spacing:1px; }
.green-head { background:rgba(16,185,129,0.08); color:#10b981; border-bottom:1px solid rgba(16,185,129,0.15); }
.red-head   { background:rgba(239,68,68,0.08);  color:#ef4444; border-bottom:1px solid rgba(239,68,68,0.15); }
.cf-total   { display:flex; justify-content:space-between; padding:14px 20px; background:rgba(255,255,255,0.03); border-top:1px solid rgba(255,255,255,0.06); font-size:13px; font-weight:700; }
.net-cf-card { background:#141418; border:1px solid rgba(255,255,255,0.08); border-radius:16px; padding:28px; }
.cf-bar-wrap { display:flex; height:8px; border-radius:4px; overflow:hidden; margin:16px 0 8px; gap:2px; }
.cf-bar-in  { background:#10b981; border-radius:4px; min-width:4px; }
.cf-bar-out { background:#ef4444; border-radius:4px; min-width:4px; }
.cf-bar-labels { display:flex; justify-content:space-between; font-size:12px; }

/* PROFITABILITY MATRIX */
.section-card { background:#141418; border:1px solid rgba(255,255,255,0.08); border-radius:16px; padding:24px; }
.section-head { display:flex; justify-content:space-between; align-items:center; margin-bottom:20px; }
.product-matrix { display:grid; grid-template-columns:repeat(2,1fr); gap:16px; }
.matrix-card { padding:20px; border-radius:12px; border:1px solid rgba(255,255,255,0.06); }
.matrix-card.hero       { background:rgba(245,158,11,0.04); border-color:rgba(245,158,11,0.15); }
.matrix-card.salted_egg { background:rgba(56,189,248,0.04);  border-color:rgba(56,189,248,0.15); }
.matrix-header { display:flex; justify-content:space-between; align-items:center; margin-bottom:16px; }
.matrix-stats  { display:grid; grid-template-columns:1fr 1fr; gap:12px; }
.matrix-stat   { display:flex; flex-direction:column; gap:4px; }

/* UTILITY */
.mono   { font-family:'DM Mono',monospace; }
.gold   { color:#f59e0b; }
.green  { color:#10b981; }
.red    { color:#ef4444; }
.violet { color:#8b5cf6; }
.muted  { color:rgba(255,255,255,0.35); }

/* RESPONSIVE */
@media (max-width:1024px) {
  .kpi-grid-4 { grid-template-columns:repeat(2,1fr); }
  .cf-grid    { grid-template-columns:1fr; }
}
@media (max-width:768px) {
  .ft-header  { flex-direction:column; }
  .ft-title   { font-size:24px; }
  .kpi-grid-4, .kpi-grid-2, .product-matrix { grid-template-columns:1fr; }
  .ft-tab span:last-child { display:none; }
  .kpi-val    { font-size:20px; }
}
</style>
