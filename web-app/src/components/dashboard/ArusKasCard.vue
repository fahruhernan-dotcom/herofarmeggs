<template>
  <div class="arus-card">
    <div class="ac-header">
      <div>
        <span class="ac-label">ARUS KAS</span>
        <span class="ac-sub">30 Hari Terakhir</span>
      </div>
      <div class="ac-net-pill" :class="net >= 0 ? 'plus' : 'minus'">
        Net: {{ formatCompactCurrency(net) }}
      </div>
    </div>

    <div class="ac-chart-wrapper">
      <Line v-if="hasData" :data="chartData" :options="chartOptions" />
      <div v-else class="ac-empty">Belum ada data arus kas bulan ini</div>
    </div>

    <div class="ac-footer">
      <div class="ac-foot-stat">
        <span class="ac-dot sky"></span>
        <span class="ac-foot-label">Masuk:</span>
        <span class="ac-foot-val sky">{{ formatCompactCurrency(totalIncome) }}</span>
      </div>
      <div class="ac-foot-stat">
        <span class="ac-dot red"></span>
        <span class="ac-foot-label">Keluar:</span>
        <span class="ac-foot-val red">{{ formatCompactCurrency(totalExpense) }}</span>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { Line } from 'vue-chartjs'
import {
  Chart as ChartJS, CategoryScale, LinearScale,
  PointElement, LineElement, Filler, Tooltip
} from 'chart.js'
import { formatCompactCurrency } from '../../utils/formatters'

ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, Filler, Tooltip)

const props = defineProps<{
  dates: string[]
  income: number[]
  expense: number[]
  totalIncome: number
  totalExpense: number
  net: number
}>()

const hasData = computed(() => {
  return props.income.some(v => v > 0) || props.expense.some(v => v > 0)
})

const chartData = computed(() => ({
  labels: props.dates,
  datasets: [
    {
      label: 'Pemasukan',
      data: props.income,
      borderColor: '#38bdf8',
      backgroundColor: 'rgba(56, 189, 248, 0.08)',
      fill: true,
      tension: 0.4,
      pointRadius: 0,
      pointHoverRadius: 4,
      borderWidth: 2
    },
    {
      label: 'Pengeluaran',
      data: props.expense,
      borderColor: '#ef4444',
      backgroundColor: 'rgba(239, 68, 68, 0.08)',
      fill: true,
      tension: 0.4,
      pointRadius: 0,
      pointHoverRadius: 4,
      borderWidth: 2
    }
  ]
}))

const chartOptions = computed(() => ({
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: { display: false },
    tooltip: {
      callbacks: {
        label: (ctx: any) => `${ctx.dataset.label}: ${formatCompactCurrency(ctx.raw)}`
      }
    }
  },
  scales: {
    x: {
      display: false
    },
    y: {
      beginAtZero: true,
      grid: { color: 'rgba(255,255,255,0.03)' },
      ticks: {
        color: 'rgba(255,255,255,0.25)',
        font: { size: 9 },
        callback: (v: any) => formatCompactCurrency(v)
      },
      border: { display: false }
    }
  }
}))
</script>

<style scoped>
.arus-card {
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-radius: 16px;
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 12px;
  transition: all 0.3s ease;
}

.arus-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 32px rgba(0,0,0,0.4);
  border-color: rgba(255,255,255,0.14);
}

.ac-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
}

.ac-label {
  font-family: var(--font-ui);
  font-size: 10px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 2px;
  color: var(--muted);
  display: block;
}

.ac-sub {
  font-size: 0.7rem;
  color: #475569;
}

.ac-net-pill {
  font-family: var(--font-mono);
  font-size: 0.7rem;
  font-weight: 500;
  padding: 3px 10px;
  border-radius: 6px;
}

.ac-net-pill.plus { background: rgba(16,185,129,0.12); color: var(--green); }
.ac-net-pill.minus { background: rgba(239,68,68,0.12); color: var(--red); }

.ac-chart-wrapper {
  flex: 1;
  min-height: 120px;
  position: relative;
}

.ac-empty {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 120px;
  color: #475569;
  font-size: 0.8rem;
}

.ac-footer {
  display: flex;
  gap: 16px;
  padding-top: 8px;
  border-top: 1px solid rgba(255,255,255,0.05);
}

.ac-foot-stat {
  display: flex;
  align-items: center;
  gap: 6px;
}

.ac-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
}

.ac-dot.sky { background: var(--sky); }
.ac-dot.red { background: var(--red); }

.ac-foot-label {
  font-size: 0.7rem;
  color: var(--muted);
}

.ac-foot-val {
  font-family: var(--font-mono);
  font-size: 0.75rem;
  font-weight: 500;
}

.ac-foot-val.sky { color: var(--sky); }
.ac-foot-val.red { color: var(--red); }
</style>
