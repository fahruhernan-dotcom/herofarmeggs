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
        :is-low="heroStock < 50"
      />
      <StatsCard 
        label="Standard Size Availability" 
        :value="standardStock" 
        unit="Butir"
        subtext="Community Retail Grade"
        :trend="-5"
        :is-low="standardStock < 30"
      />
      <StatsCard 
        label="Estimated Revenue" 
        value="Rp 0" 
        unit=""
        subtext="Active Batch Calculations"
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
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue';
import { supabase } from '../lib/supabase';
import StatsCard from '../components/ui/StatsCard.vue';

const heroStock = ref(0);
const standardStock = ref(0);
const logs = ref<any[]>([]);
const currentTime = ref('');

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
</style>
