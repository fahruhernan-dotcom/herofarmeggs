<template>
  <Teleport to="body">
    <div v-if="show" class="so-overlay" @click.self="$emit('close')">
      <div class="slide-over">
        <div class="so-header">
          <div>
            <h2 class="so-title">Restock Supplies & Packaging</h2>
            <p class="so-sub">Tambah persediaan kemasan, stiker, atau kartu</p>
          </div>
          <button class="btn-x" @click="$emit('close')">×</button>
        </div>

        <div class="so-body">
          <!-- SUPPLY TYPE -->
          <div class="fg">
            <label class="fg-label">JENIS SUPPLY</label>
            <div class="type-cards">
              <div 
                v-for="t in supplyTypes" :key="t.id"
                class="type-card" 
                :class="{ active: form.supply_type === t.id }"
                @click="form.supply_type = t.id"
              >
                <span class="tc-icon">{{ t.icon }}</span>
                <span class="tc-label">{{ t.label }}</span>
              </div>
            </div>
          </div>

          <!-- SUPPLIER -->
          <div class="fg">
            <label class="fg-label">SUPPLIER</label>
              <CustomDropdown
                v-model="form.supplier_id"
                :options="supplierOptions"
                placeholder="Pilih supplier packaging..."
                search-placeholder="Cari supplier..."
              />
          </div>

          <!-- QTY + PRICE -->
          <div class="fg-row">
            <div class="fg">
              <label class="fg-label">JUMLAH</label>
              <div class="input-wrap">
                <input type="number" v-model.number="form.qty" min="1" placeholder="0" class="fg-input" />
                <span class="suffix">UNIT</span>
              </div>
            </div>
            <div class="fg">
              <label class="fg-label">HARGA PER UNIT</label>
              <div class="input-wrap">
                <span class="prefix">Rp</span>
                <input type="number" v-model.number="form.price" min="0" placeholder="0" class="fg-input" />
              </div>
            </div>
          </div>

          <!-- DAMAGED + SHIPPING -->
          <div class="fg-row">
            <div class="fg">
              <label class="fg-label">RUSAK SAAT TERIMA</label>
              <input type="number" v-model.number="form.damaged" min="0" placeholder="0" class="fg-input" />
            </div>
            <div class="fg">
              <label class="fg-label">ONGKIR</label>
              <div class="input-wrap">
                <span class="prefix">Rp</span>
                <input type="number" v-model.number="form.shipping" min="0" placeholder="0" class="fg-input" />
              </div>
            </div>
          </div>

          <!-- LIVE CALC -->
          <div v-if="form.qty > 0 && form.price > 0" class="calc-card">
            <span class="calc-label">📊 KALKULASI OTOMATIS</span>
            <div class="calc-row">
              <span>Total Pembelian</span>
              <span class="calc-val">{{ formatCurrency(form.qty * form.price) }}</span>
            </div>
            <div class="calc-row" v-if="form.shipping > 0">
              <span>Ongkir</span>
              <span class="calc-val dim">+ {{ formatCurrency(form.shipping) }}</span>
            </div>
            <div class="calc-divider"></div>
            <div class="calc-row big">
              <span>Harga Efektif / Unit</span>
              <span class="calc-val" :class="effectiveCost > form.price ? 'red' : 'green'">{{ formatCurrency(effectiveCost) }}</span>
            </div>
            <div class="calc-row small">
              <span>Harga Nominal</span>
              <span class="calc-val dim">{{ formatCurrency(form.price) }}</span>
            </div>
          </div>
        </div>

        <div class="so-footer">
          <button class="btn-ghost" @click="$emit('close')">Batal</button>
          <button 
            class="btn-gold" 
            :disabled="!canSubmit || submitting"
            @click="handleSubmit"
          >
            {{ submitting ? 'MEMPROSES...' : 'SIMPAN RESTOCK' }}
          </button>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
import { ref, reactive, computed, watch } from 'vue';
import { supabase } from '../../lib/supabase';
// @ts-ignore
import { formatCurrency } from '../../utils/formatters';
import { useToast } from '../../composables/useToast';
import CustomDropdown from '../ui/CustomDropdown.vue';

