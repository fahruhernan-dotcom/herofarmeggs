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

    <!-- SKELETON LOADING STATE -->
    <section v-if="loading" class="dashboard-grid">
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
      <div class="command-metrics-scroller" :class="{ 'scroll-x': isMobile }">
        <NetPositionCard
          :netPosition="netPosition"
          :totalCost="totalCost"
          :revenue="totalRevenue"
          :pct="modalKembaliPct"
          class="row-2 animate-row"
          style="--row-delay: 0"
        />
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
        class="row-3-main animate-row"
        style="--row-delay: 3"
      />
      <StockStatusCard
        :grades="eggInventory"
        :potentialRevenue="potentialRevenue"
        class="row-3-side animate-row"
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
        class="row-4 animate-row"
        style="--row-delay: 5"
      />
      <PiutangAgingCard
        :paid="piutangBuckets.paid"
        :week1="piutangBuckets.week1"
        :week2="piutangBuckets.week2"
        :overdue="piutangBuckets.overdue"
        class="row-4 animate-row"
        style="--row-delay: 6"
      />
      <TopPelangganCard
        :customers="topCustomers"
        class="row-4 animate-row"
        style="--row-delay: 7"
      />
    </section>

    <!-- DANGER ZONE -->
    <section v-if="authStore.isAdmin" class="danger-zone glass-panel mt-8">
      <div class="dz-header">
        <div>
          <h3 class="hero-font text-error">System Maintenance</h3>
          <p class="text-dim">Danger Zone: Operations below are irreversible.</p>
        </div>
        <button class="btn-error" @click="showResetModal = true">
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
// @ts-ignore
import { formatCurrency } from '../utils/formatters'

// Icons
import { Trash2Icon, AlertTriangleIcon, DownloadIcon, AlertOctagonIcon } from 'lucide-vue-next'

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
  fetchData,
  setupRealtime,
  cleanup
} = useDashboard()

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

async function exportBackupData() {
  backupStatus.value = 'downloading'
  try {
    const { data: sales } = await supabase.from('sales').select('*, sale_items(*)')
    const { data: customers } = await supabase.from('customers').select('*')
    const { data: stockLogs } = await supabase.from('stock_logs').select('*')
    const { data: finance } = await supabase.from('finance_entries').select('*')

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
  }
}

async function handleSystemReset() {
  if (resetConfirmation.value !== 'RESET HERO FARM') return
  reseting.value = true
  try {
    await supabase.from('sale_items').delete().not('id', 'is', null)
    await supabase.from('sales').delete().not('id', 'is', null)
    await supabase.from('stock_logs').delete().not('id', 'is', null)
    await supabase.from('finance_entries').delete().not('id', 'is', null)
    await supabase.from('customers').update({ total_orders: 0, total_spent: 0 }).not('id', 'is', null)
    await supabase.from('inventory').update({
      current_stock: 0, cost_per_egg: 0, cost_per_packaging: 0,
      cost_per_sticker: 0, cost_per_card: 0, cost_price: 0
    }).not('id', 'is', null)
    showToast('Sistem berhasil direset')
    closeResetModal()
    fetchData()
  } catch {
    showToast('Gagal total reset sistem', 'error')
  } finally {
    reseting.value = false
  }
}

// Lifecycle
onMounted(() => {
  fetchData()
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
    overflow-x: auto;
    margin-bottom: 8px;
    gap: 12px;
    padding-bottom: 8px;
  }
  
  .command-metrics-scroller > * {
    min-width: 280px;
    flex-shrink: 0;
  }

  .row-2, .row-3-main, .row-3-side, .row-4 {
    grid-column: 1 / -1;
    width: 100%;
  }
}
</style>
