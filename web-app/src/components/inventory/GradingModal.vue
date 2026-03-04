<template>
  <Teleport to="body">
    <div v-if="show" class="modal-overlay" @click.self="$emit('close')">
      <div class="grading-modal animate-pop">
        <div class="gm-header">
          <div>
            <h2 class="gm-title">Grading Telur</h2>
            <p class="gm-sub">
              Dari pembelian: <strong>{{ supplierName }}</strong> — 
              <strong>{{ purchase?.total_eggs_bought || 0 }}</strong> butir
            </p>
          </div>
          <button class="btn-x" @click="$emit('close')">×</button>
        </div>

        <!-- COUNTER -->
        <div class="gm-counter" :class="counterClass">
          <div class="counter-main">
            <span class="counter-val font-mono">{{ gradingTotal }}</span>
            <span class="counter-slash">/</span>
            <span class="counter-target font-mono">{{ totalEggs }}</span>
            <span class="counter-unit">butir</span>
          </div>
          <div class="counter-bar">
            <div class="counter-fill" :style="{ width: progressPct + '%' }"></div>
          </div>
          <span class="counter-status">{{ counterMessage }}</span>
        </div>

        <!-- GRADE INPUTS -->
        <div class="grade-cards">
          <div class="grade-input-card hero-accent">
            <div class="gi-top">
              <span class="gi-badge hero">HERO</span>
              <span class="gi-rule">&gt;65g</span>
            </div>
            <input type="number" v-model.number="form.hero" min="0" placeholder="0" class="gi-input font-mono" />
            <span class="gi-packs">= {{ Math.floor((form.hero || 0) / 10) }} pack</span>
          </div>

          <div class="grade-input-card medium-accent">
            <div class="gi-top">
              <span class="gi-badge medium">MEDIUM</span>
              <span class="gi-rule">55-65g</span>
            </div>
            <input type="number" v-model.number="form.medium" min="0" placeholder="0" class="gi-input font-mono" />
            <span class="gi-packs">= {{ Math.floor((form.medium || 0) / 10) }} pack</span>
          </div>

          <div class="grade-input-card small-accent">
            <div class="gi-top">
              <span class="gi-badge small">SMALL</span>
              <span class="gi-rule">&lt;55g</span>
            </div>
            <input type="number" v-model.number="form.small" min="0" placeholder="0" class="gi-input font-mono" />
            <span class="gi-packs">= {{ Math.floor((form.small || 0) / 10) }} pack</span>
          </div>
        </div>

        <!-- NOTES -->
        <div class="gm-notes">
          <label class="fg-label">CATATAN GRADING</label>
          <textarea v-model="form.notes" rows="2" class="fg-input" placeholder="e.g. Kualitas batch bagus"></textarea>
        </div>

        <div class="gm-footer">
          <button class="btn-ghost" @click="$emit('close')">Batal</button>
          <button 
            class="btn-gold" 
            :disabled="!isValid || submitting"
            @click="handleSubmit"
          >
            {{ submitting ? 'MENYIMPAN...' : 'SIMPAN GRADING' }}
          </button>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
import { ref, reactive, computed, watch } from 'vue';
import { supabase } from '../../lib/supabase';
import { useToast } from '../../composables/useToast';

const props = defineProps<{
  show: boolean;
  purchase: any;
  supplierName: string;
}>();

const emit = defineEmits<{
  (e: 'close'): void;
  (e: 'gradingDone'): void;
}>();

const { showToast } = useToast();
const submitting = ref(false);

const form = reactive({ hero: 0, medium: 0, small: 0, notes: '' });

const totalEggs = computed(() => props.purchase?.total_eggs_bought || 0);
const gradingTotal = computed(() => (form.hero || 0) + (form.medium || 0) + (form.small || 0));
const isValid = computed(() => gradingTotal.value === totalEggs.value && totalEggs.value > 0);
const progressPct = computed(() => totalEggs.value > 0 ? Math.min((gradingTotal.value / totalEggs.value) * 100, 100) : 0);

const counterClass = computed(() => {
  if (gradingTotal.value === totalEggs.value && totalEggs.value > 0) return 'exact';
  if (gradingTotal.value > totalEggs.value) return 'over';
  return 'under';
});

const counterMessage = computed(() => {
  const diff = totalEggs.value - gradingTotal.value;
  if (gradingTotal.value === totalEggs.value && totalEggs.value > 0) return '✓ Semua telur sudah digrading';
  if (gradingTotal.value > totalEggs.value) return '⚠ Melebihi jumlah pembelian!';
  return `Sisa: ${diff} butir belum digrading`;
});

watch(() => props.show, (val) => {
  if (val) {
    form.hero = 0;
    form.medium = 0;
    form.small = 0;
    form.notes = '';
  }
});

async function handleSubmit() {
  if (!isValid.value || submitting.value) return;
  submitting.value = true;
  try {
    const { data, error } = await supabase.rpc('create_grading', {
      p_purchase_id: props.purchase.id,
      p_hero_qty: form.hero || 0,
      p_medium_qty: form.medium || 0,
      p_small_qty: form.small || 0,
      p_notes: form.notes || null
    });
    if (error) throw error;
    if (data?.error) { showToast(data.error, 'error'); return; }

    showToast(`✓ Stok diperbarui: Hero +${form.hero} | Medium +${form.medium} | Small +${form.small}`, 'success');
    emit('gradingDone');
  } catch (err: any) {
    showToast('Gagal: ' + (err.message || ''), 'error');
  } finally {
    submitting.value = false;
  }
}
</script>

