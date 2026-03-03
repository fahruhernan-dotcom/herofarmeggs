<template>
  <div class="dashboard-content">
    <header class="workspace-header">
      <div class="header-content">
        <h1 class="hero-font">Operational Overview</h1>
        <p class="text-dim">Real-time monitoring of Hero Farm standards.</p>
      </div>
      <div class="header-actions">
        <div class="net-position-banner glass-panel" :class="{ 'warning': netPosition < 0 }">
           <div class="np-info">
             <span class="np-label">Profit Net Position</span>
             <span class="np-val" :class="netPosition >= 0 ? 'text-green' : 'text-red'">
               {{ netPosition >= 0 ? '+' : '' }}Rp {{ netPosition.toLocaleString('id-ID') }}
             </span>
           </div>
           <div v-if="netPosition < 0" class="np-warning pulse">
             <AlertTriangleIcon class="icon-xs" />
             <span>Hati-Hati Arus Kas</span>
           </div>
        </div>
        <div class="time-widget glass-panel">
          <span class="dot pulse"></span>
          {{ currentTime }}
        </div>
      </div>
    </header>

    <!-- Premium Widgets Grid (2x3) -->
    <section class="premium-grid" v-if="loading">
      <SkeletonLoader v-for="i in 6" :key="i" type="card" height="380px" />
    </section>
    <section class="premium-grid" v-else>
      <!-- WIDGET 1: REVENUE STATUS -->
      <div class="glass-panel widget animate-fade-up" style="--delay: 1">
        <div class="widget-header">
          <div class="wh-left">
            <h4 class="widget-title">Pendapatan</h4>
            <div v-if="revenueWidget.growth.status !== 'none'" 
                 class="growth-pill" :class="revenueWidget.growth.status">
              {{ revenueWidget.growth.status === 'up' ? '↑' : '↓' }} 
              {{ revenueWidget.growth.val }}% 
              <span class="text-xs opacity-70 ml-1">dari bulan lalu</span>
            </div>
          </div>
        </div>
        <div class="chart-container donut">
          <Doughnut :data="revenueWidget.chartData" :options="{ cutout: '75%', plugins: { legend: { display: false } } }" />
          <div class="chart-center">
            <span class="cc-val">{{ revenueWidget.current.count }}</span>
            <span class="cc-label">Orders</span>
          </div>
        </div>
        <div class="legend-detailed">
          <div class="legend-item">
            <span class="dot lunas"></span>
            <span class="label">Lunas</span>
            <span class="val">Rp {{ revenueWidget.current.paid.toLocaleString('id-ID') }}</span>
          </div>
          <div class="legend-item">
            <span class="dot pending"></span>
            <span class="label">Pending</span>
            <span class="val">Rp {{ revenueWidget.current.pending.toLocaleString('id-ID') }}</span>
          </div>
          <div class="legend-item">
            <span class="dot void"></span>
            <span class="label">Void</span>
            <span class="val">Rp {{ revenueWidget.current.void.toLocaleString('id-ID') }}</span>
          </div>
        </div>
      </div>

      <!-- WIDGET 2: TOP CUSTOMERS -->
      <div class="glass-panel widget animate-fade-up" style="--delay: 2">
        <div class="widget-header">
          <div class="wh-left">
            <h4 class="widget-title">Top Pelanggan</h4>
            <span class="badge-mini">Bulan Ini</span>
          </div>
          <router-link to="/customers" class="link-more">Lihat Semua <ChevronRightIcon class="icon-xs" /></router-link>
        </div>
        <div class="chart-container bar">
          <Bar :data="topCustomersWidget.chartData" :options="{ 
            indexAxis: 'y', 
            plugins: { legend: { display: false } },
            scales: { x: { display: false }, y: { grid: { display: false }, ticks: { color: 'rgba(255,255,255,0.5)', font: { size: 10 } } } }
          }" />
        </div>
      </div>

      <!-- WIDGET 3: REALTIME STOK -->
      <div class="glass-panel widget animate-fade-up" style="--delay: 3">
        <div class="widget-header">
          <div class="wh-left">
            <h4 class="widget-title">Status Stok</h4>
            <div class="live-dot pulse"></div>
          </div>
        </div>
        <div class="stock-visual-grid">
          <div v-for="item in eggInventory" :key="item.id" class="sv-row">
            <div class="sv-info">
              <span class="sv-name">{{ item.label }}</span>
              <span class="sv-pill" :class="getDashboardStatus(item.current_stock)">
                {{ (item.current_stock || 0).toLocaleString('id-ID') }} Butir
              </span>
            </div>
            <div class="sv-progress-bg">
              <div class="sv-progress-fill" 
                   :class="getDashboardStatus(item.current_stock)"
                   :style="{ width: Math.min(((item.current_stock || 0) / 100) * 100, 100) + '%' }">
              </div>
            </div>
          </div>
        </div>
        <div class="supply-summary">
          <div v-for="s in packagingInventory" :key="s.id" class="supply-badge">
            <span class="sb-label">{{ s.label.split(' ')[0] }}</span>
            <span class="sb-val">{{ (s.current_stock || 0).toLocaleString('id-ID') }}</span>
          </div>
        </div>
      </div>

      <!-- WIDGET 4: CASH FLOW 30 HARI -->
      <div class="glass-panel widget animate-fade-up" style="--delay: 4">
        <div class="widget-header">
          <div class="wh-left">
            <h4 class="widget-title">Arus Kas</h4>
            <span class="text-xs opacity-60">30 Hari Terakhir</span>
          </div>
          <div class="net-summary" :class="cashFlowWidget.net >= 0 ? 'plus' : 'minus'">
            Net: Rp {{ cashFlowWidget.net.toLocaleString('id-ID') }}
          </div>
        </div>
        <div class="chart-container line">
          <Line :data="cashFlowWidget.chartData" :options="{ 
            responsive: true, 
            maintainAspectRatio: false,
            plugins: { legend: { display: false } }, 
            scales: { 
              x: { grid: { display: false }, ticks: { color: 'rgba(255,255,255,0.3)', font: { size: 9 } } },
              y: { grid: { color: 'rgba(255,255,255,0.05)' }, ticks: { color: 'rgba(255,255,255,0.3)', font: { size: 9 }, callback: (v: any) => v.toLocaleString('id-ID') } }
            }
          }" />
        </div>
      </div>

      <!-- WIDGET 5: PENJUALAN PER PRODUK -->
      <div class="glass-panel widget animate-fade-up" style="--delay: 5">
        <div class="widget-header">
          <div class="wh-left">
            <h4 class="widget-title">Komposisi Penjualan</h4>
          </div>
          <div class="period-select">Bulan Ini</div>
        </div>
        <div class="chart-container donut-mini">
          <Doughnut :data="salesProductWidget.chartData" :options="{ cutout: '70%', plugins: { legend: { display: false } } }" />
          <div class="chart-center">
            <span class="cc-val-sm">{{ (salesProductWidget.total || 0).toLocaleString('id-ID') }}</span>
            <span class="cc-label-xs">Packs</span>
          </div>
        </div>
        <div class="legend-grid">
          <div v-for="(val, label) in { 'Hero': salesProductWidget.heroCount, 'Standard': salesProductWidget.standardCount, 'Salted': salesProductWidget.saltedCount }" :key="label" class="lg-item">
            <span class="lg-val">{{ (val || 0).toLocaleString('id-ID') }}</span>
            <span class="lg-label">{{ label }}</span>
          </div>
        </div>
      </div>

      <!-- WIDGET 6: PIUTANG / AGING -->
      <div class="glass-panel widget animate-fade-up" style="--delay: 6">
        <div class="widget-header">
          <div class="wh-left">
            <h4 class="widget-title">Piutang</h4>
            <div v-if="piutangWidget.overdue.count > 0" class="badge-error animate-pulse">! Overdue</div>
          </div>
          <router-link to="/financial" class="link-more">Semua Piutang <ChevronRightIcon class="icon-xs" /></router-link>
        </div>
        <div class="aging-buckets">
          <div class="bucket-row green">
            <span class="b-label">Lunas</span>
            <div class="b-bar"><div class="b-fill" style="width: 100%"></div></div>
            <span class="b-val">Rp {{ (piutangWidget.paid.total || 0).toLocaleString('id-ID') }}</span>
          </div>
          <div class="bucket-row amber">
            <span class="b-label">0-7 h</span>
            <div class="b-bar"><div class="b-fill" :style="{ width: Math.min(((piutangWidget.week1.total || 0) / 10000000) * 100, 100) + '%' }"></div></div>
            <span class="b-val">Rp {{ (piutangWidget.week1.total || 0).toLocaleString('id-ID') }}</span>
          </div>
          <div class="bucket-row orange">
            <span class="b-label">8-14 h</span>
            <div class="b-bar"><div class="b-fill" :style="{ width: Math.min(((piutangWidget.week2.total || 0) / 10000000) * 100, 100) + '%' }"></div></div>
            <span class="b-val">Rp {{ (piutangWidget.week2.total || 0).toLocaleString('id-ID') }}</span>
          </div>
          <div class="bucket-row red" :class="{ 'pulse': piutangWidget.overdue.count > 0 }">
            <span class="b-label">15+ h</span>
            <div class="b-bar"><div class="b-fill" :style="{ width: Math.min(((piutangWidget.overdue.total || 0) / 10000000) * 100, 100) + '%' }"></div></div>
            <span class="b-val">Rp {{ (piutangWidget.overdue.total || 0).toLocaleString('id-ID') }}</span>
          </div>
        </div>
      </div>
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
import { ref, reactive, computed, onMounted, onUnmounted } from 'vue';
import { supabase } from '../lib/supabase';
import { useAuthStore } from '../stores/auth';
// import StatsCard from '../components/ui/StatsCard.vue';

