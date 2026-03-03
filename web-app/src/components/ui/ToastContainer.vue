<template>
  <div class="toast-container">
    <TransitionGroup name="toast">
      <div 
        v-for="toast in toasts" 
        :key="toast.id" 
        :class="['toast-card', toast.type]"
        @click="removeToast(toast.id)"
      >
        <div class="toast-content">
          <CheckCircleIcon v-if="toast.type === 'success'" class="toast-icon" />
          <AlertCircleIcon v-if="toast.type === 'error'" class="toast-icon" />
          <AlertTriangleIcon v-if="toast.type === 'warning'" class="toast-icon" />
          <span>{{ toast.message }}</span>
        </div>
      </div>
    </TransitionGroup>
  </div>
</template>

<script setup lang="ts">
import { CheckCircleIcon, AlertCircleIcon, AlertTriangleIcon } from 'lucide-vue-next';
import { useToast } from '../../composables/useToast';

const { toasts, removeToast } = useToast();
</script>

<style scoped>
.toast-container {
  position: fixed;
  bottom: 2rem;
  right: 2rem;
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  z-index: 10000;
  pointer-events: none;
}

.toast-card {
  pointer-events: auto;
  min-width: 300px;
  background: rgba(15, 23, 42, 0.8);
  backdrop-filter: blur(12px);
  border: 1px solid rgba(255, 255, 255, 0.1);
  padding: 1rem 1.25rem;
  border-radius: 12px;
  box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.3);
  cursor: pointer;
}

.toast-content {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  color: white;
  font-weight: 500;
}

.toast-icon { width: 20px; height: 20px; }

.success { border-left: 4px solid #10b981; }
.success .toast-icon { color: #10b981; }

.error { border-left: 4px solid #ef4444; }
.error .toast-icon { color: #ef4444; }

.warning { border-left: 4px solid #f59e0b; }
.warning .toast-icon { color: #f59e0b; }

.toast-enter-active, .toast-leave-active {
  transition: all 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275);
}

.toast-enter-from {
  opacity: 0;
  transform: translateX(100%) scale(0.9);
}

.toast-leave-to {
  opacity: 0;
  transform: translateX(100%) translateY(-20px);
}
</style>
