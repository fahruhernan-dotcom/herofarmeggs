<template>
  <div class="dashboard-content">
    <header class="workspace-header">
      <div class="header-content">
        <h1 class="hero-font">Operational Overview</h1>
        <p class="text-dim">Real-time monitoring of Hero Farm standards.</p>
      </div>
      <div class="header-actions">
        <div class="time-widget glass-panel">
          <span class="dot pulse"></span>
          {{ currentTime }}
        </div>
      </div>
    </header>

    <!-- Stats Grid -->
    <section class="stats-grid">
      <StatsCard 
        label="Hero Size Availability" 
        :value="heroStock" 
        unit="Butir"
        :subtext="`Physical: ${heroStock + reservedHero} | Reserved: ${reservedHero}`"
        :status="getDashboardStatus(heroStock)"
      />
      <StatsCard 
        label="Standard Size Availability" 
        :value="standardStock" 
        unit="Butir"
        :subtext="`Physical: ${standardStock + reservedStandard} | Reserved: ${reservedStandard}`"
        :status="getDashboardStatus(standardStock)"
      />
      <StatsCard 
        label="Telur Asin Availability" 
        :value="saltedStock" 
        unit="Butir"
        :subtext="`Physical: ${saltedStock + reservedSalted} | Reserved: ${reservedSalted}`"
        :status="getDashboardStatus(saltedStock)"
      />
      <StatsCard 
        v-if="authStore.isAdmin"
        label="Revenue (This Month)" 
        :value="'Rp ' + monthlyRevenue.toLocaleString()" 
        unit=""
        :subtext="revenueSubtext"
      />
    </section>

    <!-- Action Cards -->
    <div class="action-cards">
      <router-link to="/orders" class="action-card glass-panel" v-if="pendingOrdersCount > 0">
        <div class="ac-icon pending-icon">
          <ClockIcon />
        </div>
        <div class="ac-info">
          <span class="ac-value">{{ pendingOrdersCount }}</span>
          <span class="ac-label">Pending Orders</span>
        </div>
        <ArrowRightIcon class="ac-arrow" />
      </router-link>
      <router-link to="/orders" class="action-card glass-panel" v-if="onDeliveryCount > 0">
        <div class="ac-icon delivery-icon">
          <TruckIcon />
        </div>
        <div class="ac-info">
          <span class="ac-value">{{ onDeliveryCount }}</span>
          <span class="ac-label">On Delivery</span>
        </div>
        <ArrowRightIcon class="ac-arrow" />
      </router-link>
      <router-link to="/stock" class="action-card glass-panel" v-if="lowStockCount > 0">
        <div class="ac-icon critical-icon">
          <AlertTriangleIcon />
        </div>
        <div class="ac-info">
          <span class="ac-value">{{ lowStockCount }}</span>
          <span class="ac-label">Low Stock Items</span>
        </div>
        <ArrowRightIcon class="ac-arrow" />
      </router-link>
    </div>

    <!-- Sales Summary & Activity -->
    <div class="content-grid">
      <div class="glass-panel main-chart">
        <h4 class="panel-title">Sales Summary (Last 7 Days)</h4>
        <div class="sales-summary-grid" v-if="last7DaysSales.length > 0">
          <div class="day-bar-container" v-for="day in last7DaysSales" :key="day.date">
            <div class="day-bar-wrapper">
              <div 
                class="day-bar" 
                :style="{ height: day.percentage + '%' }"
                :class="{ 'today': day.isToday }"
              ></div>
            </div>
            <span class="day-label">{{ day.label }}</span>
            <span class="day-value" v-if="day.count > 0">{{ day.count }}</span>
          </div>
        </div>
        <div class="chart-placeholder" v-else>
          <p class="text-dim">No sales data available for the past 7 days.</p>
        </div>
        <div class="chart-footer">
          <span class="cf-stat">
            <strong>{{ totalLast7Days }}</strong> orders in last 7 days
          </span>
          <span class="cf-stat">
            <strong>Rp {{ revenueLast7Days.toLocaleString() }}</strong> revenue
          </span>
        </div>
      </div>

      <div class="glass-panel activity-feed">
        <h4 class="panel-title">Recent Logs</h4>
        <div class="feed-list">
          <div v-if="logs.length === 0" class="empty-state">
            No recent activity recorded.
          </div>
          <div v-for="log in logs" :key="log.id" class="feed-item">
            <div class="log-indicator" :class="log.log_type"></div>
            <div class="log-info">
              <p class="log-text"><strong>{{ log.change > 0 ? '+' : '' }}{{ log.change }}</strong> {{ log.egg_type.replace('_', ' ') }}</p>
              <p class="log-meta">{{ formatTime(log.created_at) }} • {{ log.log_type }}</p>
            </div>
          </div>
        </div>
      </div>

      <div class="glass-panel top-customers">
        <h4 class="panel-title">Top Customers (All Time)</h4>
        <div class="top-customers-list">
          <div v-if="topCustomers.length === 0" class="empty-state">
            No customer data yet.
          </div>
          <div v-for="(cust, index) in topCustomers" :key="cust.id" class="tc-item">
            <div class="tc-rank">#{{ index + 1 }}</div>
            <div class="tc-info">
              <p class="tc-name">{{ cust.name }}</p>
              <p class="tc-meta">{{ cust.total_orders }} orders</p>
            </div>
            <div class="tc-spent">
              Rp {{ (cust.total_spent || 0).toLocaleString() }}
            </div>
          </div>
        </div>
      </div>
    </div>

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
            <!-- STEP 1: WARNING -->
            <div v-if="resetStep === 1" class="reset-step animate-slide">
              <div class="warning-box">
                <AlertTriangleIcon class="icon-lg text-error" />
                <p>This action will permanently wipe all Sales, Orders, and Stock Logs. Inventory and Customer profiles will be reset to zero.</p>
              </div>
              <button class="btn-primary w-full mt-6" @click="resetStep = 2">BEGIN RESET PROCESS</button>
            </div>

            <!-- STEP 2: BACKUP -->
            <div v-if="resetStep === 2" class="reset-step animate-slide">
              <div class="backup-box glass-panel">
                <DownloadIcon class="icon-lg text-primary" />
                <h4 class="font-bold mt-4">Security Requirement</h4>
                <p class="text-dim text-sm">You must export a full backup before the reset option becomes available.</p>
                <button class="btn-primary-glow mt-6" @click="exportBackupData">
                  <FileJsonIcon class="icon-sm" />
                  <span>EXPORT BACKUP JSON</span>
                </button>
              </div>
              <div v-if="backupStatus === 'downloaded'" class="confirm-backup-row mt-6">
                <label class="checkbox-container">
                  <input type="checkbox" v-model="backupDownloaded" />
                  <span class="checkmark"></span>
                  <span class="cb-label">I have safely stored the backup file.</span>
                </label>
              </div>
              <button class="btn-secondary w-full mt-6" v-if="backupDownloaded" @click="resetStep = 3">PROCEED TO FINAL STEP</button>
            </div>

            <!-- STEP 3: FINAL CONFIRM -->
            <div v-if="resetStep === 3" class="reset-step animate-slide">
              <div class="form-group">
                <label>TYPE <span class="text-error font-bold">RESET SYSTEM</span> TO WIPE DATA</label>
                <input 
                  type="text" 
                  v-model="resetConfirmation" 
                  placeholder="Case-sensitive" 
                  class="reset-input"
                />
              </div>
              <div class="modal-actions mt-8">
                <button class="btn-secondary" @click="resetStep = 2">BACK</button>
                <button 
                  class="btn-error" 
                  :disabled="resetConfirmation !== 'RESET SYSTEM' || reseting"
                  @click="handleSystemReset"
                >
                  {{ reseting ? 'WIPING DATA...' : 'PERMANENTLY RESET DATA' }}
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
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { supabase } from '../lib/supabase';
import { useAuthStore } from '../stores/auth';
import StatsCard from '../components/ui/StatsCard.vue';
import { 
  Trash2Icon, 
  AlertTriangleIcon, 
  ClockIcon, 
  TruckIcon, 
  ArrowRightIcon,
  DownloadIcon,
  FileJsonIcon
} from 'lucide-vue-next';

