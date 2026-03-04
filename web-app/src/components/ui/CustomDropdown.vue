<template>
  <div class="custom-dropdown" :class="{ open, 'has-label': label }" v-outside-click="close">
    <div class="dropdown-trigger glass-panel" @click="toggle" :class="{ active: open }">
      <div class="trigger-content">
        <span class="label" v-if="label">{{ label }}</span>
        <span class="selected-value" :class="{ placeholder: !selectedOptionLabel }">
          {{ selectedOptionLabel || placeholder }}
        </span>
      </div>
      <div class="trigger-actions">
        <button v-if="modelValue" class="btn-clear" @click.stop="clear">×</button>
        <ChevronDownIcon class="chevron" :class="{ rotated: open }" />
      </div>
    </div>

    <Transition name="dropdown">
      <div v-if="open" class="dropdown-menu glass-panel">
        <!-- SEARCH BOX -->
        <div v-if="options.length > 5" class="search-box-wrapper">
          <SearchIcon class="search-icon" />
          <input 
            ref="searchInput"
            type="text" 
            v-model="searchQuery" 
            class="search-input" 
            :placeholder="searchPlaceholder || 'Cari...'"
            @click.stop
            @keydown.esc="close"
          />
        </div>

        <div class="options-container custom-scrollbar">
          <div 
            v-for="option in filteredOptions" 
            :key="option.value" 
            class="dropdown-item"
            :class="{ active: modelValue === option.value }"
            @click="select(option)"
          >
            <div class="item-content">
              <span class="item-label">{{ option.label }}</span>
              <span v-if="option.sublabel" class="item-sublabel">{{ option.sublabel }}</span>
            </div>
            <CheckIcon v-if="modelValue === option.value" class="check-icon" />
          </div>

          <div v-if="filteredOptions.length === 0" class="dropdown-empty">
            <span v-if="searchQuery">Tidak ditemukan "{{ searchQuery }}"</span>
            <span v-else>Tidak ada opsi tersedia</span>
          </div>
        </div>
      </div>
    </Transition>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, nextTick } from 'vue';
import { ChevronDownIcon, CheckIcon, SearchIcon } from 'lucide-vue-next';

interface Option {
  label: string;
  value: any;
  sublabel?: string;
}

const props = defineProps<{
  modelValue: any;
  options: Option[];
  placeholder?: string;
  label?: string;
  searchPlaceholder?: string;
}>();

const emit = defineEmits(['update:modelValue', 'change']);

const open = ref(false);
const searchQuery = ref('');
const searchInput = ref<HTMLInputElement | null>(null);

const filteredOptions = computed(() => {
  if (!searchQuery.value) return props.options;
  const q = searchQuery.value.toLowerCase();
  return props.options.filter(opt => 
    opt.label.toLowerCase().includes(q) || 
    opt.sublabel?.toLowerCase().includes(q)
  );
});

const selectedOptionLabel = computed(() => {
  return props.options.find(opt => opt.value === props.modelValue)?.label;
});

function toggle() {
  open.value = !open.value;
  if (open.value) {
    searchQuery.value = '';
    nextTick(() => {
      searchInput.value?.focus();
    });
  }
}

function close() {
  open.value = false;
}

function select(option: Option) {
  emit('update:modelValue', option.value);
  emit('change', option.value);
  close();
}

function clear() {
  emit('update:modelValue', '');
  emit('change', '');
}

