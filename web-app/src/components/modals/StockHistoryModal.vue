<template>
  <Teleport to="body">
    <div v-if="show" class="modal-overlay" @click.self="$emit('close')">
      <div class="modal-card glass-panel animate-pop wide">
        <div class="modal-header">
          <h2 class="hero-font">Full Price History</h2>
          <p class="text-dim">Tracking every change for {{ productName }}.</p>
          <button class="btn-close-circle" @click="$emit('close')">
            <XIcon class="icon-sm" />
          </button>
        </div>

        <div class="history-content">
          <div v-if="loading" class="loading-state">
            <div class="loader"></div>
            <span>Fetching historical records...</span>
          </div>
          
          <div v-else-if="history.length === 0" class="empty-state">
            <ClipboardIcon class="icon-lg opacity-20" />
            <p>No historical price changes found for this product.</p>
          </div>

          <div v-else class="history-table-wrapper">
            <table class="history-table">
              <thead>
                <tr>
                  <th>Tanggal</th>
                  <th>Tipe</th>
                  <th>Harga Lama</th>
                  <th>Harga Baru</th>
                  <th>Oleh</th>
                  <th>Alasan</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="h in history" :key="h.id" class="history-row">
                  <td class="date">{{ formatDate(h.changed_at) }}</td>
                  <td>
                    <span class="type-badge" :class="h.price_type">{{ h.price_type.toUpperCase() }}</span>
                  </td>
                  <td class="price">Rp {{ h.old_value?.toLocaleString('id-ID') }}</td>
                  <td class="price accent">
                    <div class="p-wrap">
                      <span>Rp {{ h.new_value?.toLocaleString('id-ID') }}</span>
                      <TrendingUpIcon v-if="h.new_value > h.old_value" class="icon-xs text-green" />
                      <TrendingDownIcon v-else-if="h.new_value < h.old_value" class="icon-xs text-red" />
                    </div>
                  </td>
                  <td class="author">{{ h.changed_by }}</td>
                  <td class="reason">{{ h.reason || '-' }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <div class="modal-actions">
          <button class="btn-secondary" @click="$emit('close')">Close History</button>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue';
import { supabase } from '../../lib/supabase';
import { XIcon, ClipboardIcon, TrendingUpIcon, TrendingDownIcon } from 'lucide-vue-next';

const props = defineProps<{
  show: boolean;
  productId: string;
  productName: string;
}>();

const emit = defineEmits(['close']);

const history = ref<any[]>([]);
const loading = ref(false);

async function fetchHistory() {
  if (!props.productId) return;
  loading.value = true;
  try {
    const { data, error } = await supabase
      .from('price_history')
      .select('*')
      .eq('inventory_id', props.productId)
      .order('changed_at', { ascending: false });
    
    if (error) throw error;
    history.value = data || [];
  } catch (err) {
    console.error('Failed to fetch history:', err);
  } finally {
    loading.value = false;
  }
}

watch(() => props.show, (newVal) => {
  if (newVal) fetchHistory();
});

function formatDate(date: string) {
  return new Date(date).toLocaleString('id-ID', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  });
}
</script>

<style scoped>
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0, 0, 0, 0.85);
  backdrop-filter: blur(12px);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 2000;
  padding: 40px;
}

.modal-card.wide {
  max-width: 900px;
  width: 100%;
  max-height: 85vh;
  display: flex;
  flex-direction: column;
}

.modal-header {
  position: relative;
  margin-bottom: 24px;
}

.btn-close-circle {
  position: absolute;
  top: -10px;
  right: -10px;
  width: 32px;
  height: 32px;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
}

.history-content {
  flex: 1;
  overflow-y: auto;
  margin-bottom: 24px;
  min-height: 300px;
}

.history-table-wrapper {
  overflow-x: auto;
}

.history-table {
  width: 100%;
  border-collapse: collapse;
}

.history-table th {
  text-align: left;
  padding: 14px;
  background: rgba(255, 255, 255, 0.02);
  color: var(--color-text-dim);
  font-size: 0.75rem;
  text-transform: uppercase;
}

.history-row td {
  padding: 14px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.03);
  font-size: 0.85rem;
}

.type-badge {
  padding: 2px 6px;
  border-radius: 4px;
  font-size: 0.65rem;
  font-weight: 800;
}

.type-badge.selling { background: rgba(0, 255, 157, 0.1); color: var(--color-success); }
.type-badge.hpp { background: rgba(255, 140, 0, 0.1); color: var(--color-primary); }
.type-badge.cost_per_egg { background: rgba(59, 130, 246, 0.1); color: #3b82f6; }

.price.accent {
  font-weight: 800;
  color: white;
}

.p-wrap {
  display: flex;
  align-items: center;
  gap: 8px;
}

.reason {
  color: var(--color-text-dim);
  font-style: italic;
  max-width: 250px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.loading-state, .empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 16px;
  padding: 60px;
  color: var(--color-text-dim);
}

.loader {
  width: 40px;
  height: 40px;
  border: 3px solid rgba(255, 140, 0, 0.1);
  border-top-color: var(--color-primary);
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.modal-actions {
  display: flex;
  justify-content: flex-end;
}

.btn-secondary {
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
  color: white;
  padding: 10px 24px;
  border-radius: 8px;
  cursor: pointer;
}
</style>
