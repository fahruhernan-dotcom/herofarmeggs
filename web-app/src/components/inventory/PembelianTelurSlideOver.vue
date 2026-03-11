<template>
  <Teleport to="body">
    <div v-if="show" class="so-overlay" @click.self="$emit('close')">
      <transition name="slide">
        <div class="slide-over">
          <div class="so-header">
            <div>
              <h2 class="so-title">Pembelian Telur Baru</h2>
              <p class="so-sub">Catat batch masuk dari peternak</p>
            </div>
            <button class="btn-x" @click="$emit('close')">×</button>
          </div>

          <div class="so-body">
            <!-- PRODUCT SELECTOR -->
            <div class="fg">
              <label class="fg-label">PRODUK YANG DIBELI</label>
              <div class="product-selector">
                <div class="product-option" 
                     :class="{ selected: form.product_id === 'hero' }" 
                     @click="form.product_id = 'hero'">
                  <div class="po-icon">🥚</div>
                  <div class="po-text">Telur Hero</div>
                </div>
                <div class="product-option" 
                     :class="{ selected: form.product_id === 'salted_egg' }" 
                     @click="form.product_id = 'salted_egg'">
                  <div class="po-icon">🧂</div>
                  <div class="po-text">Salted Egg</div>
                </div>
              </div>
            </div>

            <!-- SUPPLIER -->
            <div class="fg">
              <label class="fg-label">SUPPLIER</label>
              <CustomDropdown
                v-model="form.supplier_id"
                :options="supplierOptions"
                placeholder="Pilih supplier..."
                search-placeholder="Cari nama supplier..."
              />
              <span v-if="autoFilledPrice" class="price-hint">💡 Harga dari katalog: {{ formatCurrency(autoFilledPrice) }}</span>
            </div>

            <!-- QTY + PRICE -->
            <div class="fg-row">
              <div class="fg">
                <label class="fg-label">JUMLAH TELUR DIBELI</label>
                <div class="input-wrap">
                  <input type="number" v-model.number="form.total_eggs" min="1" placeholder="0" class="fg-input" />
                  <span class="suffix">BUTIR</span>
                </div>
              </div>
              <div class="fg">
                <label class="fg-label">HARGA BELI PER BUTIR</label>
                <div class="input-wrap">
                  <span class="prefix">Rp</span>
                  <input type="number" v-model.number="form.price_per_egg" min="1" placeholder="0" class="fg-input" />
                </div>
              </div>
            </div>

            <!-- LIVE CALC -->
            <div v-if="form.total_eggs > 0 && form.price_per_egg > 0" class="calc-card">
              <span class="calc-label">📊 KALKULASI OTOMATIS</span>
              <div class="calc-row">
                <span>Total Pembelian</span>
                <span class="calc-val">{{ formatCurrency(totalCost) }}</span>
              </div>
              <div class="calc-row" v-if="form.amount_paid > 0">
                <span>Uang Muka</span>
                <span class="calc-val dim">- {{ formatCurrency(form.amount_paid) }}</span>
              </div>
              <div class="calc-divider"></div>
              <div class="calc-row big">
                <span>Sisa Utang</span>
                <span class="calc-val" :class="sisaUtang > 0 ? 'red' : 'green'">{{ formatCurrency(sisaUtang) }}</span>
              </div>
              <div class="calc-row small">
                <span>HPP per Pack (10B)</span>
                <span class="calc-val dim">{{ formatCurrency(previewHppPack) }}</span>
              </div>
            </div>

            <!-- DP -->
            <div class="fg">
              <label class="fg-label">BAYAR DI MUKA (OPSIONAL)</label>
              <span class="fg-hint">Kosongkan jika belum bayar apapun</span>
              <div class="input-wrap">
                <span class="prefix">Rp</span>
                <input type="number" v-model.number="form.amount_paid" min="0" placeholder="0" class="fg-input" />
              </div>
              <div v-if="totalCost > 0" class="dp-badge" :class="dpStatus.class">{{ dpStatus.label }}</div>
            </div>

            <!-- NOTES -->
            <div class="fg">
              <label class="fg-label">CATATAN BATCH</label>
              <textarea v-model="form.notes" v-titlecase rows="2" class="fg-input fg-textarea" placeholder="Contoh: Batch 02/Mar/2026 - Kualitas A"></textarea>
            </div>
          </div>

          <div class="so-footer">
            <button class="btn-ghost" @click="$emit('close')">Batal</button>
            <button 
              class="btn-gold" 
              :disabled="!canSubmit || submitting"
              @click="handleSubmit"
            >
              {{ submitting ? 'MEMPROSES...' : 'SIMPAN PEMBELIAN & MASUK STOK' }}
            </button>
          </div>
        </div>
      </transition>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
