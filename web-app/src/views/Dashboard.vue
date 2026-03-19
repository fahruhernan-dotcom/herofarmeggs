<template>
  <div class="dashboard-content">
    <header v-if="!isMobile" class="workspace-header desktop-only">
      <div class="header-left">
        <h1 class="hero-font">Hero Farm Terminal</h1>
        <p class="text-dim">War Room — Real-time operational metrics</p>
      </div>
      <div class="header-actions">
        <div class="net-position-banner glass-panel" :class="{ 'warning': netPosition < 0 }">
           <div class="np-info">
             <span class="np-label">Profit Net Position</span>
             <span class="np-val" :class="netPosition >= 0 ? 'text-green' : 'text-red'">
               {{ netPosition >= 0 ? '+' : '' }}{{ formatCurrency(netPosition) }}
             </span>
           </div>
           <div v-if="netPosition < 0" class="np-warning pulse">
             <AlertTriangleIcon class="icon-xs" />
             <span>Low Cash</span>
           </div>
        </div>
        <div class="time-widget glass-panel">
          <span class="dot pulse"></span>
          {{ currentTime }}
        </div>
      </div>
    </header>

    <!-- RETRYING BANNER -->
    <div v-if="isRetrying" class="retry-banner glass-panel animate-fade-in">
      <span class="retry-dot pulse"></span>
      <span>Mencoba memuat ulang... (percobaan ke-{{ retryCount }})</span>
    </div>

    <!-- FETCH ERROR STATE -->
    <section v-if="fetchError" class="fetch-error-card glass-panel animate-pop">
      <div class="fec-icon">⚠️</div>
      <h3 class="fec-title">Koneksi bermasalah</h3>
      <p class="fec-desc">Data tidak bisa dimuat setelah beberapa percobaan.</p>
      <button class="btn-primary mt-6" @click="retryFetch">
        🔄 Coba Lagi
      </button>
      <p class="fec-hint mt-4">Pastikan koneksi internetmu stabil</p>
    </section>

    <!-- SKELETON LOADING STATE -->
    <section v-else-if="loading" class="dashboard-grid">
      <div class="skeleton-bar"></div>
      <div v-for="i in 9" :key="i" class="skeleton-card"></div>
    </section>

    <!-- MAIN DASHBOARD GRID -->
    <section v-else class="dashboard-grid">

      <!-- ROW 1: ALERT BAR -->
      <AlertBar
        :show="netPosition < 0"
        :shortfall="netPosition"
        :totalCost="totalCost"
        :revenue="totalRevenue"
        class="row-1"
      />

      <!-- ROW 2: COMMAND METRICS -->
      <div class="command-metrics-scroller dash-section" :class="{ 'scroll-x': isMobile }">
        <NetPositionCard
          :netPosition="netPosition"
          :totalCost="totalCost"
          :revenue="totalRevenue"
          :pct="modalKembaliPct"
          class="row-2 animate-row dash-section"
          style="--row-delay: 0; border-left: 3px solid #10b981;"
        />

        <template v-if="!isMobile">
          <UtangCard
            :amount="kpiData.total_utang || 0"
            :count="kpiData.utang_count || 0"
            class="row-2 animate-row"
            style="--row-delay: 1"
          />
          <PiutangCard
            :amount="kpiData.total_piutang || 0"
            :count="kpiData.piutang_count || 0"
            class="row-2 animate-row"
            style="--row-delay: 2"
          />
        </template>
        <div v-else class="combined-debt-card glass-panel row-2 animate-row dash-section" style="--row-delay: 1">
          <div class="cdc-col" :style="(kpiData.total_utang || 0) > 0 ? 'border-left: 3px solid #ef4444; padding-left: 8px;' : ''">
            <div class="cdc-label-row">
              <AlertCircleIcon class="icon-xxs text-red" />
              <span class="cdc-label">Utang Supplier</span>
            </div>
            <span class="cdc-val" :class="(kpiData.total_utang || 0) > 0 ? 'text-red' : 'text-slate-400'">{{ formatCurrency(kpiData.total_utang || 0) }}</span>
            <button class="btn-sm btn-bayar" @click="$router.push('/suppliers')">Bayar</button>
          </div>
          <div class="cdc-divider"></div>
          <div class="cdc-col" :style="(kpiData.total_piutang || 0) > 0 ? 'border-left: 3px solid #facc15; padding-left: 8px;' : ''">
            <div class="cdc-label-row">
              <ClockIcon class="icon-xxs text-gold" />
              <span class="cdc-label">Piutang Aktif</span>
            </div>
            <span class="cdc-val" :class="(kpiData.total_piutang || 0) > 0 ? 'text-gold' : 'text-slate-400'">{{ formatCurrency(kpiData.total_piutang || 0) }}</span>
            <button class="btn-sm btn-tagih" @click="$router.push('/customers')">Tagih</button>
          </div>
        </div>
      </div>

      <!-- ROW 3: PRIMARY CONTENT -->
      <PerformancePanel
        :revenue="totalRevenue"
        :profit="grossProfit"
        :marginPct="grossMarginPct"
        :transaksi="totalTransaksi"
        :packsSold="totalPacksSold"
        :growth="revenueWidget.growth"
        :salesChart="salesChartData"
        class="row-3-main animate-row dash-section"
        style="--row-delay: 3; border-left: 3px solid #38bdf8;"
      />
      
      <StockStatusCard
        :grades="eggInventory"
        :potentialRevenue="potentialRevenue"
        class="row-3-side animate-row dash-section"
        style="--row-delay: 4"
      />

      <!-- ROW 4: SECONDARY WIDGETS -->
      <ArusKasCard
        :dates="cashFlowData.dates"
        :income="cashFlowData.income"
        :expense="cashFlowData.expense"
        :totalIncome="cashFlowData.totalIncome"
        :totalExpense="cashFlowData.totalExpense"
        :net="cashFlowData.net"
        class="row-4 animate-row dash-section"
        style="--row-delay: 5"
      />
      <PiutangAgingCard
        :paid="piutangBuckets.paid"
        :week1="piutangBuckets.week1"
        :week2="piutangBuckets.week2"
        :overdue="piutangBuckets.overdue"
        class="row-4 animate-row dash-section"
        style="--row-delay: 6"
      />
      <TopPelangganCard
        :customers="topCustomers"
        class="row-4 animate-row dash-section"
        style="--row-delay: 7"
      />

      <!-- ROW 5: PURCHASE HISTORY (Desktop Only) -->
      <div v-if="!isMobile" class="pembelian-widget glass-panel row-5 animate-row dash-section" style="--row-delay: 8">
        <div class="pw-header">
          <div class="pw-title-group">
            <ShoppingCartIcon class="icon-sm text-gold" />
            <span class="pw-title hero-font">RIWAYAT PEMBELIAN</span>
          </div>
          <router-link to="/stock?tab=pembelian" class="pw-link">
            <span>Lihat Semua</span>
            <ArrowRightIcon class="icon-xs" />
          </router-link>
        </div>

        <div v-if="loadingPurchases" class="pw-loading py-6 flex-center">
          <RefreshCwIcon class="animate-spin text-dim" />
        </div>
        
        <div v-else-if="purchases.length === 0" class="pw-empty py-6 text-center">
          <p class="text-xs text-dim">Belum ada transaksi</p>
        </div>

        <div v-else class="pw-list">
          <div v-for="p in purchases" :key="p.id" class="pw-item">
            <div class="pw-item-left">
              <div class="pw-item-icon" :class="p.status">
                <PackageIcon v-if="p.item_type === 'egg'" class="icon-xs" />
                <ShoppingCartIcon v-else class="icon-xs" />
              </div>
              <div class="pw-item-info">
                <span class="pw-item-name">{{ p.supplier || 'General Supplier' }}</span>
                <span class="pw-item-meta">{{ p.total_eggs_bought?.toLocaleString('id-ID') }} butir · {{ formatRelativeDate(p.created_at) }}</span>
              </div>
            </div>
            <div class="pw-item-right">
              <span class="pw-item-amount">{{ formatCurrency(p.total_cost) }}</span>
              <span class="pw-item-status" :class="p.status">{{ p.status?.toUpperCase() }}</span>
            </div>
          </div>
        </div>

        <div class="pw-footer">
          <span class="pw-footer-label">Total bulan ini</span>
          <span class="pw-footer-val">{{ formatCurrency(monthlyTotal) }}</span>
        </div>
      </div>
    </section>

    <!-- DANGER ZONE -->
    <section v-if="(authStore.profile?.role === 'admin' || authStore.profile?.role === 'owner' || authStore.user?.email === 'fahruhernansakti@gmail.com') && !isMobile" class="danger-zone glass-panel mt-8">
      <div class="dz-header">
        <div>
          <h3 class="hero-font text-error">System Maintenance</h3>
          <p class="text-dim">Danger Zone: Operations below are irreversible.</p>
        </div>
        <button class="btn-error" @click="confirmReset">
          <Trash2Icon class="icon-sm" />
          <span>RESET SYSTEM DATA</span>
        </button>
      </div>
    </section>

    <!-- RESET CONFIRMATION MODAL -->
    <Teleport to="body">
      <div v-if="showResetModal" class="modal-overlay" @click.self="closeResetModal">
        <div class="modal-card glass-panel animate-pop reset-modal">
          <div class="modal-header">
            <h2 class="hero-font text-error">CRITICAL: SYSTEM RESET</h2>
            <p class="text-dim">Follow the steps below to securely reset your operational data.</p>
          </div>

          <div class="reset-stepper">
            <!-- STEP 1: IMPACT ASSESSMENT -->
            <div v-if="resetStep === 1" class="reset-step animate-slide">
              <div class="impact-box">
                <AlertOctagonIcon class="icon-lg text-error" />
                <h4 class="font-bold mt-2">Analisis Dampak</h4>
                <div class="impact-stats">
                  <div class="is-item"><span>Transaksi Sales</span> <strong>{{ impactCounts.sales }}</strong></div>
                  <div class="is-item"><span>Pelanggan</span> <strong>{{ impactCounts.customers }}</strong></div>
                  <div class="is-item"><span>Log Stok</span> <strong>{{ impactCounts.logs }}</strong></div>
                  <div class="is-item"><span>Entri Keuangan</span> <strong>{{ impactCounts.finance }}</strong></div>
                </div>
                <p class="text-xs text-dim mt-4 italic">Semua data di atas akan dihapus permanen.</p>
              </div>
              <div class="modal-actions mt-6">
                <button class="btn-secondary" @click="closeResetModal">BATAL</button>
                <button class="btn-primary" @click="resetStep = 2">LANJUT KE BACKUP →</button>
              </div>
            </div>

            <!-- STEP 2: MANDATORY BACKUP -->
            <div v-if="resetStep === 2" class="reset-step animate-slide">
              <div class="backup-box glass-panel amber">
                <AlertTriangleIcon class="icon-lg text-amber" />
                <h4 class="font-bold mt-2">Backup Wajib</h4>
                <p class="text-sm text-dim">Anda HARUS mengunduh backup sebelum melanjutkan.</p>
                <button class="btn-primary-glow mt-6" @click="exportBackupData">
                  <DownloadIcon class="icon-sm" />
                  <span>⬇ UNDUH BACKUP JSON</span>
                </button>
              </div>
              <div v-if="backupStatus === 'downloaded'" class="confirm-backup-row mt-6 animate-fade-in">
                <label class="checkbox-container">
                  <input type="checkbox" v-model="backupDownloaded" />
                  <span class="checkmark"></span>
                  <span class="cb-label">✓ Saya sudah menyimpan file backup dengan aman</span>
                </label>
              </div>
              <div class="modal-actions mt-6">
                <button class="btn-secondary" @click="resetStep = 1">KEMBALI</button>
                <button class="btn-primary" :disabled="!backupDownloaded" @click="resetStep = 3">TAHAP AKHIR</button>
              </div>
            </div>

            <!-- STEP 3: FINAL CONFIRM -->
            <div v-if="resetStep === 3" class="reset-step animate-slide">
              <div class="form-group">
                <label>Ketik <span class="text-error font-bold">RESET HERO FARM</span> untuk konfirmasi</label>
                <input
                  type="text"
                  v-model="resetConfirmation"
                  placeholder="Case-sensitive"
                  class="reset-input"
                />
              </div>
              <div class="modal-actions mt-8">
                <button class="btn-secondary" @click="resetStep = 2">KEMBALI</button>
                <button
                  class="btn-error"
                  :disabled="resetConfirmation !== 'RESET HERO FARM' || reseting"
                  @click="handleSystemReset"
                >
                  {{ reseting ? 'WIPING DATA...' : 'KONFIRMASI RESET' }}
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { supabase } from '../lib/supabase'
import { useAuthStore } from '../stores/auth'
import { useToast } from '../composables/useToast'
import { useDashboard } from '../composables/useDashboard'
import { withTimeout } from '../utils/safeAsync'
// @ts-ignore
import { formatCurrency, formatRelativeDate } from '../utils/formatters'

