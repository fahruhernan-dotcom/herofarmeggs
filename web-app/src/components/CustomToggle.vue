<template>
  <button 
    class="custom-toggle" 
    :class="{ 'active': modelValue }"
    @click="$emit('update:modelValue', !modelValue)"
  >
    <div class="toggle-track">
      <div class="toggle-thumb"></div>
    </div>
  </button>
</template>

<script setup lang="ts">
defineProps<{ modelValue: boolean }>();
defineEmits(['update:modelValue']);
</script>

<style scoped>
.custom-toggle {
  background: transparent;
  border: none;
  padding: 0;
  cursor: pointer;
}

.toggle-track {
  width: 44px;
  height: 24px;
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 20px;
  position: relative;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.toggle-thumb {
  width: 18px;
  height: 18px;
  background: white;
  border-radius: 50%;
  position: absolute;
  top: 2px;
  left: 2px;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  box-shadow: 0 2px 5px rgba(0,0,0,0.2);
}

.custom-toggle.active .toggle-track {
  background: var(--color-primary);
  border-color: rgba(255, 255, 255, 0.2);
}

.custom-toggle.active .toggle-thumb {
  left: calc(100% - 20px);
  background: black;
}
</style>