import { ref, reactive, computed, watch } from 'vue';
import { supabase } from '../../lib/supabase';
import { formatCurrency } from '../../utils/formatters';
import { useToast } from '../../composables/useToast';
import CustomDropdown from '../ui/CustomDropdown.vue';
import { sanitizePayload } from '../../utils/sanitize';

const props = defineProps<{ show: boolean }>();
const emit = defineEmits<{
  (e: 'close'): void;
  (e: 'purchaseCreated', purchase: any): void;
}>();

const { showToast } = useToast();
const submitting = ref(false);
const allSuppliers = ref<any[]>([]);

const form = reactive({
  product_id: 'hero',
  supplier_id: '',
  total_eggs: 0,
  price_per_egg: 0,
  amount_paid: 0,
  notes: ''
});

// Reset supplier if product changes
watch(() => form.product_id, () => {
  form.supplier_id = '';
  autoFilledPrice.value = 0;
});

const supplierOptions = computed(() => {
  return allSuppliers.value
    .filter(s => {
      const cat = (s.category || '').toLowerCase();
      // Broaden matching logic to prevent empty list if categories are slightly different
      if (form.product_id === 'hero') return cat.includes('hero') || cat.includes('bebek') || cat === 'telur';
      if (form.product_id === 'salted_egg') return cat.includes('salted') || cat.includes('asin');
      return true;
    })
    .map(s => ({
      label: s.name,
      value: s.id,
      sublabel: s.category || 'Supplier Telur'
    }));
});

const totalCost = computed(() => form.total_eggs * form.price_per_egg);
const sisaUtang = computed(() => Math.max(0, totalCost.value - (form.amount_paid || 0)));
const canSubmit = computed(() => form.supplier_id && form.total_eggs > 0 && form.price_per_egg > 0);

const autoFilledPrice = ref(0);

const dpStatus = computed(() => {
  if (totalCost.value <= 0) return { label: '', class: '' };
  if ((form.amount_paid || 0) >= totalCost.value) return { label: '✓ LUNAS', class: 'lunas' };
  if ((form.amount_paid || 0) === 0) return { label: 'Seluruhnya jadi utang', class: 'utang' };
  return { label: 'Cicilan awal', class: 'cicilan' };
});

async function fetchSuppliers() {
  const { data } = await supabase
    .from('suppliers')
    .select('id, name, category, price_list')
    .eq('is_deleted', false)
    .order('name');
  
  if (data) Object.assign(allSuppliers.value, data);
}

watch(() => props.show, (val) => {
  if (val) {
    fetchSuppliers();
    fetchSupplyCosts(); // Fetch latest supply costs when sliding over
    // Reset form
    form.product_id = 'hero';
    form.supplier_id = '';
    form.total_eggs = 0;
    form.price_per_egg = 0;
    form.amount_paid = 0;
    form.notes = '';
    autoFilledPrice.value = 0;
  }
});

watch(() => form.supplier_id, (id) => {
  if (!id) { autoFilledPrice.value = 0; return; }
  const supplier = allSuppliers.value.find(s => s.id === id);
  if (supplier?.price_list?.length) {
    const eggItem = supplier.price_list.find((p: any) => 
      p.item_name?.toLowerCase().includes('telur') || p.item_name?.toLowerCase().includes('egg')
    );
    if (eggItem?.price) {
      form.price_per_egg = eggItem.price;
      autoFilledPrice.value = eggItem.price;
    }
  }
});