const authStore = useAuthStore();
const heroStock = ref(0);
const standardStock = ref(0);
const saltedStock = ref(0);
const logs = ref<any[]>([]);
const currentTime = ref('');
const allSales = ref<any[]>([]);
const inventory = ref<any[]>([]);
const customers = ref<any[]>([]);

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
  // Fetch Stocks
  const { data: stocks } = await supabase.from('inventory').select('*');
  if (stocks) {
    inventory.value = stocks;
    heroStock.value = stocks.find(s => s.id === 'hero_size')?.current_stock ?? 0;
    standardStock.value = stocks.find(s => s.id === 'standard_size')?.current_stock ?? 0;
    saltedStock.value = stocks.find(s => s.id === 'salted_egg')?.current_stock ?? 0;
  }

  // Fetch ALL sales with status info
  const { data: sales } = await supabase
    .from('sales')
    .select('id, total_price, payment_status, fulfillment_status, stock_reserved, created_at, sale_items(egg_type, quantity)')
    .order('created_at', { ascending: false });
  if (sales) allSales.value = sales;

  // Fetch customers for rankings
  const { data: cust } = await supabase.from('customers').select('*');
  if (cust) customers.value = cust;

  // Fetch Latest Logs
  const { data: latestLogs } = await supabase
    .from('stock_logs')
    .select('*')
    .order('created_at', { ascending: false })
    .limit(8);
  
  if (latestLogs) logs.value = latestLogs;
}

