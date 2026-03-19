<template>
  <div class="stock-card">
    <div class="sc-header">
      <div class="sc-title-row">
        <PackageIcon class="sc-icon" />
        <span class="sc-label">STATUS STOK</span>
        <span class="sc-live-dot"></span>
      </div>
    </div>

    <div class="sc-grades">
      <div v-for="item in grades" :key="item.id" class="sc-grade-row">
        <div class="sc-grade-info">
          <div class="sc-grade-left">
            <span class="sc-grade-chip" :class="getChipClass(item.id)">{{ getGradeLabel(item.id) }}</span>
            <div v-if="(item.current_stock || 0) <= (item.safety_stock || 20)" class="sc-critical-pill-mini">
              KRITIS
            </div>
          </div>
          <span class="sc-grade-count">{{ formatStock(item.current_stock) }}</span>
        </div>
        <div class="sc-progress-track">
          <div
            class="sc-progress-fill"
            :class="getStockStatus(item)"
            :style="{ width: getProgressWidth(item) + '%' }"
          ></div>
        </div>
      </div>
    </div>

    <div class="sc-divider"></div>

    <div class="sc-footer">
      <span class="sc-footer-label">Potensi Revenue</span>
      <span class="sc-footer-value">{{ formatCurrency(potentialRevenue) }}</span>
    </div>
  </div>
</template>

<script setup lang="ts">
// @ts-ignore
import { GRADES, getGradeLabel, normalizeGrade } from '../../constants/grades'
// @ts-ignore
import { formatCurrency, formatStock } from '../../utils/formatters'
import { PackageIcon } from 'lucide-vue-next'

defineProps<{
  grades: any[]
  potentialRevenue: number
}>()
function getChipClass(id: string) {
  const normalized = normalizeGrade(id)
  if (normalized === 'hero') return 'chip-hero'
  if (normalized === 'salted_egg') return 'chip-small'
  return ''
}

function getStockStatus(item: any) {
  const stock = item.current_stock || 0
  const safety = item.safety_stock || 20
  if (stock <= safety) return 'critical'
  if (stock <= safety * 1.5) return 'low'
  return 'healthy'
}

function getProgressWidth(item: any) {
  const stock = item.current_stock || 0
  const safety = item.safety_stock || 20
  return Math.min((stock / (safety * 3)) * 100, 100)
}
</script>

<style scoped>
.stock-card {
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-radius: 16px;
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 16px;
  transition: all 0.3s ease;
}

.stock-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 32px rgba(0,0,0,0.4);
  border-color: rgba(255,255,255,0.14);
}

.sc-header { display: flex; justify-content: space-between; }

.sc-title-row {
  display: flex;
  align-items: center;
  gap: 10px;
}

.sc-label {
  font-family: var(--font-ui);
  font-size: 10px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 2px;
  color: var(--muted);
}

.sc-live-dot {
  width: 6px;
  height: 6px;
  background: #10b981;
  border-radius: 50%;
  box-shadow: 0 0 10px #10b981;
  animation: livePulse 1.5s ease-in-out infinite;
}

.sc-icon {
  display: none;
}

@keyframes livePulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.3; }
}

.sc-grades {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.sc-grade-row {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.sc-grade-info {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.sc-grade-chip {
  padding: 3px 10px;
  border-radius: 6px;
  font-size: 0.7rem;
  font-weight: 700;
  font-family: var(--font-ui);
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.chip-hero {
  background: rgba(245,158,11,0.18);
  color: var(--gold);
}

.chip-medium {
  background: rgba(139,92,246,0.18);
  color: var(--violet);
}

.chip-small {
  background: rgba(56,189,248,0.18);
  color: var(--sky);
}

.sc-grade-count {
  font-family: var(--font-mono);
  font-size: 0.75rem;
  color: var(--muted);
}

.sc-progress-track {
  height: 6px;
  background: rgba(255,255,255,0.04);
  border-radius: 3px;
  overflow: hidden;
}

.sc-progress-fill {
  height: 100%;
  border-radius: 3px;
  transition: width 1s ease;
}

.sc-progress-fill.healthy { background: var(--green); }
.sc-progress-fill.low { background: var(--gold); }
.sc-progress-fill.critical {
  background: var(--red);
  animation: stockPulse 2s ease-in-out infinite;
}

@keyframes stockPulse {
  0%, 100% { box-shadow: 0 0 0 0 rgba(239,68,68,0.4); }
  50% { box-shadow: 0 0 0 8px rgba(239,68,68,0); }
}

.sc-grade-left {
  display: flex;
  align-items: center;
  gap: 8px;
}

.sc-critical-pill-mini {
  padding: 1px 6px;
  background: rgba(239,68,68,0.15);
  color: var(--red);
  font-size: 9px;
  font-weight: 800;
  border-radius: 3px;
  text-transform: uppercase;
  animation: stockPulse 2s ease-in-out infinite;
}

.sc-divider {
  height: 1px;
  background: rgba(255,255,255,0.05);
}

.sc-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.sc-footer-label {
  font-size: 0.7rem;
  color: var(--muted);
}

.sc-footer-value {
  font-family: var(--font-mono);
  font-size: 0.85rem;
  font-weight: 500;
  color: var(--sky);
}
@media (max-width: 768px) {
  .stock-card {
    padding: 16px;
    border-left: 3px solid #ef4444 !important;
    box-shadow: none !important;
  }
  
  .sc-icon {
    display: block;
    width: 14px;
    height: 14px;
    color: #ef4444;
  }

  .sc-grade-count {
    font-size: 0.7rem;
  }
  
  .sc-grade-chip {
    padding: 2px 8px;
    font-size: 0.65rem;
  }
}
</style>