// Icons
import { 
  Trash2Icon, 
  AlertTriangleIcon, 
  DownloadIcon, 
  AlertOctagonIcon, 
  AlertCircleIcon, 
  ClockIcon,
  ShoppingCartIcon,
  PackageIcon,
  ArrowRightIcon,
  RefreshCwIcon
} from 'lucide-vue-next'

import { usePurchaseHistory } from '../composables/usePurchaseHistory'

// Dashboard Components
import AlertBar from '../components/dashboard/AlertBar.vue'
import NetPositionCard from '../components/dashboard/NetPositionCard.vue'
import UtangCard from '../components/dashboard/UtangCard.vue'
import PiutangCard from '../components/dashboard/PiutangCard.vue'
import PerformancePanel from '../components/dashboard/PerformancePanel.vue'
import StockStatusCard from '../components/dashboard/StockStatusCard.vue'
import ArusKasCard from '../components/dashboard/ArusKasCard.vue'
import PiutangAgingCard from '../components/dashboard/PiutangAgingCard.vue'
import TopPelangganCard from '../components/dashboard/TopPelangganCard.vue'

const { showToast } = useToast()
const authStore = useAuthStore()

// Error Recovery State
const fetchError = ref(false)
const retryCount = ref(0)
const isRetrying = ref(false)

