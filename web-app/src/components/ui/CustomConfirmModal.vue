<template>
  <Teleport to="body">
    <div v-if="modelValue" class="confirm-overlay" @click.self="$emit('update:modelValue', false)">
      <div class="confirm-card glass-panel animate-pop">
        <div class="icon-header" :class="type">
          <AlertTriangleIcon v-if="type === 'danger' || type === 'warning'" />
          <InfoIcon v-else />
        </div>
        
        <h2 class="hero-font">{{ title }}</h2>
        <p class="text-dim">{{ message }}</p>

        <div class="confirm-actions">
          <button class="btn-secondary" @click="$emit('update:modelValue', false)">
            {{ cancelLabel || 'Batal' }}
          </button>
          <button 
            :class="['btn-confirm', type]" 
            @click="handleConfirm"
          >
            {{ confirmLabel || 'Konfirmasi' }}
          </button>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
import { AlertTriangleIcon, InfoIcon } from 'lucide-vue-next';

const props = defineProps<{
  modelValue: boolean;
  title: string;
  message: string;
  confirmLabel?: string;
  cancelLabel?: string;
  type?: 'danger' | 'warning' | 'info';
}>();

const emit = defineEmits(['update:modelValue', 'confirm']);

function handleConfirm() {
  emit('confirm');
  emit('update:modelValue', false);
}
</script>

<style scoped>
.confirm-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.6);
  backdrop-filter: blur(8px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 9999;
}

.confirm-card {
  width: 90%;
  max-width: 400px;
  padding: 2.5rem;
  text-align: center;
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.icon-header {
  width: 64px;
  height: 64px;
  border-radius: 50%;
  margin: 0 auto 1.5rem;
  display: flex;
  align-items: center;
  justify-content: center;
}

.icon-header svg {
  width: 32px;
  height: 32px;
}

.icon-header.danger { background: rgba(239, 68, 68, 0.2); color: #ef4444; }
.icon-header.warning { background: rgba(245, 158, 11, 0.2); color: #f59e0b; }
.icon-header.info { background: rgba(59, 130, 246, 0.2); color: #3b82f6; }

.confirm-actions {
  display: flex;
  gap: 1rem;
  margin-top: 2rem;
}

.confirm-actions button {
  flex: 1;
}

.btn-confirm.danger { background: #ef4444; color: white; border: none; padding: 0.75rem; border-radius: 8px; font-weight: 600; }
.btn-confirm.warning { background: #f59e0b; color: white; border: none; padding: 0.75rem; border-radius: 8px; font-weight: 600; }
.btn-confirm.info { background: #3b82f6; color: white; border: none; padding: 0.75rem; border-radius: 8px; font-weight: 600; }

.btn-confirm:hover { filter: brightness(1.1); }
</style>
