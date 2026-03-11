<template>
  <div class="perf-panel">
    <!-- KPI Stats Row -->
    <div class="kpi-row scroll-x">
      <div class="kpi-stat">
        <span class="kpi-value sky">{{ formatCurrency(revenue) }}</span>
        <span class="kpi-label">Laba Kotor</span>
        <div v-if="growth.status !== 'none'" class="kpi-pill" :class="growth.status">
          {{ growth.status === 'up' ? '↑' : '↓' }} {{ growth.val }}%
        </div>
      </div>
      <div class="kpi-divider"></div>
      <div class="kpi-stat">
        <span class="kpi-value green">{{ formatCurrency(profit) }}</span>
        <span class="kpi-label">Pendapatan (Net Profit)</span>
        <div class="kpi-pill margin">{{ formatPct(marginPct) }}</div>
      </div>
      <div class="kpi-divider desktop-only"></div>
      <div class="kpi-stat">
        <span class="kpi-value white">{{ transaksi }} penjualan</span>
        <span class="kpi-label">Bulan Ini</span>
        <span class="kpi-sub">{{ packsSold }} pack terjual</span>
      </div>
    </div>

    <!-- Bar Chart -->
    <div class="chart-section">
      <div class="chart-header">
        <span class="chart-title">Penjualan 7 Hari Terakhir</span>
      </div>
      <div class="chart-wrapper">
        <Bar v-if="hasChartData" :data="chartData" :options="chartOptions" />
        <div v-else class="chart-empty">
          <span>Belum ada data penjualan</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { Bar } from 'vue-chartjs'
import {
  Chart as ChartJS, CategoryScale, LinearScale,
  BarElement, Tooltip, Filler
} from 'chart.js'
// @ts-ignore
import { formatCurrency, formatPct, formatCompactCurrency } from '../../utils/formatters'

ChartJS.register(CategoryScale, LinearScale, BarElement, Tooltip, Filler)

const props = defineProps<{
  revenue: number
  profit: number
  marginPct: number
  transaksi: number
  packsSold: number
  growth: { val: any; status: string }
  salesChart: {
    labels: string[]
    heroData: number[]
    mediumData: number[]
    saltedData: number[]
  }
}>()

const hasChartData = computed(() => {
  return props.salesChart.heroData.some(v => v > 0) ||
    props.salesChart.mediumData.some(v => v > 0) ||
    props.salesChart.saltedData.some(v => v > 0)
})

const chartData = computed(() => ({
  labels: props.salesChart.labels,
  datasets: [
    {
      label: 'Hero',
      data: props.salesChart.heroData,
      backgroundColor: 'rgba(245, 158, 11, 0.85)',
      borderRadius: 4,
      borderSkipped: false
    },
    {
      label: 'Medium',
      data: props.salesChart.mediumData,
      backgroundColor: 'rgba(139, 92, 246, 0.85)',
      borderRadius: 4,
      borderSkipped: false
    },
    {
      label: 'Small',
      data: props.salesChart.saltedData,
      backgroundColor: 'rgba(56, 189, 248, 0.85)',
      borderRadius: 4,
      borderSkipped: false
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
      stacked: true,
      grid: { display: false },
      ticks: { color: 'rgba(255,255,255,0.35)', font: { size: 10 } }
    },
    y: {
      stacked: true,
      grid: { color: 'rgba(255,255,255,0.04)' },
      ticks: {
        color: 'rgba(255,255,255,0.3)',
        font: { size: 10 },
        callback: (v: any) => formatCompactCurrency(v)
      },
      border: { display: false }
    }
  }
}))
</script>

<style scoped>
.perf-panel {
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-radius: 16px;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  transition: all 0.3s ease;
}

.perf-panel:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 32px rgba(0,0,0,0.4);
  border-color: rgba(255,255,255,0.14);
}

.kpi-row {
  display: flex;
  padding: 24px;
  gap: 0;
  border-bottom: 1px solid rgba(255,255,255,0.06);
}

.kpi-stat {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 6px;
  padding: 0 16px;
}

.kpi-stat:first-child { padding-left: 0; }
.kpi-stat:last-child { padding-right: 0; }

.kpi-divider {
  width: 1px;
  background: rgba(255,255,255,0.06);
}

.kpi-value {
  font-family: var(--font-mono);
  font-size: 1.3rem;
  font-weight: 500;
  line-height: 1.2;
}
.kpi-value.sky { color: var(--sky); }
.kpi-value.green { color: var(--green); }
.kpi-value.white { color: #f0f0f0; }

.kpi-label {
  font-family: var(--font-ui);
  font-size: 0.7rem;
  font-weight: 500;
  text-transform: uppercase;
  letter-spacing: 1px;
  color: var(--muted);
}

.kpi-pill {
  display: inline-flex;
  align-items: center;
  padding: 2px 8px;
  border-radius: 4px;
  font-size: 0.65rem;
  font-weight: 700;
  width: fit-content;
}

.kpi-pill.up { background: rgba(16,185,129,0.15); color: var(--green); }
.kpi-pill.down { background: rgba(239,68,68,0.15); color: var(--red); }
.kpi-pill.new { background: rgba(56,189,248,0.15); color: var(--sky); }
.kpi-pill.margin { background: rgba(16,185,129,0.10); color: var(--green); }

.kpi-sub {
  font-size: 0.7rem;
  color: var(--muted);
}

.chart-section {
  padding: 20px 24px 24px;
  flex: 1;
  display: flex;
  flex-direction: column;
}

.chart-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.chart-title {
  font-family: var(--font-ui);
  font-size: 0.8rem;
  font-weight: 600;
  color: var(--muted);
}

.chart-wrapper {
  flex: 1;
  min-height: 160px;
  position: relative;
}

.chart-empty {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 160px;
  color: #475569;
  font-size: 0.85rem;
}
@media (max-width: 768px) {
  .kpi-row {
    padding: 16px;
  }
  
  .kpi-stat {
    min-width: 140px;
    padding: 0 12px;
  }
  
  .kpi-stat:first-child { padding-left: 0; }
  
  .kpi-value {
    font-size: 1.1rem;
  }

  .chart-section {
    padding: 16px;
  }

  .chart-wrapper {
    min-height: 140px;
  }
}
</style>
