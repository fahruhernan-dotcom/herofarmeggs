<template>
  <div class="utang-card">
    <div class="uc-header">
      <div class="uc-title-row">
        <span class="uc-label">UTANG SUPPLIER</span>
        <ShieldAlertIcon class="uc-icon" />
      </div>
    </div>
    <div class="uc-value">{{ formatCurrency(amount) }}</div>
    <span class="uc-sub">{{ count }} tagihan aktif</span>
    <router-link to="/financial" class="uc-action">
      Bayar Utang <ArrowRightIcon class="uc-arrow" />
    </router-link>
  </div>
</template>

<script setup lang="ts">
import { ShieldAlertIcon, ArrowRightIcon } from 'lucide-vue-next'
// @ts-ignore
import { formatCurrency } from '../../utils/formatters'

defineProps<{
  amount: number
  count: number
}>()
</script>

<style scoped>
.utang-card {
  background: linear-gradient(135deg, #1f0f0f, #1a0d0d);
  border: 1px solid rgba(239, 68, 68, 0.25);
  box-shadow: 0 0 30px rgba(239, 68, 68, 0.06);
  border-radius: 16px;
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 12px;
  transition: all 0.3s ease;
}

.utang-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 32px rgba(0,0,0,0.4);
  border-color: rgba(239, 68, 68, 0.35);
}

.uc-header { display: flex; justify-content: space-between; }

.uc-title-row {
  display: flex;
  align-items: center;
  gap: 8px;
}

.uc-label {
  font-family: var(--font-ui);
  font-size: 10px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 2px;
  color: var(--muted);
}

.uc-icon {
  width: 16px;
  height: 16px;
  color: var(--red);
}

.uc-value {
  font-family: var(--font-mono);
  font-size: 1.8rem;
  font-weight: 500;
  color: var(--red);
  line-height: 1;
}

.uc-sub {
  font-size: 0.75rem;
  color: var(--muted);
}

.uc-action {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  margin-top: auto;
  padding: 10px;
  border: 1px solid rgba(239,68,68,0.30);
  border-radius: 10px;
  background: transparent;
  color: var(--red);
  font-family: var(--font-ui);
  font-size: 0.8rem;
  font-weight: 600;
  text-decoration: none;
  cursor: pointer;
  transition: all 0.2s ease;
}

.uc-action:hover {
  background: rgba(239,68,68,0.10);
}

.uc-arrow {
  width: 14px;
  height: 14px;
}
</style>
