<template>
  <Transition name="toast-fade">
    <div v-if="toast" class="critical-toast-wrapper glass-panel">
      <div class="toast-content">
        <div class="toast-left">
          <div class="pulse-dot"></div>
          <div class="toast-info">
            <h4 class="toast-title">🔴 Stok Kritis: {{ productName }}</h4>
            <p class="toast-msg">{{ toast.message }} — Segera restock!</p>
          </div>
        </div>
        
        <div class="toast-actions">
          <button class="btn-view" @click="viewStock">
            <ArrowRightIcon :size="14" />
            <span>Lihat Stok</span>
          </button>
          <button class="btn-close" @click="dismiss">
            <XIcon :size="18" />
          </button>
        </div>
      </div>
      
      <!-- Progress Bar -->
      <div class="progress-container">
        <div class="progress-bar" :style="{ width: progress + '%' }"></div>
      </div>
    </div>
  </Transition>
</template>

<script setup lang="ts">
import { ref, computed, watch, onUnmounted } from 'vue';
import { useRouter } from 'vue-router';
import { ArrowRightIcon, XIcon } from 'lucide-vue-next';
import { useNotificationStore } from '../stores/notificationStore';

const router = useRouter();
const notifStore = useNotificationStore();

const toast = computed(() => notifStore.latestCriticalToast);
const progress = ref(100);
let timer: any = null;
let progressInterval: any = null;

const productName = computed(() => {
  if (!toast.value?.message) return '';
  // Extract name before colon
  return toast.value.message.split(':')[0] || '';
});

watch(toast, (newVal) => {
  if (newVal) {
    startTimer();
  } else {
    clearTimers();
  }
});

function startTimer() {
  clearTimers();
  progress.value = 100;
  
  const duration = 10000; // 10 seconds
  const interval = 50; // Update every 50ms
  const steps = duration / interval;
  const decrement = 100 / steps;
  
  progressInterval = setInterval(() => {
    progress.value -= decrement;
    if (progress.value <= 0) {
      dismiss();
    }
  }, interval);
  
  timer = setTimeout(() => {
    dismiss();
  }, duration);
}

function clearTimers() {
  if (timer) clearTimeout(timer);
  if (progressInterval) clearInterval(progressInterval);
}

function dismiss() {
  notifStore.dismissToast();
}

function viewStock() {
  router.push('/stock');
  dismiss();
}

onUnmounted(() => {
  clearTimers();
});
</script>

<style scoped>
.critical-toast-wrapper {
  position: fixed;
  top: 80px; /* Below header */
  right: 24px;
  width: 400px;
  z-index: 9999;
  padding: 0;
  overflow: hidden;
  border: 1px solid rgba(239, 68, 68, 0.3) !important;
  box-shadow: 0 10px 40px rgba(239, 68, 68, 0.2) !important;
}

.toast-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 20px;
  gap: 16px;
}

.toast-left {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  flex: 1;
}

.pulse-dot {
  width: 10px;
  height: 10px;
  background: #ef4444;
  border-radius: 50%;
  margin-top: 6px;
  box-shadow: 0 0 10px #ef4444;
  animation: pulse 1.5s infinite;
}

@keyframes pulse {
  0% { transform: scale(1); opacity: 1; }
  50% { transform: scale(1.5); opacity: 0.5; }
  100% { transform: scale(1); opacity: 1; }
}

.toast-info {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.toast-title {
  margin: 0;
  font-size: 14px;
  font-weight: 800;
  color: #fff;
}

.toast-msg {
  margin: 0;
  font-size: 13px;
  color: var(--color-text-dim);
}

.toast-actions {
  display: flex;
  align-items: center;
  gap: 12px;
}

.btn-view {
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
  color: #fff;
  padding: 6px 12px;
  border-radius: 8px;
  font-size: 12px;
  font-weight: 700;
  display: flex;
  align-items: center;
  gap: 6px;
  cursor: pointer;
  transition: all 0.3s;
  white-space: nowrap;
}

.btn-view:hover {
  background: var(--color-primary);
  border-color: var(--color-primary);
}

.btn-close {
  background: none;
  border: none;
  color: var(--color-text-dim);
  cursor: pointer;
  padding: 4px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: color 0.2s;
}

.btn-close:hover {
  color: #fff;
}

/* Progress Bar */
.progress-container {
  height: 3px;
  background: rgba(255, 255, 255, 0.05);
  width: 100%;
}

.progress-bar {
  height: 100%;
  background: #ef4444;
  transition: width 0.05s linear;
}

/* Transitions */
.toast-fade-enter-active {
  animation: slide-in 0.5s cubic-bezier(0.23, 1, 0.32, 1);
}

.toast-fade-leave-active {
  animation: slide-in 0.3s cubic-bezier(0.23, 1, 0.32, 1) reverse;
}

@keyframes slide-in {
  from { transform: translateX(50px) scale(0.9); opacity: 0; }
  to { transform: translateX(0) scale(1); opacity: 1; }
}
</style>
