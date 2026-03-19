<template>
  <div class="net-card" :class="netPosition >= 0 ? 'positive' : 'negative'">
    <div class="nc-header-row">
      <span class="nc-label">NET POSITION</span>
      <TrendingUpIcon v-if="netPosition >= 0" class="nc-trend-icon" />
    </div>
    <div class="nc-value" :class="netPosition >= 0 ? 'text-green' : 'text-red'">
      {{ formatCurrency(animatedNet) }}
    </div>
    <div class="nc-sub-stats">
      <div class="nc-stat">
        <span class="nc-stat-icon">📥</span>
        <span class="nc-stat-text">Modal: {{ formatCompactCurrency(totalCost) }}</span>
      </div>
      <div class="nc-stat">
        <span class="nc-stat-icon">📤</span>
        <span class="nc-stat-text">Revenue: {{ formatCompactCurrency(revenue) }}</span>
      </div>
    </div>
    <div class="nc-progress">
      <div class="nc-progress-track">
        <div class="nc-progress-fill" :style="{ width: pct + '%' }"></div>
      </div>
      <span class="nc-progress-label">{{ formatPct(pct) }} modal kembali</span>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useAnimatedNumber } from '../../composables/useAnimatedNumber'
// @ts-ignore
import { formatCurrency, formatCompactCurrency, formatPct } from '../../utils/formatters'
import { TrendingUpIcon } from 'lucide-vue-next'

const props = defineProps<{
  netPosition: number
  totalCost: number
  revenue: number
  pct: number
}>()

const animatedNet = useAnimatedNumber(() => props.netPosition)
</script>

<style scoped>
.net-card {
  padding: 24px;
  border-radius: 16px;
  border: 1px solid var(--border);
  display: flex;
  flex-direction: column;
  gap: 16px;
  transition: all 0.3s ease;
}

.net-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 32px rgba(0,0,0,0.4);
}

.net-card.positive {
  background: linear-gradient(135deg, #0f1f16, #0d1a12);
  border-color: rgba(16,185,129,0.25);
  box-shadow: 0 0 30px rgba(16,185,129,0.06);
}

.net-card.negative {
  background: linear-gradient(135deg, #1f0f0f, #1a0d0d);
  border-color: rgba(239,68,68,0.25);
  box-shadow: 0 0 30px rgba(239,68,68,0.06);
}

.nc-label {
  font-family: var(--font-ui);
  font-size: 10px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 2px;
  color: var(--muted);
}

.nc-value {
  font-family: var(--font-mono);
  font-size: 2.2rem;
  font-weight: 500;
  line-height: 1;
}

.text-green { color: var(--green); }
.text-red { color: var(--red); }

.nc-sub-stats {
  display: flex;
  gap: 16px;
}

.nc-stat {
  display: flex;
  align-items: center;
  gap: 6px;
}

.nc-stat-icon { font-size: 12px; }

.nc-stat-text {
  font-size: 0.75rem;
  color: var(--muted);
}

.nc-progress {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.nc-progress-track {
  height: 6px;
  background: rgba(255,255,255,0.06);
  border-radius: 3px;
  overflow: hidden;
}

.nc-progress-fill {
  height: 100%;
  border-radius: 3px;
  background: linear-gradient(90deg, #10b981, #34d399);
  transition: width 1s ease;
}

.negative .nc-progress-fill {
  background: linear-gradient(90deg, #ef4444, #f87171);
}

.nc-progress-label {
  font-size: 0.7rem;
  color: var(--muted);
}

.nc-header-row {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
}

.nc-trend-icon {
  display: none;
}

@media (max-width: 768px) {
  .net-card {
    position: relative;
    background: linear-gradient(135deg, rgba(16,185,129,0.18) 0%, rgba(15,23,42,0.95) 60%) !important;
    border: 1px solid rgba(16,185,129,0.3) !important;
    box-shadow: inset 0 0 30px rgba(16,185,129,0.08) !important;
  }
  
  .net-card.negative {
    background: linear-gradient(135deg, rgba(239,68,68,0.18) 0%, rgba(15,23,42,0.95) 60%) !important;
    border: 1px solid rgba(239,68,68,0.3) !important;
    box-shadow: inset 0 0 30px rgba(239,68,68,0.08) !important;
  }
  
  .nc-trend-icon {
    display: block;
    position: absolute;
    top: 10px;
    right: 12px;
    color: rgba(16,185,129,0.4);
    width: 18px;
    height: 18px;
  }

  .negative .nc-trend-icon {
    color: rgba(239,68,68,0.4);
    transform: rotate(180deg);
  }

  .net-card .nc-value {
    font-size: 1.6rem !important;
    letter-spacing: 1px !important;
  }
  
  .net-card.positive .nc-value { color: #10b981 !important; }
  .net-card.negative .nc-value { color: #ef4444 !important; }

  .net-card .nc-label {
    font-size: 9px !important;
    letter-spacing: 2px !important;
  }
  
  .net-card.positive .nc-label { color: rgba(16,185,129,0.6) !important; }
  .net-card.negative .nc-label { color: rgba(239,68,68,0.6) !important; }
}
</style>