import { 
  Trash2Icon, 
  AlertTriangleIcon, 
  DownloadIcon,
  AlertOctagonIcon,
  ChevronRightIcon
} from 'lucide-vue-next';
import { 
  Chart as ChartJS, 
  Title, Tooltip, Legend, ArcElement, 
  CategoryScale, LinearScale, PointElement, 
  LineElement, BarElement, Filler 
} from 'chart.js';
import { useToast } from '../composables/useToast';
import SkeletonLoader from '../components/ui/SkeletonLoader.vue';
import { Doughnut, Line, Bar } from 'vue-chartjs';

ChartJS.register(
  Title, Tooltip, Legend, ArcElement, 
  CategoryScale, LinearScale, PointElement, 
  LineElement, BarElement, Filler
);

const { showToast } = useToast();
const authStore = useAuthStore();
const loading = ref(true);
const heroStock = ref(0);
const standardStock = ref(0);
const saltedStock = ref(0);
const logs = ref<any[]>([]);
const currentTime = ref('');
const customers = ref<any[]>([]);
const financeEntries = ref<any[]>([]);
const allSales = ref<any[]>([]);
const inventory = ref<any[]>([]);
const kpiData = ref<any>({
  total_revenue: 0,
  gross_profit: 0,
  total_piutang: 0,
  total_utang: 0,
  stock_value: 0
});