const supplyCosts = reactive({
  packaging: 0,
  sticker: 0,
  card: 0
});

async function fetchSupplyCosts() {
  const { data } = await supabase
    .from('inventory')
    .select('id, cost_per_egg')
    .in('id', ['packaging_standard', 'sticker_label', 'mini_card']);
  
  if (data) {
    supplyCosts.packaging = data.find(i => i.id === 'packaging_standard')?.cost_per_egg || 0;
    supplyCosts.sticker = data.find(i => i.id === 'sticker_label')?.cost_per_egg || 0;
    supplyCosts.card = data.find(i => i.id === 'mini_card')?.cost_per_egg || 0;
  }
}

const previewHppPack = computed(() => {
  return (form.price_per_egg * 10) + supplyCosts.packaging + supplyCosts.sticker + supplyCosts.card;
});

async function handleSubmit() {
  if (!canSubmit.value || submitting.value) return;
  submitting.value = true;
  try {
    const cleanPayload = sanitizePayload({ notes: form.notes });
    const { data, error } = await supabase.rpc('create_purchase_with_utang', {
      p_supplier_id: form.supplier_id,
      p_total_eggs: form.total_eggs,
      p_price_per_egg: form.price_per_egg,
      p_amount_paid: form.amount_paid || 0,
      p_notes: cleanPayload.notes || null,
      p_product_id: form.product_id
    });
    if (error) throw error;
    if (data?.error) { showToast(data.error, 'error'); return; }

    const supplierName = allSuppliers.value.find(s => s.id === form.supplier_id)?.name || 'Supplier';
    showToast(`✓ Pembelian dicatat — ${formatCurrency(totalCost.value)} | Utang: ${formatCurrency(sisaUtang.value)} ke ${supplierName}`, 'success');

    emit('purchaseCreated', { id: data.purchase_id, total_eggs_bought: form.total_eggs, supplier_id: form.supplier_id });
  } catch (err: any) {
    showToast('Gagal: ' + (err.message || ''), 'error');
  } finally {
    submitting.value = false;
  }
}

</script>

<style scoped>
.so-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,0.60);
  z-index: 1001;
  display: flex;
  justify-content: flex-end;
}

.slide-over {
  width: 520px;
  max-width: 100vw;
  height: 100vh;
  background: #0f0f12;
  border-left: 1px solid rgba(255,255,255,0.08);
  display: flex;
  flex-direction: column;
  animation: slideIn 0.3s ease-out;
}

@keyframes slideIn {
  from { transform: translateX(100%); }
  to { transform: translateX(0); }
}

.so-header {
  padding: 28px 28px 20px;
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  border-bottom: 1px solid rgba(255,255,255,0.06);
}

.so-title {
  font-family: 'Outfit', sans-serif;
  font-size: 18px;
  font-weight: 600;
  color: #fff;
  margin: 0 0 4px;
}