// Dashboard data
const {
  loading,
  eggInventory,
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
  fetchData: _rawFetch,
  setupRealtime,
  cleanup
} = useDashboard()

const {
  purchases,
  monthlyTotal,
  isLoading: loadingPurchases,
  fetchPurchases
} = usePurchaseHistory()

async function safeFetchData() {
  fetchError.value = false
  retryCount.value = 0
  isRetrying.value = false
  try {
    await Promise.all([
      _rawFetch(),
      fetchPurchases(5) // Only need top 5 for dashboard
    ])
  } catch (err: any) {
    // Auto-retry with exponential backoff
    let succeeded = false
    for (let attempt = 1; attempt <= 3; attempt++) {
      retryCount.value = attempt
      isRetrying.value = true
      const delay = 1000 * Math.pow(2, attempt - 1)
      await new Promise(r => setTimeout(r, delay))
      try {
        await _rawFetch()
        succeeded = true
        break
      } catch { /* continue retrying */ }
    }
    isRetrying.value = false
    if (!succeeded) {
      fetchError.value = true
      showToast('Gagal memuat data dashboard', 'error')
    }
  }
}

function retryFetch() {
  fetchError.value = false
  retryCount.value = 0
  safeFetchData()
}

const isMobile = ref(window.innerWidth <= 768)
function checkMobile() {
  isMobile.value = window.innerWidth <= 768
}

