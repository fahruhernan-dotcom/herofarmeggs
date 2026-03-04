<template>
  <div v-if="show" class="alert-bar" :class="{ 'animate-in': show }">
    <div class="ab-left">
      <AlertTriangleIcon class="ab-icon" />
      <span class="ab-label">Modal belum kembali</span>
    </div>
    <div class="ab-center">
      <span class="ab-amount">{{ formatCurrency(Math.abs(shortfall)) }}</span>
    </div>
    <div class="ab-right">
      <span class="ab-detail">Total Modal: {{ formatCompactCurrency(totalCost) }}</span>
      <span class="ab-sep">|</span>
      <span class="ab-detail">Revenue: {{ formatCompactCurrency(revenue) }}</span>
    </div>
  </div>
</template>

<script setup lang="ts">
import { AlertTriangleIcon } from 'lucide-vue-next'
import { formatCurrency, formatCompactCurrency } from '../../utils/formatters'

defineProps<{
  show: boolean
  shortfall: number
  totalCost: number
  revenue: number
}>()
</script>

<style scoped>
.alert-bar {
  grid-column: 1 / -1;
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: linear-gradient(135deg, rgba(245,158,11,0.12), rgba(245,158,11,0.06));
  border: 1px solid rgba(245,158,11,0.30);
  border-radius: 10px;
  padding: 12px 20px;
  animation: borderPulse 3s ease-in-out infinite;
}

.ab-left {
  display: flex;
  align-items: center;
  gap: 10px;
}

.ab-icon {
  width: 20px;
  height: 20px;
  color: var(--gold);
}

.ab-label {
  font-family: var(--font-ui);
  font-weight: 700;
  font-size: 0.85rem;
  color: var(--gold);
}

.ab-center {
  flex: 0 0 auto;
}

.ab-amount {
  font-family: var(--font-mono);
  font-size: 1.4rem;
  font-weight: 500;
  color: var(--gold);
}

.ab-right {
  display: flex;
  align-items: center;
  gap: 8px;
}

.ab-detail {
  font-size: 0.75rem;
  color: var(--muted);
}

.ab-sep {
  color: rgba(255,255,255,0.1);
}

@keyframes borderPulse {
  0%, 100% { border-color: rgba(245,158,11,0.15); }
  50% { border-color: rgba(245,158,11,0.45); }
}

.animate-in {
  animation: slideDown 0.4s ease-out, borderPulse 3s ease-in-out infinite;
}

@keyframes slideDown {
  from { opacity: 0; transform: translateY(-12px); }
  to { opacity: 1; transform: translateY(0); }
}
</style>