// ─── COMPUTED ───────────────────────

// Monthly revenue: only PAID orders from THIS MONTH
const monthlyRevenue = computed(() => {
  const now = new Date();
  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
  return allSales.value
    .filter(s => s.payment_status === 'paid' && new Date(s.created_at) >= startOfMonth)
    .reduce((acc, s) => acc + (s.total_price || 0), 0);
});

const revenueSubtext = computed(() => {
  const now = new Date();
  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
  const paidCount = allSales.value.filter(
    s => s.payment_status === 'paid' && new Date(s.created_at) >= startOfMonth
  ).length;
  return `${paidCount} paid order(s) this month`;
});

const pendingOrdersCount = computed(() => 
  allSales.value.filter(s => s.payment_status === 'pending').length
);

const onDeliveryCount = computed(() => 
  allSales.value.filter(s => (s.fulfillment_status || 'processing') === 'on_delivery').length
);

const lowStockCount = computed(() => 
  inventory.value.filter(i => i.item_type !== 'packaging' && i.current_stock <= 20).length
);

const reservedHero = computed(() => {
  let count = 0;
  allSales.value.filter(s => s.stock_reserved).forEach(s => {
    s.sale_items?.forEach((i: any) => {
      if (i.egg_type === 'hero_size') count += (i.quantity || 0) * 10;
    });
  });
  return count;
});

const reservedStandard = computed(() => {
  let count = 0;
  allSales.value.filter(s => s.stock_reserved).forEach(s => {
    s.sale_items?.forEach((i: any) => {
      if (i.egg_type === 'standard_size') count += (i.quantity || 0) * 10;
    });
  });
  return count;
});

const reservedSalted = computed(() => {
  let count = 0;
  allSales.value.filter(s => s.stock_reserved).forEach(s => {
    s.sale_items?.forEach((i: any) => {
      if (i.egg_type === 'salted_egg') count += (i.quantity || 0) * 10;
    });
  });
  return count;
});