// Clock
const currentTime = ref('')
let clockInterval: any

function updateClock() {
  const now = new Date()
  currentTime.value = now.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' })
}

// Reset Logic
const showResetModal = ref(false)
const resetStep = ref(1)
const backupStatus = ref<'idle' | 'downloading' | 'downloaded'>('idle')
const backupDownloaded = ref(false)
const resetConfirmation = ref('')
const reseting = ref(false)

function closeResetModal() {
  showResetModal.value = false
  resetStep.value = 1
  backupStatus.value = 'idle'
  backupDownloaded.value = false
  resetConfirmation.value = ''
}

async function confirmReset() {
  const first = window.confirm('PERINGATAN: Ini akan menghapus SEMUA data sistem. Lanjutkan?')
  if (!first) return
  const input = window.prompt('Ketik "HAPUS SEMUA DATA" untuk konfirmasi final:')
  if (input !== 'HAPUS SEMUA DATA') {
    alert('Konfirmasi salah. Reset dibatalkan.')
    return
  }
  showResetModal.value = true
}

async function exportBackupData() {
  backupStatus.value = 'downloading'
  try {
    const { data: sales } = await withTimeout(supabase.from('sales').select('*, sale_items(*)'), 12000, 'backup-sales')
    const { data: customers } = await withTimeout(supabase.from('customers').select('*'), 12000, 'backup-customers')
    const { data: stockLogs } = await withTimeout(supabase.from('stock_logs').select('*'), 12000, 'backup-stock')
    const { data: finance } = await withTimeout(supabase.from('finance_entries').select('*'), 12000, 'backup-finance')

    const backupData = {
      exported_at: new Date().toISOString(),
      sales: sales || [],
      customers: customers || [],
      stock_logs: stockLogs || [],
      finance_entries: finance || []
    }

    const blob = new Blob([JSON.stringify(backupData, null, 2)], { type: 'application/json' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    const now = new Date()
    const dateStr = now.toISOString().slice(0, 10).replace(/-/g, '')
    const timeStr = now.toTimeString().slice(0, 8).replace(/:/g, '')
    a.href = url
    a.download = `hero-farm-backup-${dateStr}-${timeStr}.json`
    document.body.appendChild(a)
    a.click()
    document.body.removeChild(a)
    URL.revokeObjectURL(url)
    showToast('Backup berhasil diunduh')
    backupStatus.value = 'downloaded'
  } catch {
    showToast('Gagal backup data', 'error')
    backupStatus.value = 'idle'
  } finally {
    if (backupStatus.value === 'downloading') {
      backupStatus.value = 'idle'
    }
  }
}

async function handleSystemReset() {
  if (resetConfirmation.value !== 'RESET HERO FARM') return
  reseting.value = true
  try {
    await withTimeout(supabase.from('sale_items').delete().not('id', 'is', null), 15000, 'reset-sale-items')
    await withTimeout(supabase.from('sales').delete().not('id', 'is', null), 15000, 'reset-sales')
    await withTimeout(supabase.from('stock_logs').delete().not('id', 'is', null), 15000, 'reset-stock-logs')
    await withTimeout(supabase.from('finance_entries').delete().not('id', 'is', null), 15000, 'reset-finance')
    await withTimeout(supabase.from('customers').update({ total_orders: 0, total_spent: 0 }).not('id', 'is', null), 15000, 'reset-customers')
    await withTimeout(supabase.from('inventory').update({
      current_stock: 0, cost_per_egg: 0, cost_per_packaging: 0,
      cost_per_sticker: 0, cost_per_card: 0, cost_price: 0
    }).not('id', 'is', null), 15000, 'reset-inventory')
    
    showToast('Sistem berhasil direset')
    closeResetModal()
    safeFetchData()
  } catch {
    showToast('Gagal total reset sistem', 'error')
  } finally {
    reseting.value = false
  }
}

// Lifecycle
onMounted(() => {
  safeFetchData()
  setupRealtime()
  updateClock()
  clockInterval = setInterval(updateClock, 1000)
  checkMobile()
  window.addEventListener('resize', checkMobile)
})

onUnmounted(() => {
  cleanup()
  clearInterval(clockInterval)
  window.removeEventListener('resize', checkMobile)
})
</script>

<style scoped>
/* ─── 12-COLUMN DASHBOARD GRID ──────────── */
.dashboard-grid {
  display: grid;
  grid-template-columns: repeat(12, 1fr);
  gap: 16px;
}

/* Row 1: Alert Bar — full width */
.row-1 { grid-column: 1 / -1; }

/* Row 2: Command Metrics — 3 cards, 4 cols each */
.command-metrics-scroller {
  grid-column: 1 / -1;
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 16px;
}
.row-2 { grid-column: auto; }

/* Row 3: Performance (8) + Stock (4) */
.row-3-main { grid-column: span 8; }
.row-3-side { grid-column: span 4; }

/* ─── COMBINED DEBT CARD (MOBILE) ───────── */
.combined-debt-card {
  display: grid;
  grid-template-columns: 1fr auto 1fr;
  gap: 12px;
  padding: 12px 14px;
  align-items: center;
}
.cdc-col {
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.cdc-label {
  font-family: var(--font-ui);
  font-size: 9px;
  font-weight: 600;
  color: var(--muted);
  text-transform: uppercase;
  letter-spacing: 0.5px;
}
.cdc-val {
  font-family: var(--font-mono);
  font-size: 1.25rem;
  font-weight: 700;
  line-height: 1;
}
.cdc-divider {
  width: 1px;
  height: 100%;
  background: rgba(255,255,255,0.06);
}
.btn-sm {
  padding: 6px 12px;
  font-size: 11px;
  font-family: var(--font-ui);
  font-weight: 600;
  border-radius: 6px;
  cursor: pointer;
  background: transparent;
  width: fit-content;
  text-decoration: none;
  margin-top: 4px;
}
.btn-outline-red {
  border: 1px solid rgba(239, 68, 68, 0.4);
  color: var(--red);
}
.btn-outline-gold {
  border: 1px solid rgba(245, 158, 11, 0.4);
  color: var(--gold);
}
.text-gold { color: var(--gold); }

/* Row 4: Secondary Widgets — 3 cards, 4 cols each */
.row-4 { grid-column: span 4; }

/* ─── STAGGERED ENTRANCE ANIMATION ──────── */
.animate-row {
  opacity: 0;
  animation: rowFadeUp 0.5s ease-out forwards;
  animation-delay: calc(var(--row-delay, 0) * 80ms);
}

@keyframes rowFadeUp {
  from { opacity: 0; transform: translateY(16px); }
  to { opacity: 1; transform: translateY(0); }
}

/* ─── SKELETON LOADING ──────────────────── */
.skeleton-bar {
  grid-column: 1 / -1;
  height: 52px;
  border-radius: 10px;
  background: linear-gradient(90deg,
    rgba(255,255,255,0.04) 0%,
    rgba(255,255,255,0.08) 50%,
    rgba(255,255,255,0.04) 100%);
  background-size: 200% 100%;
  animation: shimmer 1.5s infinite;
}

.skeleton-card {
  grid-column: span 4;
  height: 200px;
  border-radius: 16px;
  background: linear-gradient(90deg,
    rgba(255,255,255,0.04) 0%,
    rgba(255,255,255,0.08) 50%,
    rgba(255,255,255,0.04) 100%);
  background-size: 200% 100%;
  animation: shimmer 1.5s infinite;
}

.skeleton-card:nth-child(5) { grid-column: span 8; height: 320px; }
.skeleton-card:nth-child(6) { grid-column: span 4; height: 320px; }

@keyframes shimmer {
  0% { background-position: -200% 0; }
  100% { background-position: 200% 0; }
}

/* ─── HEADER ────────────────────────────── */
.workspace-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 32px;
  width: 100%;
}

.header-left {
  display: flex;
  flex-direction: column;
}

.header-actions {
  display: flex;
  align-items: center;
  gap: 16px;
}

.net-position-banner {
  display: flex;
  align-items: center;
  padding: 8px 16px;
  gap: 16px;
  background: var(--bg-card);
  border: 1px solid var(--border);
  height: 44px;
}

.net-position-banner.warning {
  border-color: rgba(239, 68, 68, 0.4);
  background: rgba(239, 68, 68, 0.05);
}

.np-info {
  display: flex;
  flex-direction: column;
}

.np-label {
  font-size: 9px;
  font-weight: 800;
  color: var(--muted);
  text-transform: uppercase;
  letter-spacing: 0.05em;
  line-height: 1;
}

.np-val {
  font-family: var(--font-mono);
  font-size: 1.1rem;
  font-weight: 700;
  line-height: 1.2;
}

.np-warning {
  display: flex;
  align-items: center;
  gap: 6px;
  color: var(--red);
  font-size: 10px;
  font-weight: 700;
  padding: 4px 8px;
  background: rgba(239, 68, 68, 0.1);
  border-radius: 6px;
}

.time-widget {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 16px;
  font-family: var(--font-mono);
  font-size: 0.85rem;
  font-weight: 500;
  color: var(--gold);
  height: 44px;
}

.chart-center {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  display: flex;
  flex-direction: column;
  align-items: center;
  pointer-events: none;
}

.cc-val { font-size: 2.2rem; font-weight: 900; line-height: 1; }
.cc-label { font-size: 0.7rem; color: var(--muted); text-transform: uppercase; }
.cc-val-sm { font-size: 1.6rem; font-weight: 900; line-height: 1; }
.cc-label-xs { font-size: 10px; color: var(--muted); }

/* ─── LEGENDS ───────────────────── */
.legend-detailed {
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding: 8px 16px;
  font-family: var(--font-mono);
  font-size: 0.85rem;
  border-radius: 10px;
}

.dot {
  width: 8px;
  height: 8px;
  background: var(--green);
  border-radius: 50%;
  box-shadow: 0 0 10px var(--green);
}

.pulse {
  animation: pulse-ring 1.5s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

@keyframes pulse-ring {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.5; }
}

/* ─── DANGER ZONE ───────────────────────── */
.danger-zone {
  padding: 32px;
  border-color: rgba(255, 66, 66, 0.2);
}

.dz-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.text-error { color: var(--red); }
.text-amber { color: var(--gold); }
.mt-8 { margin-top: 32px; }
.mt-6 { margin-top: 24px; }
.mt-4 { margin-top: 16px; }
.mt-2 { margin-top: 8px; }
.font-bold { font-weight: 700; }

.btn-error {
  background: rgba(239, 68, 68, 0.1);
  color: var(--red);
  border: 1px solid rgba(239, 68, 68, 0.3);
  padding: 12px 24px;
  border-radius: var(--radius-sm);
  display: flex;
  align-items: center;
  gap: 12px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
}

.btn-error:hover:not(:disabled) {
  background: var(--red);
  color: white;
}

.btn-error:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

/* ─── MODAL ─────────────────────────────── */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0, 0, 0, 0.85);
  backdrop-filter: blur(8px);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 2000;
  padding: 20px;
}