<style scoped>
.modal-overlay {
  position: fixed; inset: 0;
  background: rgba(0,0,0,0.70);
  backdrop-filter: blur(12px);
  display: flex; justify-content: center; align-items: center;
  z-index: 1002;
}

.grading-modal {
  background: rgba(20,20,24,0.98);
  border: 1px solid rgba(255,255,255,0.10);
  border-radius: 16px;
  width: 100%; max-width: 560px;
  padding: 32px;
  display: flex; flex-direction: column; gap: 24px;
}

.gm-header { display: flex; justify-content: space-between; align-items: flex-start; }

.gm-title {
  font-family: 'Outfit', sans-serif;
  font-size: 18px; font-weight: 600; color: #fff; margin: 0 0 4px;
}
.gm-sub { font-size: 13px; color: #64748b; margin: 0; }
.gm-sub strong { color: #94a3b8; }

.btn-x { background: none; border: none; color: #64748b; font-size: 24px; cursor: pointer; padding: 0 4px; line-height: 1; }
.btn-x:hover { color: #fff; }

/* COUNTER */
.gm-counter {
  text-align: center;
  padding: 20px;
  border-radius: 10px;
  transition: all 300ms;
}

.gm-counter.under { background: rgba(245,158,11,0.06); border: 1px solid rgba(245,158,11,0.15); }
.gm-counter.exact { background: rgba(16,185,129,0.06); border: 1px solid rgba(16,185,129,0.15); }
.gm-counter.over { background: rgba(239,68,68,0.06); border: 1px solid rgba(239,68,68,0.15); }

.counter-main { font-size: 28px; font-weight: 700; color: #fff; }
.counter-slash { color: #64748b; margin: 0 4px; }
.counter-unit { font-size: 14px; color: #64748b; margin-left: 6px; }

.counter-bar {
  height: 4px; background: rgba(255,255,255,0.06);
  border-radius: 2px; margin: 12px auto; max-width: 300px; overflow: hidden;
}

.counter-fill { height: 100%; border-radius: 2px; transition: width 300ms; }
.under .counter-fill { background: #f59e0b; }
.exact .counter-fill { background: #10b981; }
.over .counter-fill { background: #ef4444; }

.counter-status { font-size: 12px; font-weight: 600; }
.under .counter-status { color: #f59e0b; }
.exact .counter-status { color: #10b981; }
.over .counter-status { color: #ef4444; }

/* GRADE CARDS */
.grade-cards { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 12px; }

.grade-input-card {
  background: rgba(255,255,255,0.02);
  border: 1px solid rgba(255,255,255,0.06);
  border-radius: 10px;
  padding: 16px;
  text-align: center;
  display: flex; flex-direction: column; gap: 10px; align-items: center;
}

.gi-top { display: flex; align-items: center; gap: 8px; justify-content: center; }

.gi-badge {
  font-size: 11px; font-weight: 700; padding: 3px 10px;
  border-radius: 20px; letter-spacing: 0.5px;
}
.gi-badge.hero { background: #f59e0b; color: #000; }
.gi-badge.medium { background: #8b5cf6; color: #fff; }
.gi-badge.small { background: #38bdf8; color: #000; }

.gi-rule { font-size: 11px; color: #64748b; }

.gi-input {
  width: 80px; text-align: center;
  font-size: 28px; font-weight: 700;
  background: rgba(255,255,255,0.04);
  border: 1px solid rgba(255,255,255,0.08);
  border-radius: 8px;
  padding: 8px;
  color: #fff;
  transition: all 200ms;
}

.gi-input:focus {
  outline: none;
  border-color: rgba(245,158,11,0.50);
  box-shadow: 0 0 0 3px rgba(245,158,11,0.10);
}

.gi-packs { font-size: 12px; color: #64748b; }

/* NOTES */
.gm-notes { display: flex; flex-direction: column; gap: 6px; }
.fg-label { font-size: 11px; font-weight: 600; letter-spacing: 1.5px; color: #64748b; text-transform: uppercase; }
.fg-input {
  background: rgba(255,255,255,0.04);
  border: 1px solid rgba(255,255,255,0.08);
  border-radius: 8px; padding: 12px 16px;
  color: #fff; font-size: 14px; font-family: 'Outfit', sans-serif;
  transition: all 200ms; resize: vertical; width: 100%; box-sizing: border-box;
}
.fg-input:focus { outline: none; border-color: rgba(245,158,11,0.60); box-shadow: 0 0 0 3px rgba(245,158,11,0.10); }

/* FOOTER */
.gm-footer { display: flex; justify-content: space-between; gap: 12px; }

.btn-ghost {
  background: transparent; border: 1px solid rgba(255,255,255,0.10);
  color: #fff; padding: 12px 24px; border-radius: 8px;
  font-size: 13px; font-weight: 600; cursor: pointer; transition: all 200ms;
}
.btn-ghost:hover { background: rgba(255,255,255,0.04); }

.btn-gold {
  background: #f59e0b; color: #000; border: none;
  padding: 12px 24px; border-radius: 8px;
  font-size: 13px; font-weight: 700; cursor: pointer; transition: all 200ms;
}
.btn-gold:hover:not(:disabled) { filter: brightness(1.1); transform: scale(1.02); }
.btn-gold:disabled { opacity: 0.4; cursor: not-allowed; }

.animate-pop { animation: popIn 0.25s cubic-bezier(0.23, 1, 0.32, 1); }
@keyframes popIn { from { opacity: 0; transform: scale(0.95); } to { opacity: 1; transform: scale(1); } }

.font-mono { font-family: 'DM Mono', monospace; }
</style>