// Last 7 days sales chart
const last7DaysSales = computed(() => {
  const days: { date: string; label: string; count: number; revenue: number; percentage: number; isToday: boolean }[] = [];
  const today = new Date();
  
  for (let i = 6; i >= 0; i--) {
    const d = new Date(today);
    d.setDate(d.getDate() - i);
    const dateStr = d.toISOString().split('T')[0] || '';
    const dayLabel = d.toLocaleDateString('id-ID', { weekday: 'short' }) || '';
    
    const daySales = allSales.value.filter(s => {
      if (!s.created_at) return false;
      const sDate = new Date(s.created_at).toISOString().split('T')[0];
      return sDate === dateStr && s.payment_status !== 'cancelled';
    });
    
    days.push({
      date: dateStr,
      label: dayLabel,
      count: daySales.length,
      revenue: daySales.reduce((a, s) => a + (Number(s.total_price) || 0), 0),
      percentage: 0,
      isToday: i === 0
    });
  }
  
  const maxCount = Math.max(...days.map(d => d.count), 1);
  days.forEach(d => {
    d.percentage = Math.max(5, (d.count / maxCount) * 100);
  });
  
  return days;
});

const totalLast7Days = computed(() => last7DaysSales.value.reduce((a, d) => a + d.count, 0));
const revenueLast7Days = computed(() => last7DaysSales.value.reduce((a, d) => a + d.revenue, 0));

const topCustomers = computed(() => {
  return [...customers.value]
    .sort((a, b) => (b.total_spent || 0) - (a.total_spent || 0))
    .slice(0, 5);
});

function formatTime(dateStr: string) {
  return new Date(dateStr).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' });
}

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
    
    const backupData = {
      exported_at: new Date().toISOString(),
      sales: sales || [],
      customers: customers || [],
      stock_logs: stockLogs || []
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
    
    backupStatus.value = 'downloaded';
  } catch (err: any) {
    alert('Backup failed: ' + err.message);
    backupStatus.value = 'idle';
  }
}