.reset-modal { text-align: center; }

.reset-stepper {
  min-height: 250px;
  display: flex;
  flex-direction: column;
  justify-content: center;
}

.impact-box {
  background: rgba(239, 68, 68, 0.05);
  border: 1px solid rgba(239, 68, 68, 0.2);
  padding: 24px;
  border-radius: 16px;
  margin-bottom: 24px;
}

.impact-stats {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
  margin-top: 20px;
}

.is-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  background: rgba(255, 255, 255, 0.03);
  padding: 12px;
  border-radius: 12px;
}

.is-item span { font-size: 10px; color: var(--color-text-dim); text-transform: uppercase; }
.is-item strong { font-size: 1.4rem; color: #ef4444; }

.modal-actions {
  display: flex;
  gap: 16px;
  justify-content: center;
}

.modal-actions button { flex: 1; max-width: 200px; }

.backup-box {
  padding: 32px;
  background: rgba(255, 140, 0, 0.03);
  border: 1px dashed rgba(255, 140, 0, 0.3);
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
}

.backup-box.amber {
  background: rgba(245, 158, 11, 0.05);
  border-color: rgba(245, 158, 11, 0.3);
}

.checkbox-container {
  display: flex;
  align-items: center;
  gap: 12px;
  cursor: pointer;
  justify-content: center;
  user-select: none;
  background: rgba(255, 255, 255, 0.03);
  padding: 12px;
  border-radius: 8px;
}

.cb-label {
  font-size: 0.85rem;
  font-weight: 600;
  color: white;
}

.reset-input {
  width: 100%;
  max-width: 200px;
  margin-top: 8px;
  text-align: center;
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid var(--glass-border);
  padding: 12px;
  border-radius: var(--radius-sm);
  color: white;
  font-size: 1.2rem;
  font-weight: 800;
  letter-spacing: 0.2em;
}

.reset-input:focus {
  border-color: var(--red);
  outline: none;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 12px;
  margin: 24px 0;
}

.form-group label { font-size: 0.8rem; color: var(--color-text-dim); }

.animate-pop { animation: popIn 0.3s cubic-bezier(0.23, 1, 0.32, 1); }
@keyframes popIn {
  from { opacity: 0; transform: scale(0.9) translateY(20px); }
  to { opacity: 1; transform: scale(1) translateY(0); }
}

.animate-slide { animation: slideLeft 0.3s cubic-bezier(0.23, 1, 0.32, 1); }
@keyframes slideLeft {
  from { opacity: 0; transform: translateX(20px); }
  to { opacity: 1; transform: translateX(0); }
}

.animate-fade-in { animation: fadeIn 0.4s ease forwards; }
@keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }

/* ─── RETRY BANNER ──────────────────────── */
.retry-banner {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 20px;
  margin-bottom: 16px;
  border-radius: 12px;
  background: rgba(245, 158, 11, 0.08);
  border: 1px solid rgba(245, 158, 11, 0.25);
  color: #fbbf24;
  font-size: 0.85rem;
  font-weight: 600;
}

.retry-dot {
  width: 8px;
  height: 8px;
  background: #f59e0b;
  border-radius: 50%;
  flex-shrink: 0;
}

/* ─── FETCH ERROR CARD ──────────────────── */
.fetch-error-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
  padding: 48px 32px;
  border-radius: 16px;
  border: 1px solid rgba(239, 68, 68, 0.3);
  background: rgba(239, 68, 68, 0.05);
}

.fec-icon { font-size: 3rem; margin-bottom: 16px; }
.fec-title { font-size: 1.2rem; font-weight: 700; color: #f87171; margin-bottom: 8px; }
.fec-desc { color: var(--muted); font-size: 0.85rem; max-width: 300px; }
.fec-hint { color: #64748b; font-size: 0.75rem; font-style: italic; }

/* ─── PEMBELIAN WIDGET ──────────────────── */
.pembelian-widget {
  grid-column: span 4;
  display: flex;
  flex-direction: column;
  padding: 16px 20px;
}

.pw-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.pw-title-group {
  display: flex;
  align-items: center;
  gap: 10px;
}

.pw-title {
  font-size: 0.75rem;
  letter-spacing: 0.15em;
  color: var(--color-text-dim);
}

.pw-link {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 0.75rem;
  color: var(--gold-egg);
  text-decoration: none;
  font-weight: 600;
  transition: all 0.2s;
}

.pw-link:hover { opacity: 0.8; transform: translateX(2px); }

.pw-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
  flex: 1;
}

.pw-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 10px 12px;
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid rgba(255, 255, 255, 0.05);
  border-radius: 12px;
  transition: all 0.2s;
}