const props = defineProps<{ show: boolean }>();
const emit = defineEmits<{
  (e: 'close'): void;
  (e: 'restockDone'): void;
}>();

const { showToast } = useToast();
const submitting = ref(false);
const filteredSuppliers = ref<any[]>([]);

const supplyTypes = [
  { id: 'packaging_standard', icon: '📦', label: 'Box Kemasan' },
  { id: 'sticker_label', icon: '🏷️', label: 'Stiker Label' },
  { id: 'mini_card', icon: '💌', label: 'Kartu Thank You' },
];

const form = reactive({
  supply_type: 'packaging_standard',
  supplier_id: '',
  qty: 0,
  price: 0,
  damaged: 0,
  shipping: 0,
});

const supplierOptions = computed(() => {
  return filteredSuppliers.value.map(s => ({
    label: s.name,
    value: s.id,
    sublabel: s.category || 'Supplier Packaging'
  }));
});

const effectiveCost = computed(() => {
  const usable = Math.max(1, (form.qty || 0) - (form.damaged || 0));
  return ((form.qty * form.price) + (form.shipping || 0)) / usable;
});

const canSubmit = computed(() => form.supply_type && form.qty > 0 && form.price > 0);

async function fetchSuppliers() {
  const { data } = await supabase
    .from('suppliers')
    .select('id, name, category')
    .eq('is_deleted', false)
    .order('name');
  
  if (data) {
    filteredSuppliers.value = data.filter(s => {
      const cat = (s.category || '').toLowerCase();
      return cat.includes('kemasan') || cat.includes('packaging') || cat.includes('stiker') || cat.includes('card') || cat.includes('lainnya');
    });
  }
}

watch(() => props.show, (val) => {
  if (val) {
    fetchSuppliers();
    form.supply_type = 'packaging_standard';
    form.supplier_id = '';
    form.qty = 0;
    form.price = 0;
    form.damaged = 0;
    form.shipping = 0;
  }
});

async function handleSubmit() {
  if (!canSubmit.value || submitting.value) return;
  submitting.value = true;
  try {
    const { data, error } = await supabase.rpc('create_supply_purchase', {
      p_supplier_id: form.supplier_id,
      p_inventory_id: form.supply_type,
      p_qty: form.qty,
      p_price_per_unit: form.price,
      p_shipping_cost: form.shipping || 0,
      p_amount_paid: form.qty * form.price + (form.shipping || 0), // Assuming full payment for now or add DP field if needed
      p_damaged_qty: form.damaged || 0
    });

    if (error) throw error;
    if (data?.error) { showToast(data.error, 'error'); return; }

    const usableQty = Math.max(0, form.qty - (form.damaged || 0));
    showToast(`✓ Restock berhasil — +${usableQty} unit | Record Purchase & Finance Created`, 'success');
    emit('restockDone');
  } catch (err: any) {
    showToast('Gagal: ' + (err.message || ''), 'error');
  } finally {
    submitting.value = false;
  }
}
</script>

<style scoped>
.so-overlay {
  position: fixed; inset: 0;
  background: rgba(0,0,0,0.60);
  z-index: 1001;
  display: flex; justify-content: flex-end;
}

.slide-over {
  width: 520px; max-width: 100vw; height: 100vh;
  background: #0f0f12;
  border-left: 1px solid rgba(255,255,255,0.08);
  display: flex; flex-direction: column;
  animation: slideIn 0.3s ease-out;
}

@keyframes slideIn { from { transform: translateX(100%); } to { transform: translateX(0); } }

.so-header {
  padding: 28px 28px 20px;
  display: flex; justify-content: space-between; align-items: flex-start;
  border-bottom: 1px solid rgba(255,255,255,0.06);
}