async function handleSystemReset() {
  if (resetConfirmation.value !== 'RESET SYSTEM') return;
  
  reseting.value = true;
  
  try {
    const { error: e1 } = await supabase.from('sale_items').delete().not('id', 'is', null);
    const { error: e2 } = await supabase.from('sales').delete().not('id', 'is', null);
    const { error: e3 } = await supabase.from('stock_logs').delete().not('id', 'is', null);

    if (e1 || e2 || e3) {
      console.error('Deletion Errors:', { e1, e2, e3 });
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
      alert(`Customer/Inventory Reset Issue: ${e4?.message || e5?.message}`);
    } else {
      alert('SYSTEM RESET SUCCESSFUL: Orders, sales, and logs have been cleared. Customer stats and inventory levels are now zero.');
    }

    closeResetModal();
    fetchData(); 
  } catch (err: any) {
    alert('Critical Reset Failure: ' + err.message);
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
.dashboard-content {
  display: flex;
  flex-direction: column;
  gap: 28px;
}

.workspace-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
}

.text-dim { color: var(--color-text-dim); }

.time-widget {
  padding: 12px 20px;
  font-weight: 600;
  display: flex;
  align-items: center;
  gap: 12px;
  font-family: 'JetBrains Mono', monospace;
}

.dot {
  width: 8px;
  height: 8px;
  background: var(--color-success);
  border-radius: 50%;
  box-shadow: 0 0 10px var(--color-success);
}

.pulse { animation: pulse-glow 2s infinite; }

@keyframes pulse-glow {
  0% { transform: scale(1); opacity: 1; }
  50% { transform: scale(1.5); opacity: 0.5; }
  100% { transform: scale(1); opacity: 1; }
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
  gap: 16px;
}

/* ─── ACTION CARDS ──────────────── */
.action-cards {
  display: flex;
  gap: 16px;
  flex-wrap: wrap;
}

.action-card {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 18px 24px;
  min-width: 220px;
  text-decoration: none;
  color: inherit;
  cursor: pointer;
  flex: 1;
}

.action-card:hover {
  border-color: rgba(255, 140, 0, 0.3);
}

.ac-icon {
  width: 44px;
  height: 44px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.ac-icon svg { width: 20px; height: 20px; }

.pending-icon { background: rgba(255, 170, 0, 0.12); color: #FFAA00; }
.delivery-icon { background: rgba(255, 140, 0, 0.12); color: var(--color-primary); }
.critical-icon { background: rgba(255, 62, 62, 0.12); color: var(--color-error); }

.ac-info { display: flex; flex-direction: column; flex: 1; }
.ac-value { font-size: 1.4rem; font-weight: 800; }
.ac-label { font-size: 0.75rem; color: var(--color-text-dim); font-weight: 600; }

.ac-arrow { width: 16px; height: 16px; color: var(--color-text-dim); opacity: 0.5; }

/* ─── CONTENT GRID ──────────────── */
.content-grid {
  display: grid;
  grid-template-columns: 2fr 1fr;
  gap: 24px;
}

.panel-title {
  margin-bottom: 24px;
  font-size: 1rem;
  letter-spacing: 0.05em;
  color: var(--color-text-dim);
  text-transform: uppercase;
}

.main-chart { padding: 32px; }

/* ─── SALES SUMMARY BAR CHART ───── */
.sales-summary-grid {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  height: 200px;
  gap: 12px;
  padding: 0 8px;
}

.day-bar-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  flex: 1;
}

.day-bar-wrapper {
  height: 160px;
  width: 100%;
  max-width: 48px;
  display: flex;
  align-items: flex-end;
  justify-content: center;
}

.day-bar {
  width: 100%;
  border-radius: 8px 8px 4px 4px;
  background: rgba(255, 140, 0, 0.15);
  border: 1px solid rgba(255, 140, 0, 0.2);
  transition: height 0.6s cubic-bezier(0.23, 1, 0.32, 1);
  min-height: 4px;
}

.day-bar.today {
  background: linear-gradient(180deg, rgba(255, 140, 0, 0.4), rgba(255, 140, 0, 0.15));
  border-color: rgba(255, 140, 0, 0.5);
  box-shadow: 0 0 12px rgba(255, 140, 0, 0.15);
}

.day-label {
  font-size: 0.65rem;
  color: var(--color-text-dim);
  font-weight: 600;
  text-transform: uppercase;
}

.day-value {
  font-size: 0.7rem;
  font-weight: 800;
  color: var(--color-primary);
}

.chart-placeholder {
  height: 200px;
  display: flex;
  justify-content: center;
  align-items: center;
}

.chart-footer {
  display: flex;
  justify-content: space-between;
  margin-top: 20px;
  padding-top: 16px;
  border-top: 1px solid var(--glass-border);
}

.cf-stat {
  font-size: 0.75rem;
  color: var(--color-text-dim);
}

.cf-stat strong {
  color: white;
}

/* ─── ACTIVITY FEED ─────────────── */
.activity-feed { padding: 32px; }

.feed-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.feed-item {
  display: flex;
  align-items: flex-start;
  gap: 16px;
  padding-bottom: 16px;
  border-bottom: 1px solid var(--glass-border);
}

.log-indicator {
  width: 4px;
  height: 32px;
  border-radius: 2px;
}

.log-indicator.arrival { background: var(--color-success); }
.log-indicator.sorting_waste { background: var(--color-error); }
.log-indicator.sale { background: var(--color-primary); }

.log-text { font-size: 0.9rem; margin-bottom: 4px; }
.log-meta { font-size: 0.7rem; color: var(--color-text-dim); }

.empty-state {
  text-align: center;
  padding: 40px;
  color: var(--color-text-dim);
  font-style: italic;
}

/* ─── TOP CUSTOMERS ─────────────── */
.top-customers-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.tc-item {
  display: flex;
  align-items: center;
  gap: 16px;
  padding-bottom: 12px;
  border-bottom: 1px solid var(--glass-border);
}

.tc-rank {
  font-size: 0.9rem;
  font-weight: 800;
  color: var(--color-primary);
  opacity: 0.5;
  width: 24px;
}

.tc-info { flex: 1; }
.tc-name { font-size: 0.9rem; font-weight: 700; margin-bottom: 2px; }
.tc-meta { font-size: 0.7rem; color: var(--color-text-dim); }
.tc-spent { font-size: 0.85rem; font-weight: 800; color: var(--color-primary); }

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
</style>