.pw-item:hover { background: rgba(255, 255, 255, 0.05); }

.pw-item-left {
  display: flex;
  align-items: center;
  gap: 12px;
}

.pw-item-icon {
  width: 32px;
  height: 32px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(255, 255, 255, 0.05);
  color: var(--color-text-dim);
}

.pw-item-icon.lunas { color: #10b981; background: rgba(16, 185, 129, 0.1); }
.pw-item-icon.hutang { color: #ef4444; background: rgba(239, 68, 68, 0.1); }
.pw-item-icon.tempo { color: #facc15; background: rgba(250, 204, 21, 0.1); }

.pw-item-info {
  display: flex;
  flex-direction: column;
}

.pw-item-name {
  font-size: 0.85rem;
  font-weight: 600;
  color: white;
}

.pw-item-meta {
  font-size: 0.7rem;
  color: var(--color-text-dim);
}

.pw-item-right {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 2px;
}

.pw-item-amount {
  font-size: 0.85rem;
  font-weight: 700;
  color: white;
}

.pw-item-status {
  font-size: 0.65rem;
  font-weight: 800;
  padding: 2px 6px;
  border-radius: 4px;
  background: rgba(255, 255, 255, 0.05);
}

.pw-item-status.lunas { color: #10b981; }
.pw-item-status.hutang { color: #ef4444; }
.pw-item-status.tempo { color: #facc15; }

.pw-footer {
  margin-top: 16px;
  padding-top: 12px;
  border-top: 1px solid rgba(255, 255, 255, 0.05);
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.pw-footer-label {
  font-size: 0.75rem;
  color: var(--color-text-dim);
}

.pw-footer-val {
  font-size: 1rem;
  font-weight: 800;
  color: var(--gold-egg);
}

/* ─── RESPONSIVE ────────────────────────── */
@media (max-width: 1200px) {
  .row-2 { grid-column: span 4; }
  .row-3-main { grid-column: 1 / -1; }
  .row-3-side { grid-column: 1 / -1; }
  .row-4 { grid-column: span 4; }
}

@media (max-width: 768px) {
  .dashboard-grid {
    display: flex;
    flex-direction: column;
    gap: 12px;
  }
  
  .command-metrics-scroller {
    display: flex;
    flex-direction: column;
    overflow-x: hidden;
    width: 100%;
    margin-bottom: 8px;
    gap: 12px;
    padding: 0;
  }
  
  .command-metrics-scroller > * {
    width: 100%;
    box-sizing: border-box;
  }

  .row-2, .row-3-main, .row-3-side, .row-4 {
    grid-column: 1 / -1;
    width: 100%;
    box-sizing: border-box;
  }

  .dashboard-content {
    overflow-x: hidden;
    width: 100%;
  }

  .card, .glass-panel, [class*="card"] {
    box-shadow: 0 4px 12px rgba(0,0,0,0.3) !important;
  }

  .dash-section {
    animation: fadeSlideUp 0.4s ease forwards;
    opacity: 0;
  }
  .dash-section:nth-child(1) { animation-delay: 0.05s; }
  .dash-section:nth-child(2) { animation-delay: 0.1s; }
  .dash-section:nth-child(3) { animation-delay: 0.15s; }
  .dash-section:nth-child(4) { animation-delay: 0.2s; }
  .dash-section:nth-child(5) { animation-delay: 0.25s; }
  .dash-section:nth-child(6) { animation-delay: 0.3s; }
  .dash-section:nth-child(7) { animation-delay: 0.35s; }
  .dash-section:nth-child(8) { animation-delay: 0.4s; }

  .combined-debt-card {
    background: rgba(15,23,42,0.8) !important;
    border: 1px solid rgba(255,255,255,0.07) !important;
  }
  .cdc-divider {
    background: rgba(255,255,255,0.06) !important;
    width: 1px;
  }
  .cdc-label-row { display: flex; align-items: center; gap: 4px; }
  .icon-xxs { width: 14px; height: 14px; }
  .text-slate-400 { color: #94a3b8 !important; }

  .btn-bayar {
    background: rgba(239,68,68,0.1) !important;
    border: 1px solid rgba(239,68,68,0.3) !important;
    color: #ef4444 !important;
  }
  .btn-bayar:hover { background: rgba(239,68,68,0.2) !important; }

  .btn-tagih {
    background: rgba(250,204,21,0.1) !important;
    border: 1px solid rgba(250,204,21,0.3) !important;
    color: #facc15 !important;
  }
}

@keyframes fadeSlideUp {
  from {
    opacity: 0;
    transform: translateY(16px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
</style>