.so-sub { font-size: 13px; color: #64748b; margin: 0; }

.btn-x {
  background: none; border: none; color: #64748b; font-size: 24px; cursor: pointer; padding: 0 4px; line-height: 1;
}
.btn-x:hover { color: #fff; }

.so-body {
  flex: 1;
  overflow-y: auto;
  padding: 24px 28px;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.fg { display: flex; flex-direction: column; gap: 6px; }
.fg-label {
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 1.5px;
  color: #64748b;
  text-transform: uppercase;
}
.fg-hint { font-size: 11px; color: #475569; }

.fg-input {
  background: rgba(255,255,255,0.04);
  border: 1px solid rgba(255,255,255,0.08);
  border-radius: 8px;
  padding: 12px 16px;
  color: #fff;
  font-size: 14px;
  font-family: 'Outfit', sans-serif;
  transition: all 200ms;
  width: 100%;
  box-sizing: border-box;
}

.fg-input:focus {
  outline: none;
  border-color: rgba(245,158,11,0.60);
  box-shadow: 0 0 0 3px rgba(245,158,11,0.10);
}

.fg-input option { background: #141418; color: #fff; }

.fg-textarea { resize: vertical; min-height: 60px; }

.fg-row { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }

.input-wrap {
  display: flex;
  align-items: center;
  background: rgba(255,255,255,0.04);
  border: 1px solid rgba(255,255,255,0.08);
  border-radius: 8px;
  transition: all 200ms;
}

.input-wrap:focus-within {
  border-color: rgba(245,158,11,0.60);
  box-shadow: 0 0 0 3px rgba(245,158,11,0.10);
}

.input-wrap .fg-input {
  background: none;
  border: none;
  box-shadow: none;
}

.input-wrap .fg-input:focus { box-shadow: none; }

.prefix {
  padding-left: 14px;
  color: #64748b;
  font-size: 13px;
  font-weight: 600;
  white-space: nowrap;
}

.suffix {
  padding-right: 14px;
  color: #f59e0b;
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 1px;
  white-space: nowrap;
}

.price-hint {
  font-size: 12px;
  color: #10b981;
  margin-top: 2px;
}

/* CALC CARD */
.calc-card {
  background: rgba(245,158,11,0.06);
  border: 1px solid rgba(245,158,11,0.15);
  border-radius: 8px;
  padding: 16px;
}

.calc-label {
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 1px;
  color: #f59e0b;
  text-transform: uppercase;
  display: block;
  margin-bottom: 12px;
}

.calc-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 4px 0;
  font-size: 13px;
  color: #94a3b8;
}

.calc-row.big { font-size: 15px; font-weight: 600; color: #fff; }
.calc-row.small { font-size: 12px; }

.calc-val {
  font-family: 'DM Mono', monospace;
  color: #fff;
  font-weight: 600;
}

.calc-val.dim { color: #64748b; }
.calc-val.red { color: #ef4444; }
.calc-val.green { color: #10b981; }

.calc-divider {
  height: 1px;
  background: rgba(245,158,11,0.20);
  margin: 8px 0;
}

/* DP BADGE */
.dp-badge {
  font-size: 11px;
  font-weight: 700;
  padding: 4px 10px;
  border-radius: 6px;
  width: fit-content;
  margin-top: 4px;
}

.dp-badge.lunas { background: rgba(16,185,129,0.12); color: #10b981; }
.dp-badge.utang { background: rgba(245,158,11,0.12); color: #f59e0b; }
.dp-badge.cicilan { background: rgba(245,158,11,0.12); color: #f59e0b; }

/* FOOTER */
.so-footer {
  padding: 20px 28px;
  border-top: 1px solid rgba(255,255,255,0.06);
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
}

.btn-ghost {
  background: transparent;
  border: 1px solid rgba(255,255,255,0.10);
  color: #fff;
  padding: 12px 24px;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: all 200ms;
}

.btn-ghost:hover { background: rgba(255,255,255,0.04); }

.btn-gold {
  background: #f59e0b;
  color: #000;
  border: none;
  padding: 12px 24px;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 700;
  cursor: pointer;
  transition: all 200ms;
}

.btn-gold:hover:not(:disabled) { filter: brightness(1.1); transform: scale(1.02); }
.btn-gold:disabled { opacity: 0.4; cursor: not-allowed; }

.product-selector {
  display: flex;
  gap: 12px;
  margin-bottom: 16px;
}

.product-option {
  flex: 1;
  background: rgba(255,255,255,0.03);
  border: 1px solid rgba(255,255,255,0.1);
  border-radius: 12px;
  padding: 16px;
  display: flex;
  align-items: center;
  gap: 12px;
  cursor: pointer;
  transition: all 150ms;
}

.product-option:hover {
  background: rgba(255,255,255,0.06);
}

.product-option.selected {
  background: rgba(245,158,11,0.1);
  border-color: #f59e0b;
}

.po-icon {
  font-size: 24px;
}

.po-text {
  font-size: 14px;
  font-weight: 700;
  color: white;
}
</style>