.so-title { font-family: 'Outfit', sans-serif; font-size: 18px; font-weight: 600; color: #fff; margin: 0 0 4px; }
.so-sub { font-size: 13px; color: #64748b; margin: 0; }
.btn-x { background: none; border: none; color: #64748b; font-size: 24px; cursor: pointer; padding: 0 4px; line-height: 1; }
.btn-x:hover { color: #fff; }

.so-body {
  flex: 1; overflow-y: auto; padding: 24px 28px;
  display: flex; flex-direction: column; gap: 20px;
}

.fg { display: flex; flex-direction: column; gap: 6px; }
.fg-label { font-size: 11px; font-weight: 600; letter-spacing: 1.5px; color: #64748b; text-transform: uppercase; }

.fg-input {
  background: rgba(255,255,255,0.04);
  border: 1px solid rgba(255,255,255,0.08);
  border-radius: 8px; padding: 12px 16px;
  color: #fff; font-size: 14px; font-family: 'Outfit', sans-serif;
  transition: all 200ms; width: 100%; box-sizing: border-box;
}
.fg-input:focus { outline: none; border-color: rgba(245,158,11,0.60); box-shadow: 0 0 0 3px rgba(245,158,11,0.10); }
.fg-input option { background: #141418; color: #fff; }

.fg-row { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }

/* TYPE CARDS */
.type-cards { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 10px; }

.type-card {
  background: rgba(255,255,255,0.02);
  border: 2px solid rgba(255,255,255,0.06);
  border-radius: 10px; padding: 16px 12px;
  cursor: pointer; transition: all 200ms;
  display: flex; flex-direction: column; align-items: center; gap: 6px;
  text-align: center;
}

.type-card:hover { border-color: rgba(255,255,255,0.14); }
.type-card.active { border-color: rgba(139,92,246,0.50); background: rgba(139,92,246,0.06); }
.tc-icon { font-size: 24px; }
.tc-label { font-size: 12px; font-weight: 600; color: #94a3b8; }
.type-card.active .tc-label { color: #c4b5fd; }

.input-wrap {
  display: flex; align-items: center;
  background: rgba(255,255,255,0.04);
  border: 1px solid rgba(255,255,255,0.08);
  border-radius: 8px; transition: all 200ms;
}
.input-wrap:focus-within { border-color: rgba(245,158,11,0.60); box-shadow: 0 0 0 3px rgba(245,158,11,0.10); }
.input-wrap .fg-input { background: none; border: none; box-shadow: none; }
.input-wrap .fg-input:focus { box-shadow: none; }
.prefix { padding-left: 14px; color: #64748b; font-size: 13px; font-weight: 600; white-space: nowrap; }
.suffix { padding-right: 14px; color: #8b5cf6; font-size: 11px; font-weight: 700; letter-spacing: 1px; white-space: nowrap; }

/* CALC */
.calc-card { background: rgba(139,92,246,0.06); border: 1px solid rgba(139,92,246,0.15); border-radius: 8px; padding: 16px; }
.calc-label { font-size: 11px; font-weight: 700; letter-spacing: 1px; color: #8b5cf6; text-transform: uppercase; display: block; margin-bottom: 12px; }
.calc-row { display: flex; justify-content: space-between; align-items: center; padding: 4px 0; font-size: 13px; color: #94a3b8; }
.calc-row.big { font-size: 15px; font-weight: 600; color: #fff; }
.calc-row.small { font-size: 12px; }
.calc-val { font-family: 'DM Mono', monospace; color: #fff; font-weight: 600; }
.calc-val.dim { color: #64748b; }
.calc-val.red { color: #ef4444; }
.calc-val.green { color: #10b981; }
.calc-divider { height: 1px; background: rgba(139,92,246,0.20); margin: 8px 0; }

/* FOOTER */
.so-footer {
  padding: 20px 28px; border-top: 1px solid rgba(255,255,255,0.06);
  display: flex; justify-content: space-between; align-items: center; gap: 12px;
}
.btn-ghost {
  background: transparent; border: 1px solid rgba(255,255,255,0.10); color: #fff;
  padding: 12px 24px; border-radius: 8px; font-size: 13px; font-weight: 600; cursor: pointer; transition: all 200ms;
}
.btn-ghost:hover { background: rgba(255,255,255,0.04); }
.btn-gold {
  background: #f59e0b; color: #000; border: none;
  padding: 12px 24px; border-radius: 8px; font-size: 13px; font-weight: 700; cursor: pointer; transition: all 200ms;
}
.btn-gold:hover:not(:disabled) { filter: brightness(1.1); transform: scale(1.02); }
.btn-gold:disabled { opacity: 0.4; cursor: not-allowed; }
</style>
