<template>
  <div class="aging-card" :class="{ 'overdue-glow': hasOverdue }">
    <div class="ag-header">
      <div class="ag-title-row">
        <span class="ag-label">PIUTANG</span>
        <span v-if="overdueCount > 0" class="ag-badge">{{ overdueCount }}</span>
      </div>
      <router-link to="/financial" class="ag-link">Semua Piutang →</router-link>
    </div>

    <div class="ag-buckets">
      <div v-for="bucket in buckets" :key="bucket.label" class="ag-row" :class="bucket.color">
        <span class="ag-row-label">{{ bucket.label }}</span>
        <div class="ag-bar-track">
          <div class="ag-bar-fill" :style="{ width: getWidth(bucket.total) + '%' }"></div>
        </div>
        <span class="ag-row-val">{{ formatCurrency(bucket.total) }}</span>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { formatCurrency } from '../../utils/formatters'

const props = defineProps<{
  paid: { count: number; total: number }
  week1: { count: number; total: number }
  week2: { count: number; total: number }
  overdue: { count: number; total: number }
}>()

const hasOverdue = computed(() => props.overdue.total > 0)
const overdueCount = computed(() => props.week1.count + props.week2.count + props.overdue.count)

const maxTotal = computed(() => {
  return Math.max(props.paid.total, props.week1.total, props.week2.total, props.overdue.total, 1)
})

function getWidth(total: number) {
  return Math.min((total / maxTotal.value) * 100, 100)
}

const buckets = computed(() => [
  { label: 'Lunas', total: props.paid.total, color: 'green' },
  { label: '0-7 hari', total: props.week1.total, color: 'yellow' },
  { label: '8-14 hari', total: props.week2.total, color: 'amber' },
  { label: '15+ hari', total: props.overdue.total, color: 'red' }
])
</script>

<style scoped>
.aging-card {
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-radius: 16px;
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 16px;
  transition: all 0.3s ease;
}

.aging-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 32px rgba(0,0,0,0.4);
  border-color: rgba(255,255,255,0.14);
}

.aging-card.overdue-glow {
  border-color: rgba(239,68,68,0.25);
  box-shadow: 0 0 20px rgba(239,68,68,0.06);
}

.ag-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.ag-title-row {
  display: flex;
  align-items: center;
  gap: 8px;
}

.ag-label {
  font-family: var(--font-ui);
  font-size: 10px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 2px;
  color: var(--muted);
}

.ag-badge {
  background: rgba(239,68,68,0.15);
  color: var(--red);
  font-size: 0.65rem;
  font-weight: 800;
  padding: 1px 6px;
  border-radius: 4px;
}

.ag-link {
  font-size: 0.7rem;
  color: var(--gold);
  text-decoration: none;
  font-weight: 600;
  transition: opacity 0.2s;
}

.ag-link:hover { opacity: 0.7; }

.ag-buckets {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.ag-row {
  display: flex;
  align-items: center;
  gap: 12px;
}

.ag-row-label {
  font-size: 0.7rem;
  font-weight: 600;
  color: #94a3b8;
  width: 60px;
  flex-shrink: 0;
}

.ag-bar-track {
  flex: 1;
  height: 8px;
  background: rgba(255,255,255,0.04);
  border-radius: 4px;
  overflow: hidden;
}

.ag-bar-fill {
  height: 100%;
  border-radius: 4px;
  transition: width 1s ease;
}

.ag-row.green .ag-bar-fill { background: var(--green); }
.ag-row.yellow .ag-bar-fill { background: #eab308; }
.ag-row.amber .ag-bar-fill { background: var(--gold); }
.ag-row.red .ag-bar-fill { background: var(--red); }

.ag-row.red .ag-bar-fill {
  animation: agingPulse 2s ease-in-out infinite;
}

@keyframes agingPulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.6; }
}

.ag-row-val {
  font-family: var(--font-mono);
  font-size: 0.7rem;
  font-weight: 500;
  color: var(--muted);
  width: 90px;
  text-align: right;
  flex-shrink: 0;
}
</style>