// Net Position Calculation
const netPosition = computed(() => {
  const cash = financeEntries.value.reduce((acc, f) => {
    if (f.entry_type === 'income') return acc + Number(f.amount);
    if (f.entry_type === 'expense') return acc - Number(f.amount);
    return acc;
  }, 0);
  // Actually Net Position = Cash + Piutang - Utang
  return cash + kpiData.value.total_piutang - kpiData.value.total_utang;
});

// NEW: Impact counts for Reset
const impactCounts = reactive({
  sales: 0,
  customers: 0,
  logs: 0,
  finance: 0
});

// ─── HELPER: GROWTH CALCULATION ────────────────
function calculateGrowth(current: number, previous: number) {
  if (previous === 0) return current > 0 ? { val: 100, status: 'new' } : { val: 0, status: 'none' };
  const diff = ((current - previous) / previous) * 100;
  return { val: Math.abs(diff).toFixed(1), status: diff >= 0 ? 'up' : 'down' };
}

function getPeriodStats(salesArr: any[], offsetMonths = 0) {
  const now = new Date();
  const start = new Date(now.getFullYear(), now.getMonth() - offsetMonths, 1);
  const end = new Date(now.getFullYear(), now.getMonth() - offsetMonths + 1, 0, 23, 59, 59);
  
  const filtered = salesArr.filter((s: any) => {
    if (!s.created_at) return false;
    const d = new Date(s.created_at);
    return d >= start && d <= end;
  });

  return {
    total: filtered.reduce((acc: number, s: any) => acc + (s.total_price || 0), 0),
    count: filtered.length,
    paid: filtered.filter((s: any) => s.payment_status === 'paid').reduce((acc: number, s: any) => acc + (s.total_price || 0), 0),
    pending: filtered.filter((s: any) => s.payment_status === 'pending').reduce((acc: number, s: any) => acc + (s.total_price || 0), 0),
    void: filtered.filter((s: any) => s.payment_status === 'voided').reduce((acc: number, s: any) => acc + (s.total_price || 0), 0),
    items: filtered.flatMap((s: any) => s.sale_items || [])
  };
}

