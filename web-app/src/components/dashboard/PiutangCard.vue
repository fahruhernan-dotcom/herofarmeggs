<template>
  <div class="piutang-card">
    <div class="pc-title-row">
      <span class="pc-label">PIUTANG AKTIF</span>
      <ClockIcon class="pc-icon" />
    </div>
    <div class="pc-value">{{ formatCurrency(amount) }}</div>
    <span class="pc-sub">{{ count }} invoice belum terbayar</span>
    <router-link to="/financial" class="pc-action">
      Tagih Sekarang <ArrowRightIcon class="pc-arrow" />
    </router-link>
  </div>
</template>

<script setup lang="ts">
import { ClockIcon, ArrowRightIcon } from 'lucide-vue-next'
// @ts-ignore
import { formatCurrency } from '../../utils/formatters'

defineProps<{
  amount: number
  count: number
}>()
</script>

<style scoped>
.piutang-card {
  background: var(--bg-card);
  border: 1px solid rgba(245,158,11,0.20);
  border-radius: 16px;
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 12px;
  transition: all 0.3s ease;
}

.piutang-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 32px rgba(0,0,0,0.4);
  border-color: rgba(245,158,11,0.35);
}

.pc-title-row {
  display: flex;
  align-items: center;
  gap: 8px;
}

.pc-label {
  font-family: var(--font-ui);
  font-size: 10px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 2px;
  color: var(--muted);
}

.pc-icon {
  width: 16px;
  height: 16px;
  color: var(--gold);
}

.pc-value {
  font-family: var(--font-mono);
  font-size: 1.8rem;
  font-weight: 500;
  color: var(--gold);
  line-height: 1;
}

.pc-sub {
  font-size: 0.75rem;
  color: var(--muted);
}

.pc-action {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  margin-top: auto;
  padding: 10px;
  border: 1px solid rgba(245,158,11,0.30);
  border-radius: 10px;
  background: transparent;
  color: var(--gold);
  font-family: var(--font-ui);
  font-size: 0.8rem;
  font-weight: 600;
  text-decoration: none;
  cursor: pointer;
  transition: all 0.2s ease;
}

.pc-action:hover {
  background: rgba(245,158,11,0.10);
}

.pc-arrow {
  width: 14px;
  height: 14px;
}
</style>
