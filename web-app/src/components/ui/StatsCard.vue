<template>
  <div class="glass-panel stat-card" :class="status">
    <div class="card-glow"></div>
    <div class="card-content">
      <div class="header-main">
        <div class="value-container">
          <h2 class="value">{{ value }}</h2>
          <span class="unit" v-if="unit">{{ unit }}</span>
        </div>
        
        <!-- NEW GROWTH INDICATOR -->
        <div v-if="trend !== undefined || trendStatus" class="growth-indicator">
          <div v-if="trendStatus === 'new'" class="growth-pill new">
            — Baru
          </div>
          <div v-else-if="trend !== undefined" class="growth-pill" :class="trend >= 0 ? 'up' : 'down'">
            {{ trend >= 0 ? '↑' : '↓' }} {{ Math.abs(trend) }}%
          </div>
        </div>

        <span class="label">{{ label }}</span>
      </div>

      <div class="footer">
        <span class="subtext">{{ subtext }}</span>
        <div v-if="status === 'critical'" class="alert-icon">⚠️</div>
        <div v-if="status === 'low'" class="alert-icon">⚡</div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
withDefaults(defineProps<{
  label: string;
  value: string | number;
  unit?: string;
  subtext?: string;
  trend?: number;
  trendStatus?: 'up' | 'down' | 'new' | 'none';
  status?: 'healthy' | 'low' | 'critical';
}>(), {
  status: 'healthy',
  trendStatus: 'none'
});
</script>

<style scoped>
.stat-card {
  position: relative;
  padding: 24px;
  overflow: hidden;
  min-height: 160px;
  transition: var(--transition-smooth);
}

.card-content {
  position: relative;
  z-index: 2;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  height: 100%;
}

.header-main {
  display: flex;
  flex-direction: column;
}

.label {
  color: var(--color-text-dim);
  text-transform: uppercase;
  letter-spacing: 0.1em;
  font-size: 0.7rem;
  font-weight: 700;
  margin-top: 4px;
}

.value-container {
  display: flex;
  align-items: baseline;
  gap: 8px;
}

.value {
  font-size: 2.2rem;
  font-weight: 900;
  color: white;
  line-height: 1;
}

.unit {
  color: var(--color-text-dim);
  font-size: 0.9rem;
  font-weight: 700;
}

.growth-indicator {
  margin-top: 6px;
  margin-bottom: 2px;
}

.growth-pill {
  display: inline-flex;
  align-items: center;
  padding: 2px 8px;
  border-radius: 4px;
  font-size: 11px;
  font-weight: 800;
}

.growth-pill.up { background: rgba(16, 185, 129, 0.15); color: #10b981; }
.growth-pill.down { background: rgba(239, 68, 68, 0.15); color: #ef4444; }
.growth-pill.new { background: rgba(255, 255, 255, 0.05); color: var(--color-text-dim); }

/* Status Styles */
.stat-card.critical { border-color: rgba(255, 66, 66, 0.5); box-shadow: inset 0 0 20px rgba(255, 66, 66, 0.05); }
.stat-card.low { border-color: rgba(255, 215, 0, 0.4); box-shadow: inset 0 0 20px rgba(255, 215, 0, 0.05); }
.stat-card.healthy { border-color: var(--glass-border); }

.alert-icon { font-size: 1.2rem; }

.card-glow {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: radial-gradient(circle at top right, rgba(255, 255, 255, 0.03), transparent 70%);
  z-index: 1;
}

.critical .card-glow { background: radial-gradient(circle at top right, rgba(255, 66, 66, 0.15), transparent 70%); }
.low .card-glow { background: radial-gradient(circle at top right, rgba(255, 215, 0, 0.1), transparent 70%); }
</style>