// Custom directive for clicking outside
const vOutsideClick = {
  mounted(el: any, binding: any) {
    el.clickOutsideEvent = (event: Event) => {
      if (!(el === event.target || el.contains(event.target))) {
        binding.value();
      }
    };
    document.addEventListener('mousedown', el.clickOutsideEvent);
  },
  unmounted(el: any) {
    document.removeEventListener('mousedown', el.clickOutsideEvent);
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
  padding: 10px 16px;
  cursor: pointer;
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 12px;
  transition: all 0.2s ease;
  min-height: 48px;
}

.dropdown-trigger:hover {
  background: rgba(255, 255, 255, 0.06);
  border-color: rgba(255, 255, 255, 0.15);
}

.dropdown-trigger.active {
  border-color: #f59e0b;
  box-shadow: 0 0 0 4px rgba(245, 158, 11, 0.1);
}

.trigger-content {
  display: flex;
  flex-direction: column;
  flex: 1;
  min-width: 0;
}

.label {
  font-size: 0.6rem;
  font-weight: 800;
  color: #64748b;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  margin-bottom: 2px;
}

.selected-value {
  font-weight: 600;
  color: #fff;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  font-size: 0.9rem;
}

.selected-value.placeholder {
  color: #475569;
  font-weight: 500;
}

.trigger-actions {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-left: 12px;
}

.btn-clear {
  background: none;
  border: none;
  color: #475569;
  font-size: 18px;
  cursor: pointer;
  line-height: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 20px;
  height: 20px;
  border-radius: 50%;
  transition: all 0.2s;
}

.btn-clear:hover {
  color: #fff;
  background: rgba(255,255,255,0.1);
}

.chevron {
  width: 16px;
  height: 16px;
  color: #64748b;
  transition: transform 0.3s cubic-bezier(0.23, 1, 0.32, 1);
}

.chevron.rotated {
  transform: rotate(180deg);
}

.dropdown-menu {
  position: absolute;
  top: calc(100% + 8px);
  left: 0;
  width: 100%;
  z-index: 2100; /* Above slide-overs */
  padding: 6px;
  background: #141418;
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 12px;
  box-shadow: 0 20px 50px rgba(0, 0, 0, 0.6);
  overflow: hidden;
}

/* SEARCH BOX */
.search-box-wrapper {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 12px;
  background: rgba(255, 255, 255, 0.03);
  border-bottom: 1px solid rgba(255, 255, 255, 0.05);
  margin-bottom: 4px;
}

.search-icon {
  width: 14px;
  height: 14px;
  color: #475569;
}

.search-input {
  background: transparent !important;
  border: none !important;
  padding: 4px 0 !important;
  color: #fff !important;
  font-size: 0.85rem !important;
  width: 100% !important;
}

.search-input:focus {
  outline: none !important;
}

.options-container {
  max-height: 240px;
  overflow-y: auto;
}

.dropdown-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 10px 14px;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.2s ease;
}

.dropdown-item:hover {
  background: rgba(45, 212, 191, 0.08);
}

.item-content {
  display: flex;
  flex-direction: column;
  min-width: 0;
}

.item-label {
  font-size: 0.85rem;
  color: #cbd5e1;
  font-weight: 600;
}

.item-sublabel {
  font-size: 0.7rem;
  color: #64748b;
  margin-top: 1px;
}

.dropdown-item.active {
  background: rgba(245, 158, 11, 0.15);
}

.dropdown-item.active .item-label {
  color: #f59e0b;
}

.check-icon {
  width: 14px;
  height: 14px;
  color: #f59e0b;
}

.dropdown-empty {
  padding: 24px 16px;
  text-align: center;
  color: #475569;
  font-size: 0.8rem;
}

/* Scrollbar */
.custom-scrollbar::-webkit-scrollbar {
  width: 5px;
}
.custom-scrollbar::-webkit-scrollbar-track {
  background: transparent;
}
.custom-scrollbar::-webkit-scrollbar-thumb {
  background: rgba(255, 255, 255, 0.1);
  border-radius: 10px;
}
.custom-scrollbar::-webkit-scrollbar-thumb:hover {
  background: rgba(255, 255, 255, 0.2);
}

/* Transitions */
.dropdown-enter-active,
.dropdown-leave-active {
  transition: all 0.3s cubic-bezier(0.23, 1, 0.32, 1);
}

.dropdown-enter-from,
.dropdown-leave-to {
  opacity: 0;
  transform: translateY(-8px) scale(0.98);
}
</style>
