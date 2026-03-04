<template>
  <Teleport to="body">
    <div v-if="show" class="modal-overlay" @click.self="$emit('close')">
      <div class="choice-modal animate-pop">
        <div class="cm-header">
          <div>
            <h2 class="cm-title">Tambah Stok Baru</h2>
            <p class="cm-sub">Pilih jenis stok yang ingin ditambahkan</p>
          </div>
          <button class="btn-close" @click="$emit('close')">×</button>
        </div>

        <div class="cm-cards">
          <!-- TELUR -->
          <div class="choice-card" @click="$emit('select', 'telur')">
            <div class="cc-icon amber">🥚</div>
            <h3 class="cc-title">Stok Telur</h3>
            <p class="cc-sub">Catat pembelian batch baru dari supplier telur</p>
            <div class="cc-tags">
              <span class="cc-tag">✓ Otomatis buat utang supplier</span>
              <span class="cc-tag">✓ Lanjut ke proses grading</span>
              <span class="cc-tag">✓ Update stok per grade</span>
            </div>
          </div>

          <!-- SUPPLIES -->
          <div class="choice-card" @click="$emit('select', 'supplies')">
            <div class="cc-icon violet">📦</div>
            <h3 class="cc-title">Supplies & Packaging</h3>
            <p class="cc-sub">Restock kemasan, stiker, atau kartu untuk packaging</p>
            <div class="cc-tags">
              <span class="cc-tag">✓ Box, Stiker, Kartu</span>
              <span class="cc-tag">✓ Catat harga efektif</span>
              <span class="cc-tag">✓ Hitung HPP otomatis</span>
            </div>
          </div>
        </div>

        <div class="cm-footer">
          <span class="cm-alt">Koreksi manual stok? Gunakan tab <strong>Stok Opname</strong></span>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
defineProps<{ show: boolean }>();
defineEmits<{
  (e: 'close'): void;
  (e: 'select', type: 'telur' | 'supplies'): void;
}>();
</script>

<style scoped>
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,0.70);
  backdrop-filter: blur(12px);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
}

.choice-modal {
  background: rgba(20,20,24,0.98);
  border: 1px solid rgba(255,255,255,0.10);
  border-radius: 16px;
  width: 100%;
  max-width: 520px;
  padding: 32px;
}

.cm-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 28px;
}

.cm-title {
  font-family: 'Outfit', sans-serif;
  font-size: 20px;
  font-weight: 600;
  color: #fff;
  margin: 0 0 4px;
}

.cm-sub {
  font-size: 13px;
  color: #64748b;
  margin: 0;
}

.btn-close {
  background: none;
  border: none;
  color: #64748b;
  font-size: 24px;
  cursor: pointer;
  line-height: 1;
  padding: 0 4px;
}
.btn-close:hover { color: #fff; }

.cm-cards {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 14px;
}

.choice-card {
  background: rgba(255,255,255,0.02);
  border: 2px solid rgba(255,255,255,0.06);
  border-radius: 12px;
  padding: 24px 20px;
  cursor: pointer;
  transition: all 200ms ease;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.choice-card:first-child:hover {
  border-color: rgba(245,158,11,0.40);
  box-shadow: 0 0 24px rgba(245,158,11,0.08);
}

.choice-card:last-child:hover {
  border-color: rgba(139,92,246,0.40);
  box-shadow: 0 0 24px rgba(139,92,246,0.08);
}

.cc-icon {
  width: 48px;
  height: 48px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24px;
}

.cc-icon.amber { background: rgba(245,158,11,0.12); }
.cc-icon.violet { background: rgba(139,92,246,0.12); }

.cc-title {
  font-family: 'Outfit', sans-serif;
  font-size: 15px;
  font-weight: 600;
  color: #fff;
  margin: 0;
}

.cc-sub {
  font-size: 12px;
  color: #64748b;
  margin: 0;
  line-height: 1.4;
}

.cc-tags {
  display: flex;
  flex-direction: column;
  gap: 4px;
  margin-top: 4px;
}

.cc-tag {
  font-size: 11px;
  color: #94a3b8;
}

.cm-footer {
  margin-top: 20px;
  padding-top: 16px;
  border-top: 1px solid rgba(255,255,255,0.06);
  text-align: center;
}

.cm-alt {
  font-size: 12px;
  color: #64748b;
}
.cm-alt strong { color: #f59e0b; }

.animate-pop {
  animation: popIn 0.25s cubic-bezier(0.23, 1, 0.32, 1);
}

@keyframes popIn {
  from { opacity: 0; transform: scale(0.95); }
  to { opacity: 1; transform: scale(1); }
}
</style>