// ─── WIDGET 3: REALTIME STOK ────────────────
const eggInventory = computed(() => inventory.value.filter((i: any) => i.item_type !== 'packaging'));
const packagingInventory = computed(() => inventory.value.filter((i: any) => i.item_type === 'packaging'));

// ─── WIDGET 1: REVENUE STATUS ────────────────
const revenueWidget = computed(() => {
  const current = getPeriodStats(allSales.value, 0);
  const previous = getPeriodStats(allSales.value, 1);
  const growth = calculateGrowth(current.paid, previous.paid);
  
  return {
    current,
    growth,
    chartData: {
      labels: ['Lunas', 'Pending', 'Void'],
      datasets: [{
        data: [current.paid, current.pending, current.void],
        backgroundColor: ['#10b981', '#f59e0b', '#ef4444'],
        borderWidth: 0,
        hoverOffset: 4
      }]
    }
  };
});

// ─── WIDGET 2: TOP CUSTOMERS (THIS MONTH) ────
const topCustomersWidget = computed(() => {
  // Aggregate by customer_id
  const customerMap: Record<string, { name: string, total: number }> = {};
  allSales.value.filter((s: any) => {
    if (!s.created_at) return false;
    const d = new Date(s.created_at);
    return d.getMonth() === new Date().getMonth() && d.getFullYear() === new Date().getFullYear();
  }).forEach((s: any) => {
    const cust = (customers.value || []).find((c: any) => c?.id === s.customer_id);
    if (!s.customer_id || !cust) return;
    if (!customerMap[s.customer_id]) {
      customerMap[s.customer_id] = { name: cust.name, total: 0 };
    }
    const entry = customerMap[s.customer_id];
    if (entry) entry.total += (s.total_price || 0);
  });

  const sorted = Object.values(customerMap)
    .sort((a, b) => b.total - a.total)
    .slice(0, 5);

  return {
    chartData: {
      labels: sorted.map(c => c.name),
      datasets: [{
        label: 'Total Belanja (Rp)',
        data: sorted.map(c => c.total),
        backgroundColor: 'rgba(245, 158, 11, 0.8)',
        borderRadius: 5,
        borderWidth: 0,
        barThickness: 12
      }]
    }
  };
});

// ─── WIDGET 4: CASH FLOW (30 DAYS) ──────────
const cashFlowWidget = computed(() => {
  const dates = [];
  const income = [];
  const expense = [];
  const today = new Date();
  
  for (let i = 29; i >= 0; i--) {
    const d = new Date(today);
    d.setDate(d.getDate() - i);
    const dateStr = d.toISOString().split('T')[0];
    dates.push(d.toLocaleDateString('id-ID', { day: 'numeric', month: 'short' }));
    
    const dayFin = financeEntries.value.filter((f: any) => f.entry_date === dateStr);
    income.push(dayFin.filter((f: any) => f.entry_type === 'income').reduce((a: number, f: any) => a + Number(f.amount), 0));
    expense.push(dayFin.filter((f: any) => f.entry_type === 'expense').reduce((a: number, f: any) => a + Number(f.amount), 0));
  }

  const net = income.reduce((a: number, b: number) => a + b, 0) - expense.reduce((a: number, b: number) => a + b, 0);

  return {
    net,
    chartData: {
      labels: dates,
      datasets: [
        {
          label: 'Pemasukan',
          data: income,
          borderColor: '#14b8a6',
          backgroundColor: 'rgba(20, 184, 166, 0.1)',
          fill: true,
          tension: 0.4
        },
        {
          label: 'Pengeluaran',
          data: expense,
          borderColor: '#ef4444',
          backgroundColor: 'rgba(239, 68, 68, 0.1)',
          fill: true,
          tension: 0.4
        }
      ]
    }
  };
});

// ─── WIDGET 5: SALES PER PRODUCT ────────────
const salesProductWidget = computed(() => {
  const current = getPeriodStats(allSales.value, 0);
  const items = current.items;
  
  const heroCount = items.filter((i: any) => i.egg_type === 'hero_size').reduce((a: number, i: any) => a + i.quantity, 0);
  const standardCount = items.filter((i: any) => i.egg_type === 'standard_size').reduce((a: number, i: any) => a + i.quantity, 0);
  const saltedCount = items.filter((i: any) => i.egg_type === 'salted_egg').reduce((a: number, i: any) => a + i.quantity, 0);
  const total = heroCount + standardCount + saltedCount;

  return {
    total,
    heroCount, standardCount, saltedCount,
    chartData: {
      labels: ['Hero Egg', 'Standard Egg', 'Salted Egg'],
      datasets: [{
        data: [heroCount, standardCount, saltedCount],
        backgroundColor: ['#fcc419', '#339af0', '#be4bdb'],
        borderWidth: 0
      }]
    }
  };
});

