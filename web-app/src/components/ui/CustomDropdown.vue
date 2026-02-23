<template>
  <div class="custom-dropdown" :class="{ open }" v-outside-click="close">
    <div class="dropdown-trigger glass-panel" @click="toggle">
      <div class="trigger-content">
        <span class="label" v-if="label">{{ label }}</span>
        <span class="selected-value">{{ selectedOptionLabel || placeholder }}</span>
      </div>
      <ChevronDownIcon class="chevron" :class="{ rotated: open }" />
    </div>

    <Transition name="dropdown">
      <div v-if="open" class="dropdown-menu glass-panel">
        <div 
          v-for="option in options" 
          :key="option.value" 
          class="dropdown-item"
          :class="{ active: modelValue === option.value }"
          @click="select(option)"
        >
          {{ option.label }}
          <CheckIcon v-if="modelValue === option.value" class="check-icon" />
        </div>
        <div v-if="options.length === 0" class="dropdown-empty">
          No options available
        </div>
      </div>
    </Transition>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue';
import { ChevronDownIcon, CheckIcon } from 'lucide-vue-next';

interface Option {
  label: string;
  value: any;
}

const props = defineProps<{
  modelValue: any;
  options: Option[];
  placeholder?: string;
  label?: string;
}>();

const emit = defineEmits(['update:modelValue', 'change']);

const open = ref(false);

const selectedOptionLabel = computed(() => {
  return props.options.find(opt => opt.value === props.modelValue)?.label;
});

function toggle() {
  open.value = !open.value;
}

function close() {
  open.value = false;
}

function select(option: Option) {
  emit('update:modelValue', option.value);
  emit('change', option.value);
  close();
}

// Custom directive for clicking outside
const vOutsideClick = {
  mounted(el: any, binding: any) {
    el.clickOutsideEvent = (event: Event) => {
      if (!(el === event.target || el.contains(event.target))) {
        binding.value();
      }
    };
    document.addEventListener('click', el.clickOutsideEvent);
  },
  unmounted(el: any) {
    document.removeEventListener('click', el.clickOutsideEvent);
  },
};
</script>

<style scoped>
.custom-dropdown {
  position: relative;
  width: 100%;
  user-select: none;
}

.dropdown-trigger {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 20px;
  cursor: pointer;
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid var(--glass-border);
  border-radius: var(--radius-md);
  transition: var(--transition-smooth);
}

.dropdown-trigger:hover {
  background: rgba(255, 255, 255, 0.06);
  border-color: rgba(255, 255, 255, 0.2);
}

.trigger-content {
  display: flex;
  flex-direction: column;
}

.label {
  font-size: 0.65rem;
  font-weight: 800;
  color: var(--color-text-dim);
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin-bottom: 2px;
}

.selected-value {
  font-weight: 600;
  color: var(--color-text);
}

.chevron {
  width: 18px;
  height: 18px;
  color: var(--color-text-dim);
  transition: transform 0.3s ease;
}

.chevron.rotated {
  transform: rotate(180deg);
}

.dropdown-menu {
  position: absolute;
  top: calc(100% + 8px);
  left: 0;
  width: 100%;
  z-index: 100;
  padding: 8px;
  background: rgba(10, 10, 10, 0.95);
  backdrop-filter: blur(20px);
  border: 1px solid var(--glass-border);
  border-radius: var(--radius-md);
  box-shadow: 0 20px 40px rgba(0, 0, 0, 0.4);
  max-height: 250px;
  overflow-y: auto;
}

.dropdown-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 10px 16px;
  border-radius: var(--radius-sm);
  cursor: pointer;
  transition: var(--transition-smooth);
  font-size: 0.9rem;
  color: var(--color-text-dim);
}

.dropdown-item:hover {
  background: rgba(255, 255, 255, 0.05);
  color: white;
}

.dropdown-item.active {
  background: var(--color-primary-glow);
  color: var(--color-primary);
  font-weight: 700;
}

.check-icon {
  width: 16px;
  height: 16px;
}

.dropdown-empty {
  padding: 16px;
  text-align: center;
  color: var(--color-text-dim);
  font-style: italic;
}

/* Transitions */
.dropdown-enter-active,
.dropdown-leave-active {
  transition: all 0.3s cubic-bezier(0.23, 1, 0.32, 1);
}

.dropdown-enter-from,
.dropdown-leave-to {
  opacity: 0;
  transform: translateY(-10px);
}
</style>
