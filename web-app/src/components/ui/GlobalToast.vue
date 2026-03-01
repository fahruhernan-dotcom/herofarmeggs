<template>
  <div class="toast-container">
    <TransitionGroup name="toast-list">
      <div 
        v-for="toast in toasts" 
        :key="toast.id" 
        class="toast glass-panel"
        :class="`toast-${toast.type}`"
      >
        <div class="toast-icon">
          <AlertTriangleIcon v-if="toast.type === 'error' || toast.type === 'warning'" class="icon-sm" />
          <InfoIcon v-else class="icon-sm" />
        </div>
        <div class="toast-content">
          <h4 class="toast-title">{{ toast.title }}</h4>
          <p class="toast-msg">{{ toast.message }}</p>
        </div>
        <button class="toast-close" @click="removeToast(toast.id)">×</button>
      </div>
    </TransitionGroup>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { AlertTriangleIcon, InfoIcon } from 'lucide-vue-next';

interface Toast {
  id: number;
  type: 'info' | 'warning' | 'error' | 'success';
  title: string;
  message: string;
}

const toasts = ref<Toast[]>([]);
let nextId = 0;

function addToast(toast: Omit<Toast, 'id'>) {
  const id = nextId++;
  toasts.value.push({ ...toast, id });
  
  // Auto remove after 5s
  setTimeout(() => removeToast(id), 5000);
}

function removeToast(id: number) {
  const index = toasts.value.findIndex(t => t.id === id);
  if (index > -1) {
    toasts.value.splice(index, 1);
  }
}

// Expose the method globally if needed, or we can use an event bus/store.
// For simplicity in a small app, we can export it or just use an EventBus.
// We'll export it here and let the parent handle the ref.
defineExpose({
  addToast
});
</script>

<style scoped>
.toast-container {
  position: fixed;
  bottom: 24px;
  right: 24px;
  display: flex;
  flex-direction: column;
  gap: 12px;
  z-index: 9999;
  pointer-events: none; /* Let clicks pass through empty space */
}

.toast {
  pointer-events: auto;
  display: flex;
  align-items: flex-start;
  gap: 12px;
  padding: 16px 20px;
  min-width: 300px;
  max-width: 400px;
  background: rgba(15, 15, 15, 0.95);
  border-left: 4px solid var(--color-primary);
  box-shadow: 0 10px 40px rgba(0,0,0,0.5);
}

.toast-warning { border-left-color: #FFAA00; }
.toast-error { border-left-color: var(--color-error); }
.toast-success { border-left-color: var(--color-success); }
.toast-info { border-left-color: #00D1FF; }

.toast-icon {
  display: flex;
  align-items: center;
  justify-content: center;
  margin-top: 2px;
}

.toast-warning .icon-sm { color: #FFAA00; }
.toast-error .icon-sm { color: var(--color-error); }
.toast-success .icon-sm { color: var(--color-success); }
.toast-info .icon-sm { color: #00D1FF; }

.toast-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.toast-title {
  font-size: 0.85rem;
  font-weight: 800;
  margin: 0;
  color: white;
}

.toast-msg {
  font-size: 0.75rem;
  color: var(--color-text-dim);
  margin: 0;
  line-height: 1.4;
}

.toast-close {
  background: transparent;
  border: none;
  color: var(--color-text-dim);
  font-size: 1.2rem;
  cursor: pointer;
  padding: 0;
  line-height: 1;
  opacity: 0.5;
  transition: opacity 0.2s;
}

.toast-close:hover {
  opacity: 1;
  color: white;
}

/* Transitions */
.toast-list-enter-active,
.toast-list-leave-active {
  transition: all 0.4s cubic-bezier(0.23, 1, 0.32, 1);
}

.toast-list-enter-from {
  opacity: 0;
  transform: translateX(50px) scale(0.9);
}

.toast-list-leave-to {
  opacity: 0;
  transform: translateX(50px) scale(0.9);
}
</style>