// ─── WIDGET 6: PIUTANG AGING ────────────────
const piutangWidget = computed(() => {
  const pendingSales = allSales.value.filter(s => s.payment_status === 'pending');
  const now = new Date();
  
  const buckets = {
    paid: { count: allSales.value.filter(s => s.payment_status === 'paid').length, total: allSales.value.filter(s => s.payment_status === 'paid').reduce((a, s) => a + (s.total_price || 0), 0) },
    week1: { count: 0, total: 0 }, // 0-7 days
    week2: { count: 0, total: 0 }, // 8-14 days
    overdue: { count: 0, total: 0 } // 15+ days
  };

  pendingSales.forEach((s: any) => {
    const created = new Date(s.created_at);
    const diffDays = Math.floor((now.getTime() - created.getTime()) / (1000 * 3600 * 24));
    
    // In V2, we use kpiData for totals but still need aging for buckets
    if (diffDays <= 7) { 
      buckets.week1.count++; 
      buckets.week1.total += (s.total_price || 0); 
    } else if (diffDays <= 14) { 
      buckets.week2.count++; 
      buckets.week2.total += (s.total_price || 0); 
    } else { 
      buckets.overdue.count++; 
      buckets.overdue.total += (s.total_price || 0); 
    }
  });

  // Override total from institutional KPI
  buckets.week1.total = kpiData.value.total_piutang_7d || buckets.week1.total;
  buckets.week2.total = kpiData.value.total_piutang_14d || buckets.week2.total;
  buckets.overdue.total = kpiData.value.total_piutang_overdue || buckets.overdue.total;

  return buckets;
});

// Reset Logic
const showResetModal = ref(false);
const resetStep = ref(1);
const backupStatus = ref<'idle' | 'downloading' | 'downloaded'>('idle');
const backupDownloaded = ref(false);
const resetConfirmation = ref('');
const reseting = ref(false);

function updateClock() {
  const now = new Date();
  currentTime.value = now.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' });
}

let clockInterval: any;
let refreshInterval: any;

async function fetchData() {
  loading.value = true;
  try {
    // Fetch Stocks
    const { data: stocks } = await supabase.from('inventory').select('*');
    if (stocks) {
      inventory.value = stocks;
      heroStock.value = stocks.find(s => s.id === 'hero_size')?.current_stock ?? 0;
      standardStock.value = stocks.find(s => s.id === 'standard_size')?.current_stock ?? 0;
      saltedStock.value = stocks.find(s => s.id === 'salted_egg')?.current_stock ?? 0;
    }

    // Fetch ALL sales
    const { data: sales } = await supabase
      .from('sales')
      .select('*, sale_items(*)')
      .order('created_at', { ascending: false });
    if (sales) allSales.value = sales;

    // Fetch customers
    const { data: cust } = await supabase.from('customers').select('*').eq('is_deleted', false);
    if (cust) customers.value = cust;

    // Fetch Finance
    const { data: fin } = await supabase.from('finance_entries').select('*').order('entry_date', { ascending: false });
    if (fin) financeEntries.value = fin;

    // Fetch Logs
    const { data: latestLogs } = await supabase
      .from('stock_logs')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(8);
    if (latestLogs) logs.value = latestLogs;

    // Fetch Impact Counts (for Reset)
    const { data: kpis } = await supabase.rpc('get_dashboard_kpis');
    if (kpis) kpiData.value = kpis;

    if (authStore.isAdmin) {
      const { count: sCount } = await supabase.from('sales').select('*', { count: 'exact', head: true });
      const { count: cCount } = await supabase.from('customers').select('*', { count: 'exact', head: true });
      const { count: lCount } = await supabase.from('stock_logs').select('*', { count: 'exact', head: true });
      const { count: fCount } = await supabase.from('finance_entries').select('*', { count: 'exact', head: true });
      impactCounts.sales = sCount || 0;
      impactCounts.customers = cCount || 0;
      impactCounts.logs = lCount || 0;
      impactCounts.finance = fCount || 0;
    }
  } finally {
    loading.value = false;
  }
}

// ─── COMPUTED ───────────────────────

// Monthly revenue: only PAID orders from THIS MONTH
function getDashboardStatus(stock: number) {
  if (stock <= 20) return 'critical';
  if (stock <= 25) return 'low';
  return 'healthy';
}

