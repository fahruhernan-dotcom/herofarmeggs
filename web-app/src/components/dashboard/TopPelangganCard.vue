<template>
  <div class="top-card">
    <div class="tc-header">
      <div class="tc-title-row">
        <UsersIcon class="tc-icon" />
        <span class="tc-label">TOP PELANGGAN</span>
      </div>
      <router-link to="/customers" class="tc-link">Lihat Semua →</router-link>
    </div>

    <div v-if="customers.length > 0" class="tc-list">
      <div v-for="(cust, idx) in customers" :key="idx" class="tc-row">
        <span class="tc-rank">{{ medals[idx] || (idx + 1) + '.' }}</span>
        <span class="tc-name">{{ cust.name }}</span>
        <div class="tc-bar-track">
          <div class="tc-bar-fill" :style="{ width: getWidth(cust.total) + '%' }"></div>
        </div>
        <span class="tc-amount">{{ formatCurrency(cust.total) }}</span>
      </div>
    </div>

    <div v-else class="tc-empty">
      <span class="tc-empty-icon">👥</span>
      <span class="tc-empty-text">Belum ada pelanggan bulan ini</span>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { formatCurrency } from '../../utils/formatters'
import { UsersIcon } from 'lucide-vue-next'

const props = defineProps<{
  customers: Array<{ name: string; total: number }>
}>()

const medals = ['🥇', '🥈', '🥉']

const maxTotal = computed(() => {
  if (props.customers.length === 0) return 1
  return Math.max(...props.customers.map(c => c.total), 1)
})

function getWidth(total: number) {
  return Math.min((total / maxTotal.value) * 100, 100)
}
</script>

<style scoped>
.top-card {
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-radius: 16px;
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 16px;
  transition: all 0.3s ease;
}

.top-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 32px rgba(0,0,0,0.4);
  border-color: rgba(255,255,255,0.14);
}

.tc-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.tc-label {
  font-family: var(--font-ui);
  font-size: 10px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 2px;
  color: var(--muted);
}

.tc-link {
  font-size: 0.7rem;
  color: var(--gold);
  text-decoration: none;
  font-weight: 600;
  transition: opacity 0.2s;
}

.tc-link:hover { opacity: 0.7; }

.tc-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.tc-row {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 6px 8px;
  border-radius: 8px;
  transition: background 0.2s;
}

.tc-row:hover {
  background: rgba(255,255,255,0.03);
}

.tc-rank {
  font-size: 14px;
  width: 24px;
  text-align: center;
  flex-shrink: 0;
}

.tc-name {
  font-size: 0.8rem;
  font-weight: 500;
  color: #e2e8f0;
  width: 80px;
  flex-shrink: 0;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.tc-bar-track {
  flex: 1;
  height: 8px;
  background: rgba(255,255,255,0.04);
  border-radius: 4px;
  overflow: hidden;
}

.tc-bar-fill {
  height: 100%;
  border-radius: 4px;
  background: linear-gradient(90deg, #f59e0b, #fbbf24);
  transition: width 1s ease;
}

.tc-amount {
  font-family: var(--font-mono);
  font-size: 0.7rem;
  font-weight: 500;
  color: var(--muted);
  width: 80px;
  text-align: right;
  flex-shrink: 0;
}

.tc-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 32px 0;
}

.tc-empty-icon {
  font-size: 2rem;
  opacity: 0.3;
}

.tc-empty-text {
  font-size: 0.8rem;
  color: #475569;
}

.tc-title-row {
  display: flex;
  align-items: center;
  gap: 6px;
}

.tc-icon {
  display: none;
}

@media (max-width: 768px) {
  .tc-icon {
    display: block;
    width: 14px;
    height: 14px;
    color: rgba(250,204,21,0.5);
  }
  .tc-row {
    padding: 5px 0 !important;
    gap: 8px !important;
  }
}
</style>
