<template>
  <div class="glass-panel stat-card" :class="{ 'warning': isLow }">
    <div class="card-glow"></div>
    <div class="card-content">
      <div class="header">
        <span class="label">{{ label }}</span>
        <div v-if="trend !== undefined" class="trend" :class="trend >= 0 ? 'up' : 'down'">
          {{ trend >= 0 ? '+' : '' }}{{ trend }}%
        </div>
      </div>
      <div class="value-container">
        <h2 class="value">{{ value }}</h2>
        <span class="unit" v-if="unit">{{ unit }}</span>
      </div>
      <div class="footer">
        <span class="subtext">{{ subtext }}</span>
        <div v-if="isLow" class="alert-icon">⚠️</div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
defineProps<{
  label: string;
  value: string | number;
  unit?: string;
  subtext?: string;
  trend?: number;
  isLow?: boolean;
}>();
</script>

<style scoped>
.stat-card {
  position: relative;
  padding: 24px;
  overflow: hidden;
  min-height: 160px;
}

.card-content {
  position: relative;
  z-index: 2;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  height: 100%;
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.label {
  color: var(--color-text-dim);
  text-transform: uppercase;
  letter-spacing: 0.1em;
  font-size: 0.75rem;
  font-weight: 600;
}

.value-container {
  display: flex;
  align-items: baseline;
  gap: 8px;
}

.value {
  font-size: 2.4rem;
  font-weight: 800;
  color: white;
  line-height: 1;
}

.unit {
  color: var(--color-text-dim);
  font-size: 1rem;
}

.footer {
  margin-top: 16px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.subtext {
  font-size: 0.8rem;
  color: var(--color-text-dim);
}

.trend {
  font-size: 0.75rem;
  padding: 4px 8px;
  border-radius: 20px;
  font-weight: 700;
}

.trend.up { background: rgba(0, 255, 157, 0.1); color: var(--color-success); }
.trend.down { background: rgba(255, 62, 62, 0.1); color: var(--color-error); }

.warning { border-color: rgba(255, 140, 0, 0.4); }
.alert-icon { font-size: 1.2rem; }

.card-glow {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: radial-gradient(circle at top right, rgba(255, 140, 0, 0.05), transparent 70%);
  z-index: 1;
}
</style>