function closeResetModal() {
  showResetModal.value = false;
  resetStep.value = 1;
  backupStatus.value = 'idle';
  backupDownloaded.value = false;
  resetConfirmation.value = '';
}

async function exportBackupData() {
  backupStatus.value = 'downloading';
  try {
    const { data: sales } = await supabase.from('sales').select('*, sale_items(*)');
    const { data: customers } = await supabase.from('customers').select('*');
    const { data: stockLogs } = await supabase.from('stock_logs').select('*');
    const { data: finance } = await supabase.from('finance_entries').select('*');
    
    const backupData = {
      exported_at: new Date().toISOString(),
      sales: sales || [],
      customers: customers || [],
      stock_logs: stockLogs || [],
      finance_entries: finance || []
    };

    const blob = new Blob([JSON.stringify(backupData, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    
    const now = new Date();
    const dateStr = now.toISOString().slice(0, 10).replace(/-/g, '');
    const timeStr = now.toTimeString().slice(0, 8).replace(/:/g, '');
    
    a.href = url;
    a.download = `hero-farm-backup-${dateStr}-${timeStr}.json`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
    
    showToast('Backup berhasil diunduh');
    backupStatus.value = 'downloaded';
  } catch (err: any) {
    showToast('Gagal backup data', 'error');
    backupStatus.value = 'idle';
  }
}

async function handleSystemReset() {
  if (resetConfirmation.value !== 'RESET HERO FARM') return;
  
  reseting.value = true;
  
  try {
    const { error: e1 } = await supabase.from('sale_items').delete().not('id', 'is', null);
    const { error: e2 } = await supabase.from('sales').delete().not('id', 'is', null);
    const { error: e3 } = await supabase.from('stock_logs').delete().not('id', 'is', null);
    const { error: e6 } = await supabase.from('finance_entries').delete().not('id', 'is', null);

    if (e1 || e2 || e3 || e6) {
      console.error('Deletion Errors:', { e1, e2, e3, e6 });
    }

    const { error: e4 } = await supabase.from('customers').update({ 
      total_orders: 0, 
      total_spent: 0
    }).not('id', 'is', null);

    const { error: e5 } = await supabase.from('inventory').update({ 
      current_stock: 0,
      cost_per_egg: 0,
      cost_per_packaging: 0,
      cost_per_sticker: 0,
      cost_per_card: 0,
      cost_price: 0
    }).not('id', 'is', null);

    if (e4 || e5) {
      showToast('Gagal reset sebagian data', 'error');
    } else {
      showToast('Sistem berhasil direset');
    }

    closeResetModal();
    fetchData(); 
  } catch (err: any) {
    showToast('Gagal total reset sistem', 'error');
  } finally {
    reseting.value = false;
  }
}

onMounted(() => {
  fetchData();
  updateClock();
  clockInterval = setInterval(updateClock, 1000);
  refreshInterval = setInterval(fetchData, 10000); // Background refresh every 10s

  const inventorySubscription = supabase
    .channel('dashboard-updates')
    .on('postgres_changes', { event: '*', schema: 'public', table: 'inventory' }, () => {
      fetchData();
    })
    .subscribe();

  onUnmounted(() => {
    clearInterval(clockInterval);
    clearInterval(refreshInterval);
    inventorySubscription.unsubscribe();
  });
});
</script>

<style scoped>
/* ─── PREMIUM GRID ──────────────── */
.premium-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
  gap: 24px;
}

.widget {
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 20px;
  min-height: 380px;
  transition: transform 0.3s ease, border-color 0.3s ease;
}

/* NET POSITION BANNER */
.net-position-banner {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 8px 16px;
  border-radius: 12px;
  border-left: 4px solid #10b981;
}

.net-position-banner.warning {
  border-left-color: #ef4444;
  background: rgba(239, 68, 68, 0.05);
}

.np-info {
  display: flex;
  flex-direction: column;
}

.np-label {
  font-size: 0.65rem;
  font-weight: 800;
  text-transform: uppercase;
  color: var(--color-text-dim);
  letter-spacing: 0.05em;
}

.np-val {
  font-size: 1.2rem;
  font-weight: 900;
}

.np-warning {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 4px 10px;
  background: rgba(239, 68, 68, 0.15);
  color: #ef4444;
  border-radius: 20px;
  font-size: 0.7rem;
  font-weight: 800;
}

.pulse {
  animation: pulse-ring 1.5s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

@keyframes pulse-ring {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.5; }
}

.widget:hover {
  transform: translateY(-4px);
  border-color: rgba(255, 255, 255, 0.15);
}

.widget-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
}

.widget-title {
  font-size: 0.9rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  color: var(--color-text-dim);
}

.growth-pill {
  display: inline-flex;
  align-items: center;
  padding: 4px 10px;
  border-radius: 20px;
  font-size: 0.7rem;
  font-weight: 800;
  margin-top: 6px;
}

.growth-pill.up { background: rgba(16, 185, 129, 0.15); color: #10b981; }
.growth-pill.down { background: rgba(239, 68, 68, 0.15); color: #ef4444; }

.badge-mini {
  font-size: 10px;
  background: rgba(255, 255, 255, 0.05);
  padding: 2px 8px;
  border-radius: 4px;
  color: var(--color-text-dim);
}

/* ─── CHART CONTAINERS ──────────── */
.chart-container {
  flex: 1;
  position: relative;
  display: flex;
  justify-content: center;
  align-items: center;
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
.cc-label { font-size: 0.7rem; color: var(--color-text-dim); text-transform: uppercase; }
.cc-val-sm { font-size: 1.6rem; font-weight: 900; line-height: 1; }
.cc-label-xs { font-size: 10px; color: var(--color-text-dim); }

/* ─── LEGENDS ───────────────────── */
.legend-detailed {
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding-top: 16px;
  border-top: 1px solid rgba(255, 255, 255, 0.05);
}

.legend-item {
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 0.8rem;
}

.dot { width: 8px; height: 8px; border-radius: 50%; }
.dot.lunas { background: #10b981; box-shadow: 0 0 8px #10b981; }
.dot.pending { background: #f59e0b; box-shadow: 0 0 8px #f59e0b; }
.dot.void { background: #ef4444; box-shadow: 0 0 8px #ef4444; }

.legend-item .label { flex: 1; color: var(--color-text-dim); }
.legend-item .val { font-weight: 700; font-family: 'JetBrains Mono', monospace; }

.link-more {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 11px;
  color: var(--color-primary);
  text-decoration: none;
  font-weight: 600;
  transition: opacity 0.3s;
}

.link-more:hover { opacity: 0.8; }

/* ─── STOCK GRID ────────────────── */
.stock-visual-grid {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.sv-row {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.sv-info {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.sv-name { font-size: 0.85rem; font-weight: 600; }
.sv-pill {
  padding: 2px 8px;
  border-radius: 4px;
  font-size: 11px;
  font-weight: 800;
}

.sv-pill.healthy { background: rgba(16, 185, 129, 0.1); color: #10b981; }
.sv-pill.low { background: rgba(245, 158, 11, 0.1); color: #f59e0b; }
.sv-pill.critical { background: rgba(239, 68, 68, 0.1); color: #ef4444; }

.sv-progress-bg {
  height: 6px;
  background: rgba(255, 255, 255, 0.03);
  border-radius: 3px;
  overflow: hidden;
}

.sv-progress-fill {
  height: 100%;
  border-radius: 3px;
  transition: width 1s ease;
}

.sv-progress-fill.healthy { background: #10b981; }
.sv-progress-fill.low { background: #f59e0b; }
.sv-progress-fill.critical { background: #ef4444; animation: progress-pulse 2s infinite; }

@keyframes progress-pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.6; }
}

.live-dot {
  width: 8px;
  height: 8px;
  background: #10b981;
  border-radius: 50%;
  box-shadow: 0 0 10px #10b981;
}

.supply-summary {
  display: flex;
  gap: 8px;
  margin-top: auto;
}

.supply-badge {
  flex: 1;
  background: rgba(255, 255, 255, 0.03);
  padding: 8px;
  border-radius: 8px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2px;
}

.sb-label { font-size: 9px; color: var(--color-text-dim); text-transform: uppercase; }
.sb-val { font-size: 0.9rem; font-weight: 800; }

/* ─── CASH FLOW ─────────────────── */
.net-summary {
  font-size: 11px;
  font-weight: 800;
  padding: 4px 10px;
  border-radius: 20px;
}

.net-summary.plus { background: rgba(20, 184, 166, 0.1); color: #14b8a6; }
.net-summary.minus { background: rgba(239, 68, 68, 0.1); color: #ef4444; }

/* ─── LEGEND GRID ────────────────── */
.legend-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 12px;
  margin-top: auto;
}

.lg-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  background: rgba(255, 255, 255, 0.03);
  padding: 8px;
  border-radius: 8px;
}

.lg-val { font-size: 1rem; font-weight: 900; }
.lg-label { font-size: 9px; color: var(--color-text-dim); }

/* ─── AGING BUCKETS ──────────────── */
.aging-buckets {
  display: flex;
  flex-direction: column;
  gap: 12px;
  margin-top: 10px;
}

.bucket-row {
  display: flex;
  align-items: center;
  gap: 12px;
}

.b-label { font-size: 11px; font-weight: 700; width: 50px; color: var(--color-text-dim); }
.b-bar { flex: 1; height: 8px; background: rgba(255, 255, 255, 0.03); border-radius: 4px; overflow: hidden; }
.b-fill { height: 100%; border-radius: 4px; transition: width 1s ease; }
.b-val { font-size: 11px; font-weight: 700; width: 90px; text-align: right; }

.bucket-row.green .b-fill { background: #10b981; }
.bucket-row.amber .b-fill { background: #f59e0b; }
.bucket-row.orange .b-fill { background: #f97316; }
.bucket-row.red .b-fill { background: #ef4444; }

.bucket-row.red.pulse .b-fill { animation: progress-pulse 1.5s infinite; }

.badge-error { font-size: 10px; font-weight: 800; background: rgba(239, 68, 68, 0.2); color: #ef4444; padding: 2px 8px; border-radius: 4px; }

/* ANIMATIONS */
.animate-fade-up {
  opacity: 0;
  animation: fadeUp 0.6s cubic-bezier(0.23, 1, 0.32, 1) forwards;
  animation-delay: calc(var(--delay) * 100ms);
}

@keyframes fadeUp {
  from { opacity: 0; transform: translateY(20px); }
  to { opacity: 1; transform: translateY(0); }
}

@media (max-width: 1200px) {
  .premium-grid { grid-template-columns: 1fr; }
}

.wh-left { display: flex; flex-direction: column; gap: 4px; }
.wh-left .widget-title { margin-bottom: 0; }


/* ─── DANGER ZONE ───────────────── */
.danger-zone {
  padding: 32px;
  border-color: rgba(255, 66, 66, 0.2);
}

.dz-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.text-error { color: #ff4242; }
.tc-meta { font-size: 0.7rem; color: var(--color-text-dim); }
.tc-spent { font-size: 0.85rem; font-weight: 800; color: var(--color-primary); }
.mt-8 { margin-top: 32px; }
.mt-6 { margin-top: 24px; }
.font-bold { font-weight: 700; }

.btn-error {
  background: rgba(255, 66, 66, 0.1);
  color: #ff4242;
  border: 1px solid rgba(255, 66, 66, 0.3);
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
  background: #ff4242;
  color: white;
}

.btn-error:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

/* ─── MODAL ─────────────────────── */
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

.reset-modal {
  text-align: center;
}

.warning-box {
  background: rgba(255, 66, 66, 0.05);
  border: 1px solid rgba(255, 66, 66, 0.15);
  padding: 24px;
  border-radius: var(--radius-md);
  margin-top: 24px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
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
  border-color: #ff4242;
  outline: none;
}

/* RESET STEPPER */
.reset-stepper {
  min-height: 250px;
  display: flex;
  flex-direction: column;
  justify-content: center;
}

.backup-box {
  padding: 32px;
  background: rgba(255, 140, 0, 0.03);
  border: 1px dashed rgba(255, 140, 0, 0.3);
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
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

.animate-slide {
  animation: slideLeft 0.3s cubic-bezier(0.23, 1, 0.32, 1);
}

@keyframes slideLeft {
  from { opacity: 0; transform: translateX(20px); }
  to { opacity: 1; transform: translateX(0); }
}

.animate-pop { animation: popIn 0.3s cubic-bezier(0.23, 1, 0.32, 1); }
@keyframes popIn {
  from { opacity: 0; transform: scale(0.9) translateY(20px); }
  to { opacity: 1; transform: scale(1) translateY(0); }
}

/* RESET STYLES */
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

.backup-box.amber {
  background: rgba(245, 158, 11, 0.05);
  border-color: rgba(245, 158, 11, 0.3);
}

.text-amber { color: #f59e0b; }

.animate-fade-in { animation: fadeIn 0.4s ease forwards; }
@keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }

.form-group {
  display: flex;
  flex-direction: column;
  gap: 12px;
  margin: 24px 0;
}

.form-group label { font-size: 0.8rem; color: var(--color-text-dim); }
</style>
