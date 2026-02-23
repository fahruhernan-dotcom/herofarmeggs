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
        subtext="Premium Grade A+"
        :trend="12"
        :status="getDashboardStatus(heroStock)"
      />
      <StatsCard 
        label="Standard Size Availability" 
        :value="standardStock" 
        unit="Butir"
        subtext="Community Retail Grade"
        :trend="-5"
        :status="getDashboardStatus(standardStock)"
      />
      <StatsCard 
        label="Telur Asin Availability" 
        :value="saltedStock" 
        unit="Butir"
        subtext="Premium Salted Grade"
        :status="getDashboardStatus(saltedStock)"
      />
      <StatsCard 
        v-if="authStore.profile?.role === 'admin'"
        label="Monthly Revenue" 
        :value="'Rp ' + totalRevenue.toLocaleString()" 
        unit=""
        subtext="Total processed income"
      />
    </section>

    <!-- Activity & Charts Placeholder -->
    <div class="content-grid">
      <div class="glass-panel main-chart">
        <h4 class="panel-title">Sales Trend (Coming Soon)</h4>
        <div class="chart-placeholder">
          <div class="grid-lines"></div>
          <p class="text-dim">Analytics engine initializing...</p>
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
    </div>

    <!-- DANGER ZONE -->
    <section v-if="authStore.profile?.role === 'admin'" class="danger-zone glass-panel mt-8">
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
            <h2 class="hero-font text-error">CRITICAL ACTION</h2>
            <p class="text-dim">This will permanently delete all Sales, Orders, and Stock Logs.</p>
          </div>

          <div class="warning-box">
             <AlertTriangleIcon class="icon-lg text-error" />
             <p>All transaction history, digital invoices, and audit trails will be wiped. Inventory levels will remain as they are.</p>
          </div>

          <div class="form-group mt-6">
            <label>Type <span class="text-error font-bold">RESET</span> to confirm</label>
            <input 
              type="text" 
              v-model="resetConfirmation" 
              placeholder="Case-sensitive" 
              class="reset-input"
            />
          </div>

          <div class="modal-actions mt-8">
            <button class="btn-secondary" @click="closeResetModal">CANCEL</button>
            <button 
              class="btn-error" 
              :disabled="resetConfirmation !== 'RESET' || reseting"
              @click="handleSystemReset"
            >
              {{ reseting ? 'WIPING DATA...' : 'PERMANENTLY RESET DATA' }}
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue';
import { supabase } from '../lib/supabase';
import { useAuthStore } from '../stores/auth';
import StatsCard from '../components/ui/StatsCard.vue';
import { Trash2Icon, AlertTriangleIcon } from 'lucide-vue-next';

const authStore = useAuthStore();
const heroStock = ref(0);
const standardStock = ref(0);
const saltedStock = ref(0);
const totalRevenue = ref(0);
const logs = ref<any[]>([]);
const currentTime = ref('');

// Reset Logic
const showResetModal = ref(false);
const resetConfirmation = ref('');
const reseting = ref(false);

function updateClock() {
  const now = new Date();
  currentTime.value = now.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' });
}

let clockInterval: any;

async function fetchData() {
  // Fetch Stocks
  const { data: stocks } = await supabase.from('inventory').select('*');
  if (stocks) {
    heroStock.value = stocks.find(s => s.id === 'hero_size')?.current_stock ?? 0;
    standardStock.value = stocks.find(s => s.id === 'standard_size')?.current_stock ?? 0;
    saltedStock.value = stocks.find(s => s.id === 'salted_egg')?.current_stock ?? 0;
  }

  // Fetch Total Revenue
  const { data: sales } = await supabase.from('sales').select('total_price');
  if (sales) {
    totalRevenue.value = sales.reduce((acc, curr) => acc + (curr.total_price || 0), 0);
  }

  // Fetch Latest Logs
  const { data: latestLogs } = await supabase
    .from('stock_logs')
    .select('*')
    .order('created_at', { ascending: false })
    .limit(5);
  
  if (latestLogs) logs.value = latestLogs;
}

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
  resetConfirmation.value = '';
}

async function handleSystemReset() {
  if (resetConfirmation.value !== 'RESET') return;
  
  reseting.value = true;
  
  try {
    // 1. Delete Transactional Data (Order matters for Foreign Keys)
    // Table 'sales' exists, but 'orders' does not (it's a view name/concept in UI)
    const { error: e1 } = await supabase.from('sale_items').delete().not('id', 'is', null);
    const { error: e2 } = await supabase.from('sales').delete().not('id', 'is', null);
    const { error: e3 } = await supabase.from('stock_logs').delete().not('id', 'is', null);

    if (e1 || e2 || e3) {
      console.error('Deletion Errors:', { e1, e2, e3 });
    }

    // 2. Reset Customer Statistics (total_orders and total_spent)
    const { error: e4 } = await supabase.from('customers').update({ 
      total_orders: 0, 
      total_spent: 0
    }).not('id', 'is', null);

    // 3. Reset Inventory to Zero State
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

  // REAL-TIME UPDATES
  const inventorySubscription = supabase
    .channel('dashboard-updates')
    .on('postgres_changes', { event: '*', schema: 'public', table: 'inventory' }, () => {
      fetchData();
    })
    .subscribe();

  onUnmounted(() => {
    clearInterval(clockInterval);
    inventorySubscription.unsubscribe();
  });
});
</script>

<style scoped>
.dashboard-content {
  display: flex;
  flex-direction: column;
  gap: 32px;
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
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 20px;
}

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

.main-chart { padding: 32px; min-height: 400px; }

.chart-placeholder {
  height: 100%;
  display: flex;
  justify-content: center;
  align-items: center;
  position: relative;
}

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

/* Danger Zone Styles */
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

/* Modal Overflow Fix */
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

.animate-pop { animation: popIn 0.3s cubic-bezier(0.23, 1, 0.32, 1); }
@keyframes popIn {
  from { opacity: 0; transform: scale(0.9) translateY(20px); }
  to { opacity: 1; transform: scale(1) translateY(0); }
}
</style>
