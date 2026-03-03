<template>
  <div class="empty-state animate-fade-in">
    <div class="icon-wrapper">
      <component :is="icon" class="main-icon" />
    </div>
    <h3 class="title">{{ title }}</h3>
    <p class="message">{{ message }}</p>
    <button v-if="actionLabel" class="btn-primary-glow mt-4" @click="$emit('action')">
      <span>{{ actionLabel }}</span>
    </button>
  </div>
</template>

<script setup lang="ts">
defineProps<{
  icon: any;
  title: string;
  message: string;
  actionLabel?: string;
}>();

defineEmits(['action']);
</script>

<style scoped>
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 4rem 2rem;
  text-align: center;
}

.icon-wrapper {
  margin-bottom: 1.5rem;
  opacity: 0.3;
}

.main-icon {
  width: 64px;
  height: 64px;
}

.title {
  font-family: 'Outfit', sans-serif;
  font-weight: 600;
  font-size: 1.25rem;
  margin-bottom: 0.5rem;
  color: var(--text-bright);
}

.message {
  color: var(--text-dim);
  max-width: 300px;
}
</style>
