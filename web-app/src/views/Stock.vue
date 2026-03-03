<template>
  <div class="stock-page">
    <header class="header">
      <div class="header-left">
        <h4 class="brand-tag">B2B LOGISTICS</h4>
        <h1 class="hero-font">Manajemen Stok</h1>
        <p class="text-dim">Monitoring inventory & input barang datang.</p>
      </div>
      <div class="header-actions">
        <button class="btn-primary-glow" @click="showAdjustmentModal = true" :disabled="loading">
          <PlusIcon class="icon" />
          <span>TAMBAH STOK BARU</span>
        </button>
      </div>
    </header>

    <nav class="tab-nav glass-panel">
      <button 
        class="tab-btn" 
        :class="{ active: activeTab === 'inventory' }"
        @click="activeTab = 'inventory'"
      >
        <PackageIcon class="icon-sm" />
        <span>Inventory Matrix</span>
      </button>
      <button 
        class="tab-btn" 
        :class="{ active: activeTab === 'pembelian' }"
        @click="activeTab = 'pembelian'"
      >
        <TruckIcon class="icon-sm" />
        <span>Pembelian & Grading</span>
      </button>
      <button 
        class="tab-btn" 
        :class="{ active: activeTab === 'stok_opname' }"
        @click="activeTab = 'stok_opname'"
      >
        <ClipboardListIcon class="icon-sm" />
        <span>Stok Opname</span>
      </button>
    </nav>

    <div v-if="activeTab === 'inventory'" class="tab-content animate-fade">
      <section class="inventory-section">

      <div class="section-header-flex">
        <div class="section-badge">PRIMARY PRODUCTS</div>
        <button 
          v-if="authStore.profile?.role === 'admin'"
          class="btn-secondary-xs" 
          @click="recalculateAllHPP"
          :disabled="recalculating"
        >
          <RefreshCwIcon :class="{ 'animate-spin': recalculating }" class="icon-xs" />
          <span>{{ recalculating ? 'RECALCULATING...' : 'RECALCULATE ALL HPP' }}</span>
        </button>
      </div>
      <div class="stock-grid" v-if="loading">
        <SkeletonLoader v-for="i in 3" :key="i" type="card" height="320px" />
      </div>
      <div class="stock-grid" v-else-if="eggInventory.length > 0">
        <div v-for="item in eggInventory" :key="item.id" class="stock-card glass-panel" :class="[item.id, { 'low-stock': item.current_stock <= (item.safety_stock || 20) }]">
          <!-- card content ... -->
          <div class="card-bg-icon">
            <PackageIcon v-if="item.id === 'hero'" />
            <CookingPotIcon v-else-if="item.id === 'medium'" />
            <ZapIcon v-else />
          </div>
          <div class="card-content">
            <div class="top">
              <span class="label">{{ item.grade || item.label }}</span>
              <div v-if="item.current_stock <= (item.safety_stock || 20)" class="pulsing-badge critical">
                <AlertTriangleIcon class="icon-xs" />
                <span>RESTOCK REQ.</span>
              </div>
              <div v-else class="pulsing-badge safe">
                <div class="dot online"></div>
                <span>OPTIMAL</span>
              </div>
            </div>
            <div class="main">
              <h2 class="stock-value">
                <span class="v-num">{{ item.current_stock.toLocaleString('id-ID') }}</span>
                <span class="v-unit">butir</span>
              </h2>
              <div class="price-info">
                <div class="retail-tag clickable" @click="openEditProduct(item)" title="Click to Change Price">
                  <span class="rt-label">Retail</span>
                  <span class="rt-val">Rp {{ (item.retail_price_per_pack || item.base_price_per_pack || 0).toLocaleString('id-ID') }}</span>
                </div>
                <div v-if="authStore.profile?.role === 'admin'" class="hpp-glass">
                  <LockIcon class="icon-xs" />
                  <div class="hpp-inner">
                    <span class="hpp-label">HPP/Butir</span>
                    <span class="hpp-val">Rp {{ (item.hpp_per_egg || item.cost_per_egg || 0).toLocaleString('id-ID') }}</span>
                  </div>
                </div>
                <div v-if="authStore.profile?.role === 'admin'" class="hpp-glass">
                  <LockIcon class="icon-xs" />
                  <div class="hpp-inner">
                    <span class="hpp-label">HPP/Pack</span>
                    <span class="hpp-val">Rp {{ (item.hpp_per_pack || item.cost_price || 0).toLocaleString('id-ID') }}</span>
                  </div>
                </div>
                <div v-if="authStore.profile?.role === 'admin' && (item.margin_pct !== null)" class="margin-tag" :class="(item.margin_pct || 0) >= 20 ? 'good' : 'low'">
                  <span class="mt-label">Margin</span>
                  <span class="mt-val">{{ (item.margin_pct || 0).toFixed(1) }}%</span>
                </div>
              </div>
            </div>
            <div class="card-footer-elite">
              <div class="mini-stat">
                <span class="ms-label">Safety Stock</span>
                <span class="ms-value">{{ item.safety_stock || 20 }}</span>
              </div>
              <div class="card-actions">
                <button v-if="authStore.profile?.role === 'admin'" class="btn-icon-circle" @click="openEditProduct(item)" title="Edit Specs">
                  <Edit3Icon class="icon-sm" />
                </button>
                <button class="btn-tactical" @click="quickAdjust(item.id)">
                  <span>ADJUST STOCK</span>
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
      <EmptyState v-else icon="PackageIcon" title="Inventory Kosong" message="Produk telur belum terdaftar di database." />
    </section>

    <section class="inventory-section">
      <div class="section-badge">SUPPLIES & PACKAGING</div>
      <div class="stock-grid" v-if="loading">
        <SkeletonLoader v-for="i in 2" :key="i" type="card" height="320px" />
      </div>
      <div class="stock-grid" v-else-if="supplyInventory.length > 0">
        <div v-for="item in supplyInventory" :key="item.id" class="stock-card glass-panel supply-card" :class="{ 'low-stock': item.current_stock <= 20 }">
          <div class="card-bg-icon"><PackageIcon /></div>
          <div class="card-content">
            <div class="top">
              <span class="label">{{ item.label }}</span>
              <div v-if="item.current_stock <= 20" class="pulsing-badge critical small">
                <span>LOW</span>
              </div>
            </div>
            <div class="main">
              <h2 class="stock-value supply">
                <span class="v-num">{{ item.current_stock }}</span>
                <span class="v-unit">units</span>
              </h2>
              <div class="price-info">
                <div class="hpp-glass supply">
                  <TruckIcon class="icon-xs" />
                  <div class="hpp-inner">
                    <span class="hpp-label">Effective Cost</span>
                    <span class="hpp-val">Rp {{ (item.cost_per_egg || 0).toLocaleString('id-ID') }}</span>
                  </div>
                </div>
              </div>
            </div>
            <div class="card-footer-elite">
              <div class="mini-stat">
                <span class="ms-label">Safety Stock</span>
                <span class="ms-value">20</span>
              </div>
              <div class="card-actions">
                <button v-if="authStore.profile?.role === 'admin'" class="btn-primary-tactical" @click="openPackagingPurchase(item)">
                  <PlusIcon class="icon-sm" />
                  <span>RESTOCK</span>
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
      <EmptyState v-else icon="PackageSearchIcon" title="Supplies Kosong" message="Belum ada data kemasan atau label." />
    </section>

    <!-- RECENT TRANSACTIONS / LOGS -->
    <section class="logs-section glass-panel">
      <div class="section-header">
        <h3 class="hero-font">Audit Trail</h3>
        <span class="text-dim">Last 20 operations</span>
      </div>
      
      <div class="logs-table-wrapper">
        <div v-if="loading" class="flex flex-column gap-2">
          <SkeletonLoader v-for="i in 5" :key="i" type="table-row" />
        </div>
        <table v-else-if="logs.length > 0" class="logs-table">
          <thead>
            <tr>
              <th>Timestamp</th>
              <th>Type</th>
              <th>Change</th>
              <th>Reason</th>
              <th>Admin</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="log in logs" :key="log.id" class="log-row">
              <td class="time">{{ formatTime(log.created_at) }}</td>
              <td>
                <span class="log-badge" :class="log.log_type">{{ log.log_type }}</span>
              </td>
              <td class="change" :class="log.change > 0 ? 'pos' : 'neg'">
                {{ log.change > 0 ? '+' : '' }}{{ (log.change || 0).toLocaleString('id-ID') }}
              </td>
              <td class="notes">
                <span class="note-text">{{ formatLogNotes(log.notes) }}</span>
              </td>
              <td class="admin">System Admin</td>
            </tr>
          </tbody>
        </table>
        <EmptyState v-else icon="HistoryIcon" title="Belum ada riwayat" message="Semua pergerakan stok akan tercatat di sini." />
      </div>
      </section>
    </div>

    <!-- ━━━ TAB 2: PEMBELIAN & GRADING ━━━ -->
    <div v-else-if="activeTab === 'pembelian'" class="tab-content animate-fade">
      <div class="purchase-layout">
        <!-- STEP 1: FORM PEMBELIAN -->
        <div v-if="!purchaseForGrading" class="glass-panel purchase-form-panel">
          <div class="purchase-form-header">
            <h2 class="hero-font text-xl">Input Pembelian Telur</h2>
            <p class="text-dim">Mencatat batch masuk dari supplier secara manual.</p>
          </div>
          <form @submit.prevent="submitPurchase" class="modal-form mt-6">
            <div class="form-group">
              <CustomDropdown 
                v-model="purchaseForm.supplier_id" 
                :options="eggSupplierOptions" 
                label="Supplier"
                placeholder="Pilih supplier..."
              />
            </div>
            <div class="form-row mt-4">
              <div class="form-group flex-1">
                <label>Jumlah Butir</label>
                <div class="input-group-premium">
                  <input type="number" v-model.number="purchaseForm.total_eggs" placeholder="0" required min="1" />
                  <span class="suffix">BUTIR</span>
                </div>
              </div>
              <div class="form-group flex-1">
                <label>Harga per Butir</label>
                <div class="input-group-premium">
                  <span class="prefix">Rp</span>
                  <input type="number" v-model.number="purchaseForm.price_per_egg" placeholder="0" required min="1" />
                </div>
              </div>
            </div>

            <div class="form-group">
              <label>Uang Muka / DP (Opsional)</label>
              <div class="input-group-premium">
                <span class="prefix">Rp</span>
                <input type="number" v-model.number="purchaseForm.amount_paid" placeholder="0" min="0" />
              </div>
            </div>

            <!-- RINGKASAN PEMBELIAN -->
            <div v-if="purchaseForm.total_eggs > 0 && purchaseForm.price_per_egg > 0" class="order-summary-box animate-slide">
              <div class="summary-line">
                <span>Total Tagihan:</span>
                <span class="val">Rp {{ (purchaseForm.total_eggs * purchaseForm.price_per_egg).toLocaleString('id-ID') }}</span>
              </div>
              <div class="summary-line highlight" v-if="(purchaseForm.total_eggs * purchaseForm.price_per_egg - purchaseForm.amount_paid) > 0">
                <span>Total Sisa Utang:</span>
                <span class="val text-red">Rp {{ Math.max(0, purchaseForm.total_eggs * purchaseForm.price_per_egg - purchaseForm.amount_paid).toLocaleString('id-ID') }}</span>
              </div>
              <div class="summary-line secondary">
                <span>Estimasi HPP/Pack (10B):</span>
                <span class="val">Rp {{ Math.round(purchaseForm.price_per_egg * 10 * 1.073).toLocaleString('id-ID') }}</span>
              </div>
            </div>
            <div class="form-group mt-2">
              <label>Catatan Tambahan</label>
              <textarea v-model="purchaseForm.notes" placeholder="Tulis keterangan batch atau nomor surat jalan..." rows="2"></textarea>
            </div>

            <div class="form-footer-actions">
              <button type="submit" class="btn-primary-action" :disabled="submittingPurchase || !purchaseForm.supplier_id">
                <span v-if="submittingPurchase">MEMPROSES...</span>
                <span v-else>SIMPAN & LANJUT KE GRADING</span>
              </button>
            </div>
          </form>
        </div>

        <!-- STEP 2: GRADING FORM -->
        <div v-else class="glass-panel grading-form-panel animate-pop">
          <div class="section-header-flex">
            <div>
              <h2 class="hero-font">Grading / Sortir Telur</h2>
              <p class="text-dim">
                Pembelian: <strong>{{ purchaseForGrading.total_eggs_bought }} butir</strong> dari 
                <strong>{{ suppliers.find(s => s.id === purchaseForGrading.supplier_id)?.name || 'Supplier' }}</strong>
              </p>
            </div>
            <button class="btn-secondary" @click="purchaseForGrading = null">← Kembali</button>
          </div>

          <form @submit.prevent="submitGrading" class="modal-form mt-6">
            <div class="grading-cards">
              <div class="grading-card glass-panel hero-grade">
                <div class="gc-header">
                  <span class="gc-badge hero">HERO</span>
                  <span class="gc-rule">&gt;65g</span>
                </div>
                <input type="number" v-model.number="gradingForm.hero_qty" min="0" placeholder="0" class="gc-input" />
                <span class="gc-unit">butir</span>
              </div>
              <div class="grading-card glass-panel medium-grade">
                <div class="gc-header">
                  <span class="gc-badge medium">MEDIUM</span>
                  <span class="gc-rule">55-65g</span>
                </div>
                <input type="number" v-model.number="gradingForm.medium_qty" min="0" placeholder="0" class="gc-input" />
                <span class="gc-unit">butir</span>
              </div>
              <div class="grading-card glass-panel small-grade">
                <div class="gc-header">
                  <span class="gc-badge small">SMALL</span>
                  <span class="gc-rule">&lt;55g</span>
                </div>
                <input type="number" v-model.number="gradingForm.small_qty" min="0" placeholder="0" class="gc-input" />
                <span class="gc-unit">butir</span>
              </div>
            </div>

            <!-- VALIDATION BAR -->
            <div class="grading-validation" :class="gradingTotalValid ? 'valid' : 'invalid'">
              <span>Total: {{ gradingTotal }} / {{ purchaseForGrading.total_eggs_bought }} butir</span>
              <span v-if="gradingTotalValid" class="check-text">✓ Cocok</span>
              <span v-else class="warning-text">✗ Belum cocok</span>
            </div>

            <div class="form-group">
              <label>Catatan Grading</label>
              <textarea v-model="gradingForm.notes" placeholder="e.g. Kualitas batch bagus"></textarea>
            </div>

            <div class="modal-actions">
              <button type="button" class="btn-secondary" @click="purchaseForGrading = null">Batal</button>
              <button type="submit" class="btn-primary" :disabled="!gradingTotalValid || submittingGrading">
                {{ submittingGrading ? 'MENYIMPAN...' : 'SIMPAN GRADING' }}
              </button>
            </div>
          </form>
        </div>

        <!-- PURCHASE HISTORY -->
        <div class="glass-panel purchase-history-panel mt-8">
          <div class="section-header-flex">
            <h3 class="hero-font">Riwayat Pembelian</h3>
          </div>
          <div class="table-container-elite mt-4">
            <table v-if="purchases.length > 0" class="logs-table v-middle">
              <thead>
                <tr>
                  <th>Tanggal</th>
                  <th>Supplier</th>
                  <th>Qty (butir)</th>
                  <th>Harga/Butir</th>
                  <th>Total</th>
                  <th>Status</th>
                  <th>Sisa Utang</th>
                  <th>Aksi</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="p in purchases" :key="p.id" class="log-row">
                  <td class="font-bold">{{ formatDate(p.purchase_date || p.created_at) }}</td>
                  <td>{{ suppliers.find(s => s.id === p.supplier_id)?.name || '-' }}</td>
                  <td>{{ p.total_eggs_bought.toLocaleString('id-ID') }}</td>
                  <td>Rp {{ p.price_per_egg.toLocaleString('id-ID') }}</td>
                  <td class="font-bold">Rp {{ p.total_cost.toLocaleString('id-ID') }}</td>
                  <td>
                    <span class="status-badge" :class="p.status">{{ p.status === 'lunas' ? 'LUNAS' : p.status === 'cicilan' ? 'CICILAN' : 'UTANG' }}</span>
                  </td>
                  <td :class="p.remaining_debt > 0 ? 'text-red font-bold' : 'text-green'">
                    Rp {{ (p.remaining_debt || 0).toLocaleString('id-ID') }}
                  </td>
                  <td>
                    <button 
                      v-if="!purchaseHasGrading(p.id)"
                      class="btn-lite-action" 
                      @click="startGradingFor(p)"
                    >Grading</button>
                    <span v-else class="text-dim text-xs">✓ Graded</span>
                  </td>
                </tr>
              </tbody>
            </table>
            <EmptyState v-else icon="TruckIcon" title="Belum Ada Pembelian" message="Catat pembelian telur pertama Anda di atas." />
          </div>
        </div>
      </div>
    </div>

    <!-- ━━━ FEATURE 1: STOK OPNAME SECTION ━━━ -->
    <div v-else-if="activeTab === 'stok_opname'" class="tab-content animate-fade">
      <div class="stok-opname-layout">
        <!-- Dashboard / History -->
        <div v-if="!activeStokTake" class="so-dashboard glass-panel elite-hub">
          <div class="so-header-premium">
            <div class="sh-left">
              <h2 class="hero-font hub-title">Pusat Verifikasi Stok</h2>
              <p class="text-dim hub-desc">Audit dan sinkronisasi stok fisik dengan pencatatan digital secara akurat.</p>
            </div>
            <button 
              v-if="authStore.profile?.role === 'admin'"
              class="btn-hub-primary" 
              @click="startNewStokOpname"
              :disabled="loadingSO"
            >
              <PlusIcon class="icon-sm" />
              <span>MULAI STOK OPNAME BARU</span>
            </button>
          </div>

          <div class="so-history-section mt-10">
            <div class="section-title-wrapper mb-6">
                <h4 class="section-label-elite">Riwayat Verifikasi</h4>
                <div class="accent-line"></div>
            </div>
            <div class="table-container-elite">
                <table class="logs-table v-middle" v-if="opnameHistory.length > 0">
                    <thead>
                        <tr>
                        <th>Tanggal</th>
                        <th>Oleh</th>
                        <th>Selisih Total</th>
                        <th>Status</th>
                        <th class="text-right">Aksi</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr v-for="so in opnameHistory" :key="so.id" class="log-row">
                        <td class="font-bold">{{ formatDate(so.opname_date) }}</td>
                        <td class="text-dim">{{ so.conducted_by }}</td>
                        <td :class="so.total_difference < 0 ? 'text-red' : 'text-green'" class="font-mono text-lg">
                            {{ so.total_difference > 0 ? '+' : '' }}{{ (so.total_difference || 0).toLocaleString('id-ID') }}
                        </td>
                        <td>
                            <span class="status-badge" :class="so.status">{{ so.status === 'completed' ? 'SELESAI' : 'DRAFT' }}</span>
                        </td>
                        <td class="text-right">
                            <button class="btn-lite-action" @click="viewStokTake(so)">Detail</button>
                        </td>
                        </tr>
                    </tbody>
                </table>
                <EmptyState 
                    v-else 
                    icon="ClipboardCheckIcon" 
                    title="Riwayat Masih Kosong" 
                    message="Belum ada riwayat stok opname yang tercatat di sistem."
                />
            </div>
          </div>
        </div>

        <!-- ACTIVE COUNT SCREEN -->
        <div v-else class="so-active-screen glass-panel animate-pop">
          <div class="so-header">
            <div class="sh-left">
              <h2 class="hero-font">Sesi Hitung Berjalan</h2>
              <p class="text-dim">Mencatat fisik butir telur di lapangan. Status: <span class="badge-draft">DRAFT</span></p>
            </div>
            <div class="sh-actions">
              <button class="btn-secondary" @click="activeStokTake = null" :disabled="submittingSO">Batal</button>
              <button class="btn-secondary-glow" @click="saveSODraft" :disabled="submittingSO">Simpan Draft</button>
              <button class="btn-primary-glow" @click="finalizeStokOpname" :disabled="submittingSO">
                Finalisasi & Sesuaikan Stok
              </button>
            </div>
          </div>

          <div class="so-table-wrapper mt-6">
            <table class="so-table">
              <thead>
                <tr>
                  <th>Produk</th>
                  <th>SKU</th>
                  <th>Sistem (Butir)</th>
                  <th>Hitungan Aktual</th>
                  <th>Selisih</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="item in activeSOItems" :key="item.id" class="so-row">
                  <td class="prod-info">
                    <span class="p-name">{{ item.product_label }}</span>
                  </td>
                  <td class="sku-cell">{{ (item.inventory_id || item.id).slice(0,8) }}</td>
                  <td class="sys-qty">{{ item.system_count }}</td>
                  <td class="count-cell">
                    <div class="count-input-wrapper">
                      <input 
                        type="number" 
                        v-model.number="item.physical_count" 
                        class="count-input"
                        @input="calculateDiff(item)"
                      />
                    </div>
                  </td>
                  <td class="diff-cell" :class="getDiffClass(item.difference)">
                    {{ item.difference > 0 ? '+' : '' }}{{ item.difference || 0 }}
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          
          <div class="so-summary-footer">
            <div class="summary-pill glass-panel">
              <span class="label">PRODUK SESUAI</span>
              <span class="val">{{ activeSOItems.filter(i => i.difference === 0).length }}</span>
            </div>
            <div class="summary-pill glass-panel">
              <span class="label">SURPLUS</span>
              <span class="val green">{{ activeSOItems.filter(i => i.difference > 0).length }}</span>
            </div>
            <div class="summary-pill glass-panel">
              <span class="label">KURANG</span>
              <span class="val red">{{ activeSOItems.filter(i => i.difference < 0).length }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>


    <!-- ADJUSTMENT MODAL -->
    <Teleport to="body">
      <div v-if="showAdjustmentModal" class="modal-overlay" @click.self="showAdjustmentModal = false">
        <div class="modal-card glass-panel animate-pop">
          <h2 class="hero-font">Koreksi & Input Stok</h2>
          <p class="text-dim">Mencatat barang masuk, sortir limbah, atau koreksi manual.</p>

          <form @submit.prevent="submitAdjustment" class="modal-form">
            <div class="form-group">
              <CustomDropdown 
                v-model="form.egg_type" 
                :options="eggTypeOptions" 
                label="Jenis Produk" 
                placeholder="Pilih produk..."
              />
            </div>

            <div class="form-group">
              <CustomDropdown 
                v-model="form.log_type" 
                :options="operationTypeOptions" 
                label="Tipe Operasi" 
                placeholder="Pilih tipe..."
              />
            </div>

            <div class="form-row">
              <div class="form-group">
                <label>Jumlah (Butir)</label>
                <input type="number" v-model.number="form.change" placeholder="Contoh: 100" required />
              </div>
              <div v-if="form.log_type === 'arrival'" class="form-group">
                <label>Pecah / Rusak</label>
                <input type="number" v-model.number="form.damaged" placeholder="Contoh: 5" />
              </div>
            </div>

            <div v-if="form.log_type === 'arrival'" class="form-group price-arrival-group animate-slide">
              <label>Harga Beli (Per Butir)</label>
              <div class="price-input-wrapper">
                <span class="prefix">Rp</span>
                <input type="number" v-model.number="form.purchase_price" placeholder="Contoh: 1500" />
              </div>
              <div v-if="suggestedPrices.length > 0" class="price-suggestions">
                <span class="s-hint">Dari katalog {{ form.supplier }}:</span>
                <div class="s-chips">
                  <button 
                    v-for="p in suggestedPrices" 
                    :key="p.item_name"
                    type="button"
                    class="price-chip"
                    @click="form.purchase_price = p.price"
                  >
                    {{ p.item_name }}: Rp {{ p.price }}
                  </button>
                </div>
              </div>
            </div>
            
            <div v-if="form.log_type === 'arrival' && form.purchase_price > 0" class="form-group info-box animate-slide">
              <label>Analisis Biaya & Potensi</label>
              <div class="financial-summary-grid">
                <div class="fs-item">
                  <span class="fs-label">HPP/Butir</span>
                  <span class="fs-val">Rp {{ (form.damaged > 0 ? calculateEffectiveEggCost() : form.purchase_price).toLocaleString('id-ID') }}</span>
                </div>
                <div class="fs-item">
                  <span class="fs-label">HPP/Pack (10 butir)</span>
                  <span class="fs-val">Rp {{ ((form.damaged > 0 ? calculateEffectiveEggCost() : form.purchase_price) * 10).toLocaleString('id-ID') }}</span>
                </div>
                <div class="fs-item">
                  <span class="fs-label">Harga Jual</span>
                  <span class="fs-val">Rp {{ (inventory.find(i => i.id === form.egg_type)?.base_price_per_pack || 0).toLocaleString('id-ID') }}</span>
                </div>
                <div class="fs-item highlight">
                  <span class="fs-label">Total Investasi</span>
                  <span class="fs-val">Rp {{ (form.change * form.purchase_price).toLocaleString('id-ID') }}</span>
                </div>
              </div>
              <p class="text-dim mini-text">Estimasi laba kotor: Rp {{ ((inventory.find(i => i.id === form.egg_type)?.base_price_per_pack || 0) - ((form.damaged > 0 ? calculateEffectiveEggCost() : form.purchase_price) * 10)).toLocaleString('id-ID') }} / pack</p>
              <p v-if="form.damaged > 0" class="text-dim mini-text" style="color: #ef4444;">⚠ HPP naik karena {{ form.damaged }} butir rusak, biaya diserap ke {{ form.change - form.damaged }} butir baik</p>
            </div>

            <!-- PAYMENT STATUS -->
            <div v-if="form.log_type === 'arrival'" class="form-group payment-status-group">
                <div class="toggle-row">
                    <label>Status Pembayaran</label>
                    <div class="toggle-buttons">
                        <button type="button" :class="{ active: form.isPaid }" @click="form.isPaid = true">LUNAS</button>
                        <button type="button" :class="{ active: !form.isPaid }" @click="form.isPaid = false">BELUM BAYAR (HUTANG)</button>
                    </div>
                </div>

                <div v-if="form.isPaid" class="form-group mt-3 animate-slide">
                    <CustomDropdown 
                        v-model="form.paidToAccountId" 
                        :options="bankAccountOptions" 
                        label="Gunakan Rekening" 
                        placeholder="Pilih bank..."
                    />
                </div>
                <div v-else class="form-group mt-3 animate-slide">
                    <label>Jatuh Tempo (Opsional)</label>
                    <input type="date" v-model="form.due_date" />
                </div>
            </div>

            <div class="form-group">
              <CustomDropdown 
                v-model="form.supplier" 
                :options="supplierOptions" 
                label="Supplier (Optional)" 
                placeholder="Select vendor..."
              />
            </div>

            <div class="form-group">
              <label>Notes</label>
              <textarea v-model="form.notes" placeholder="e.g. Batch from Blitar supplier"></textarea>
            </div>

            <div class="modal-actions">
              <button type="button" class="btn-secondary" @click="showAdjustmentModal = false">Cancel</button>
              <button type="submit" class="btn-primary" :disabled="submitting">
                {{ submitting ? 'RECORDING...' : 'SAVE CHANGES' }}
              </button>
            </div>
          </form>
        </div>
      </div>
    </Teleport>

    <!-- EDIT PRODUCT MODAL (HPP & PRICE) -->
    <Teleport to="body">
      <div v-if="showEditModal" class="modal-overlay" @click.self="showEditModal = false">
        <div class="modal-card glass-panel animate-pop">
          <h2 class="hero-font">Edit Product Specs</h2>
          <p class="text-dim">Update prices and costs for {{ editForm.label }}.</p>

          <form @submit.prevent="saveProductEdit" class="modal-form">
            <div class="form-row">
              <div class="form-group">
                <label>HPP Telur (Per Butir)</label>
                <input type="number" v-model.number="editForm.cost_per_egg" placeholder="e.g. 1500" required />
              </div>
              <div class="form-group">
                <div class="label-with-badge">
                  <label>HPP Kemasan</label>
                  <span class="badge-sync">AUTO-SYNC</span>
                </div>
                <input type="number" v-model.number="editForm.cost_per_packaging" readonly class="input-readonly" />
              </div>
            </div>

            <div class="form-row">
              <div class="form-group">
                <div class="label-with-badge">
                  <label>HPP Stiker</label>
                  <span class="badge-sync">AUTO-SYNC</span>
                </div>
                <input type="number" v-model.number="editForm.cost_per_sticker" readonly class="input-readonly" />
              </div>
              <div class="form-group">
                <div class="label-with-badge">
                  <label>HPP Kartu</label>
                  <span class="badge-sync">AUTO-SYNC</span>
                </div>
                <input type="number" v-model.number="editForm.cost_per_card" readonly class="input-readonly" />
              </div>
            </div>

            <div class="form-group info-box">
              <label>Estimasi HPP Total (Per 10 Butir)</label>
              <div class="calc-result">
                Rp {{ ((editForm.cost_per_egg * 10) + editForm.cost_per_packaging + editForm.cost_per_sticker + editForm.cost_per_card).toLocaleString() }}
              </div>
            </div>

            <div class="form-group">
              <label>Harga Jual / Retail (Per Pack)</label>
              <input type="number" v-model.number="editForm.base_price_per_pack" required />
            </div>

            <div class="form-group">
              <label>Reason for Change</label>
              <input type="text" v-model="editForm.reason" placeholder="e.g. Supplier price increase, Promo end..." />
            </div>

            <div class="form-group info-box mt-4">
              <div class="label-row-between">
                <label>Price Evolution History</label>
                <button type="button" class="btn-link-xs" @click="showFullHistory = true">Lihat semua riwayat →</button>
              </div>
              <div v-if="loadingHistory" class="text-dim mini-text">Loading records...</div>
              <div v-else-if="priceHistory.length === 0" class="text-dim mini-text">No price changes recorded.</div>
              <div v-else class="history-mini-list">
                <div v-for="ph in priceHistory" :key="ph.id" class="ph-row">
                  <div class="ph-main">
                    <span class="ph-type" :class="ph.price_type">{{ ph.price_type.toUpperCase() }}</span>
                    <div class="ph-details">
                      <span class="ph-old">Rp {{ ph.old_value?.toLocaleString('id-ID') }}</span>
                      <span class="ph-arr">
                        <TrendingUpIcon v-if="ph.new_value > ph.old_value" class="icon-xs text-green" />
                        <TrendingDownIcon v-else-if="ph.new_value < ph.old_value" class="icon-xs text-red" />
                        <span v-else>→</span>
                      </span>
                      <span class="ph-new">Rp {{ ph.new_value?.toLocaleString('id-ID') }}</span>
                    </div>
                  </div>
                  <div class="ph-meta">
                    <span class="ph-author">by {{ ph.changed_by }}</span>
                    <span class="ph-date text-dim">{{ formatDate(ph.changed_at) }}</span>
                  </div>
                </div>
              </div>
            </div>

            <div class="modal-actions">
              <button type="button" class="btn-secondary" @click="showEditModal = false">Cancel</button>
              <button type="submit" class="btn-primary" :disabled="submitting">
                {{ submitting ? 'SAVING...' : 'UPDATE SPECS' }}
              </button>
            </div>
          </form>
        </div>
      </div>
    </Teleport>

    <!-- PACKAGING PURCHASE MODAL -->
    <Teleport to="body">
      <div v-if="showPackagingModal" class="modal-overlay" @click.self="showPackagingModal = false">
        <div class="modal-card glass-panel animate-pop">
          <h2 class="hero-font">Restock Packaging</h2>
          <p class="text-dim">Calculate effective HPP including shipping and waste.</p>

          <form @submit.prevent="submitPackagingPurchase" class="modal-form">
            <div class="form-row">
              <div class="form-group">
                <label>Total Item Price</label>
                <input type="number" v-model.number="packForm.price" placeholder="e.g. 30000" required />
              </div>
              <div class="form-group">
                <label>Shipping Cost</label>
                <input type="number" v-model.number="packForm.shipping" placeholder="e.g. 5000" />
              </div>
            </div>

            <div class="form-row">
              <div class="form-group">
                <label>Quantity Ordered</label>
                <input type="number" v-model.number="packForm.qty" placeholder="30" required />
              </div>
              <div class="form-group">
                <label>Quantity Damaged</label>
                <input type="number" v-model.number="packForm.damaged" placeholder="0" />
              </div>
            </div>

            <div class="form-group">
              <CustomDropdown 
                v-model="packForm.supplier" 
                :options="supplierOptions" 
                label="Supplier (Optional)" 
                placeholder="Select vendor..."
              />
            </div>

            <div class="form-group info-box">
              <label>Effective HPP per Unit</label>
              <div class="calc-result">
                Rp {{ calculateEffectivePackCost().toLocaleString() }}
              </div>
              <p class="text-dim mini-text">Formula: (Price + Shipping) / (Total - Damaged)</p>
            </div>

            <div class="modal-actions">
              <button type="button" class="btn-secondary" @click="showPackagingModal = false">Cancel</button>
              <button type="submit" class="btn-primary" :disabled="submitting">
                {{ submitting ? 'PROCESSING...' : 'CONFIRM PURCHASE' }}
              </button>
            </div>
          </form>
        </div>
      </div>
    </Teleport>

    <!-- FULL HISTORY MODAL -->
    <StockHistoryModal 
      :show="showFullHistory" 
      :productId="editForm.id" 
      :productName="editForm.label"
      @close="showFullHistory = false"
    />
    <!-- CUSTOM CONFIRM MODAL -->
    <CustomConfirmModal 
      :modelValue="showConfirmModal"
      @update:modelValue="showConfirmModal = $event"
      :title="confirmData.title"
      :message="confirmData.message"
      @confirm="confirmData.onConfirm()"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, reactive, computed, watch } from 'vue';
import { supabase } from '../lib/supabase';
import { useAuthStore } from '../stores/auth';
import { useRoute } from 'vue-router';
import CustomDropdown from '../components/ui/CustomDropdown.vue';
import StockHistoryModal from '../components/modals/StockHistoryModal.vue';
import { 
  LockIcon,
  TruckIcon,
  ClipboardListIcon,
  PlusIcon,
  PackageIcon,
  ZapIcon,
  CookingPotIcon,
  Edit3Icon,
  AlertTriangleIcon,
  TrendingUpIcon,
  TrendingDownIcon,
  RefreshCwIcon
} from 'lucide-vue-next';

import SkeletonLoader from '../components/ui/SkeletonLoader.vue';
import EmptyState from '../components/ui/EmptyState.vue';
import CustomConfirmModal from '../components/ui/CustomConfirmModal.vue';
import { useToast } from '../composables/useToast';

const authStore = useAuthStore();
const { showToast } = useToast();

const inventory = ref<any[]>([]);
const activeTab = ref('inventory');
const opnameHistory = ref<any[]>([]);
const activeStokTake = ref<any>(null);
const activeSOItems = ref<any[]>([]);
const loading = ref(true);
const loadingSO = ref(false);
const submittingSO = ref(false);
const recalculating = ref(false);
const showFullHistory = ref(false);

const logs = ref<any[]>([]);
const suppliers = ref<any[]>([]);
const showAdjustmentModal = ref(false);
const showEditModal = ref(false);
const showPackagingModal = ref(false);
const showConfirmModal = ref(false);
const confirmData = reactive({
  title: '',
  message: '',
  onConfirm: () => {}
});
const submitting = ref(false);

const priceHistory = ref<any[]>([]);
const loadingHistory = ref(false);

// ━━━ PURCHASE & GRADING STATE ━━━
const purchases = ref<any[]>([]);
const gradings = ref<any[]>([]);
const purchaseForGrading = ref<any>(null);
const submittingPurchase = ref(false);
const submittingGrading = ref(false);

const purchaseForm = reactive({
  supplier_id: '',
  total_eggs: 0,
  price_per_egg: 0,
  amount_paid: 0,
  notes: ''
});

const gradingForm = reactive({
  hero_qty: 0,
  medium_qty: 0,
  small_qty: 0,
  notes: ''
});

const gradingTotal = computed(() => (gradingForm.hero_qty || 0) + (gradingForm.medium_qty || 0) + (gradingForm.small_qty || 0));
const gradingTotalValid = computed(() => purchaseForGrading.value && gradingTotal.value === purchaseForGrading.value.total_eggs_bought);

const eggSupplierOptions = computed(() => suppliers.value
  .filter(s => !s.is_deleted)
  .map(s => ({ label: `${s.name} ${s.category ? `(${s.category})` : ''}`, value: s.id }))
);

function purchaseHasGrading(purchaseId: string) {
  return gradings.value.some(g => g.purchase_id === purchaseId);
}

function startGradingFor(purchase: any) {
  purchaseForGrading.value = purchase;
  gradingForm.hero_qty = 0;
  gradingForm.medium_qty = 0;
  gradingForm.small_qty = 0;
  gradingForm.notes = '';
}

async function submitPurchase() {
  submittingPurchase.value = true;
  try {
    const { data, error } = await supabase.rpc('create_purchase_with_utang', {
      p_supplier_id: purchaseForm.supplier_id,
      p_total_eggs: purchaseForm.total_eggs,
      p_price_per_egg: purchaseForm.price_per_egg,
      p_amount_paid: purchaseForm.amount_paid || 0,
      p_notes: purchaseForm.notes || null
    });
    if (error) throw error;
    if (data?.error) { showToast(data.error, 'error'); return; }
    
    showToast('Pembelian dicatat! Lanjut ke grading...', 'success');
    
    // Fetch the created purchase and move to grading step
    const { data: newPurchase } = await supabase
      .from('purchases')
      .select('*')
      .eq('id', data.purchase_id)
      .single();
    
    if (newPurchase) {
      purchaseForGrading.value = newPurchase;
      gradingForm.hero_qty = 0;
      gradingForm.medium_qty = 0;
      gradingForm.small_qty = 0;
    }
    
    // Reset form
    purchaseForm.supplier_id = '';
    purchaseForm.total_eggs = 0;
    purchaseForm.price_per_egg = 0;
    purchaseForm.amount_paid = 0;
    purchaseForm.notes = '';
    
    await fetchPurchases();
  } catch (err: any) {
    showToast('Gagal menyimpan pembelian: ' + (err.message || ''), 'error');
  } finally {
    submittingPurchase.value = false;
  }
}

async function submitGrading() {
  submittingGrading.value = true;
  try {
    const { data, error } = await supabase.rpc('create_grading', {
      p_purchase_id: purchaseForGrading.value.id,
      p_hero_qty: gradingForm.hero_qty || 0,
      p_medium_qty: gradingForm.medium_qty || 0,
      p_small_qty: gradingForm.small_qty || 0,
      p_notes: gradingForm.notes || null
    });
    if (error) throw error;
    if (data?.error) { showToast(data.error, 'error'); return; }
    
    showToast(`Grading selesai! Hero: ${data.hero_added}, Medium: ${data.medium_added}, Small: ${data.small_added}`, 'success');
    purchaseForGrading.value = null;
    
    await fetchData();
    await fetchPurchases();
  } catch (err: any) {
    showToast('Gagal menyimpan grading: ' + (err.message || ''), 'error');
  } finally {
    submittingGrading.value = false;
  }
}

async function fetchPurchases() {
  const { data: pData } = await supabase.from('purchases').select('*').order('created_at', { ascending: false }).limit(50);
  if (pData) purchases.value = pData;
  const { data: gData } = await supabase.from('gradings').select('*');
  if (gData) gradings.value = gData;
}

const eggInventory = computed(() => inventory.value.filter(i => i.item_type !== 'packaging'));
const supplyInventory = computed(() => inventory.value.filter(i => i.item_type === 'packaging'));

const eggTypeOptions = computed(() => inventory.value
  .filter(item => item.item_type === 'egg')
  .map(item => ({
    label: item.label,
    value: item.id
  }))
);

const supplierOptions = computed(() => suppliers.value.map(s => ({
  label: `${s.name} ${s.category ? `(${s.category})` : ''}`,
  value: s.name
})));

const bankAccounts = ref<any[]>([]);
const bankAccountOptions = computed(() => bankAccounts.value.map(b => ({
  label: `${b.bank_name} - ${b.account_name} (Rp ${b.current_balance.toLocaleString('id-ID')})`,
  value: b.id
})));

const suggestedPrices = computed(() => {
  if (!form.supplier || !form.egg_type) return [];
  const supplier = suppliers.value.find(s => s.name === form.supplier);
  if (!supplier || !Array.isArray(supplier.price_list)) return [];
  
  // Filter price list for items matching current egg type label keywords
  const eggLabel = inventory.value.find(i => i.id === form.egg_type)?.label.toLowerCase() || '';
  return supplier.price_list.filter((item: any) => 
    item.item_name.toLowerCase().includes(eggLabel.split(' ')[0]) || 
    eggLabel.includes(item.item_name.toLowerCase().split(' ')[0])
  );
});


const operationTypeOptions = [
  { label: 'Barang Masuk (+)', value: 'arrival' },
  { label: 'Waste / Pecah (-)', value: 'sorting_waste' },
  { label: 'Koreksi Manual', value: 'manual_adjustment' }
];

const form = reactive({
  egg_type: 'hero_size',
  log_type: 'arrival',
  change: 0,
  damaged: 0,
  purchase_price: 0,
  supplier: '',
  notes: '',
  isPaid: true,
  paidToAccountId: '',
  due_date: ''
});


const editForm = reactive({
  id: '',
  label: '',
  base_price_per_pack: 0,
  cost_per_egg: 0,
  cost_per_packaging: 0,
  cost_per_sticker: 0,
  cost_per_card: 0,
  old_base_price: 0,
  old_cost_price: 0,
  reason: ''
});

const packForm = reactive({
  id: '',
  label: '',
  price: 0,
  shipping: 0,
  qty: 0,
  damaged: 0,
  supplier: ''
});

async function fetchData() {
  loading.value = true;
  try {
    const { data: inv } = await supabase.from('inventory').select('*').order('id');
    if (inv) inventory.value = inv;

    const { data: logData } = await supabase
      .from('stock_logs')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(20);
    if (logData) logs.value = logData;

    const { data: sup } = await supabase.from('suppliers').select('*').eq('is_deleted', false).order('name');
    if (sup) suppliers.value = sup;

    const { data: soData } = await supabase.from('stock_opname').select('*').order('opname_date', { ascending: false });
    if (soData) opnameHistory.value = soData;
    const { data: bAcc } = await supabase.from('bank_accounts').select('*').eq('is_active', true);
    if (bAcc) bankAccounts.value = bAcc;

    await fetchPurchases();
  } catch (err: any) {
    console.error('Error fetching inventory:', err);
    showToast('Gagal sinkronisasi data', 'error');
  } finally {
    loading.value = false;
  }
}

// ━━━ STOK OPNAME LOGIC ━━━
async function startNewStokOpname() {
  loadingSO.value = true;
  try {
    const { data: so, error } = await supabase
      .from('stock_opname')
      .insert({ 
        conducted_by: authStore.profile?.full_name || 'Admin',
        status: 'draft',
        opname_date: new Date().toISOString().split('T')[0]
      })
      .select()
      .single();
    
    if (error) throw error;
    
    // Snapshot current inventory
    const items = eggInventory.value.map(inv => ({
      opname_id: so.id,
      inventory_id: inv.id,
      grade: inv.grade || inv.label,
      system_count: inv.current_stock,
      physical_count: inv.current_stock, // default to system qty
      difference: 0,
      product_label: inv.label // for UI display
    }));

    const { error: itemError } = await supabase.from('stock_opname_items').insert(
      items.map(({ product_label, ...rest }) => rest)
    );
    if (itemError) throw itemError;

    activeStokTake.value = so;
    activeSOItems.value = items;
    showToast('Sesi stok opname dimulai');
  } catch (err: any) {
    showToast('Gagal memulai stok opname', 'error');
  } finally {
    loadingSO.value = false;
  }
}

function calculateDiff(item: any) {
  item.difference = (item.physical_count || 0) - item.system_count;
}

function getDiffClass(diff: number) {
  if (diff > 0) return 'text-green font-bold';
  if (diff < 0) return 'text-red font-bold';
  return 'text-dim';
}

async function saveSODraft() {
  submittingSO.value = true;
  try {
    const { error } = await supabase
      .from('stock_opname_items')
      .upsert(
        activeSOItems.value.map(i => ({
          opname_id: activeStokTake.value.id,
          inventory_id: i.inventory_id,
          grade: i.grade,
          system_count: i.system_count,
          physical_count: i.physical_count,
          difference: i.difference
        }))
      );
    if (error) throw error;
    showToast('Draft berhasil disimpan');
  } catch (err: any) {
    showToast('Gagal simpan draft', 'error');
  } finally {
    submittingSO.value = false;
  }
}

async function finalizeStokOpname() {
  confirmData.title = 'Finalisasi Stok Opname?';
  confirmData.message = 'Finalisasi akan menyesuaikan stok sistem dengan hasil hitungan. Lanjutkan?';
  confirmData.onConfirm = async () => {
    submittingSO.value = true;
    try {
      // 1. Update items in DB
      const { error: itemError } = await supabase
        .from('stock_opname_items')
        .upsert(
          activeSOItems.value.map(i => ({
            opname_id: activeStokTake.value.id,
            inventory_id: i.inventory_id,
            grade: i.grade,
            system_count: i.system_count,
            physical_count: i.physical_count,
            difference: i.difference
          }))
        );
      if (itemError) throw itemError;

      // 2. Update Inventory & Insert Logs for discrepancies
      for (const item of activeSOItems.value) {
        if (item.difference !== 0) {
          // Update Inventory
          await supabase
            .from('inventory')
            .update({ current_stock: item.physical_count })
            .eq('id', item.inventory_id);
          
          // Log Adjustment
          await supabase.from('stock_logs').insert({
            egg_type: item.inventory_id,
            change: item.difference,
            log_type: 'manual_adjustment',
            notes: `Stok Opname Adjustment (Ref: ${activeStokTake.value.id.slice(0,8)})`
          });
        }
      }

      // 3. Complete the Stock Take session
      const totalDiff = activeSOItems.value.reduce((acc, i) => acc + (i.difference || 0), 0);
      await supabase
        .from('stock_opname')
        .update({ 
          status: 'completed',
          total_difference: totalDiff,
          opname_date: new Date().toISOString().split('T')[0]
        })
        .eq('id', activeStokTake.value.id);

      showToast('Stok Opname Berhasil Difinalisasi');
      activeStokTake.value = null;
      fetchData();
    } catch (err: any) {
      showToast('Gagal finalisasi', 'error');
    } finally {
      submittingSO.value = false;
    }
  };
  showConfirmModal.value = true;
}

async function viewStokTake(so: any) {
  loadingSO.value = true;
  try {
    const { data: items, error } = await supabase
      .from('stock_opname_items')
      .select('*, inventory(label)')
      .eq('opname_id', so.id);
    
    if (error) throw error;
    
    activeSOItems.value = items.map(i => ({
      ...i,
      product_label: i.inventory?.label || 'Unknown'
    }));
    activeStokTake.value = { ...so, readonly: true };
  } catch (err: any) {
    showToast('Gagal memuat detail', 'error');
  } finally {
    loadingSO.value = false;
  }
}

function formatDate(date: any) {
  if (!date) return '-';
  return new Date(date).toLocaleDateString('id-ID', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  });
}


function formatTime(date: string) {
  return new Date(date).toLocaleString('id-ID', { 
    day: '2-digit', 
    month: 'short', 
    hour: '2-digit', 
    minute: '2-digit' 
  });
} // Added closing brace for formatTime

function formatLogNotes(notes: string) {
  if (!notes) return '-';
  // If note contains a UUID (sale #), slice it for cleaner UI
  return notes.replace(/#([a-f0-9-]{36})/, (_, id) => `#${id.slice(-8).toUpperCase()}`);
}

function quickAdjust(type: string) {
    form.egg_type = type;
    showAdjustmentModal.value = true;
}

function openEditProduct(item: any) {
  // Always fetch latest supply costs from supplyInventory to ensure sync
  const latestPackaging = supplyInventory.value.find(s => s.id === 'packaging_standard')?.cost_per_egg || 0;
  const latestSticker = supplyInventory.value.find(s => s.id === 'sticker_label')?.cost_per_egg || 0;
  const latestCard = supplyInventory.value.find(s => s.id === 'mini_card')?.cost_per_egg || 0;

  editForm.id = item.id;
  editForm.label = item.label;
  editForm.base_price_per_pack = item.base_price_per_pack;
  editForm.old_base_price = item.base_price_per_pack;
  editForm.old_cost_price = item.cost_price || 0;
  editForm.cost_per_egg = item.cost_per_egg || 0;
  
  // Use either the item's stored value or the latest from global supply list
  editForm.cost_per_packaging = latestPackaging || item.cost_per_packaging || 0;
  editForm.cost_per_sticker = latestSticker || item.cost_per_sticker || 0;
  editForm.cost_per_card = latestCard || item.cost_per_card || 0;
  
  showEditModal.value = true;
  
  // Fetch price history
  loadingHistory.value = true;
  priceHistory.value = [];
  supabase
    .from('price_history')
    .select('*')
    .eq('product_id', item.id)
    .order('changed_at', { ascending: false })
    .limit(5)
    .then(({ data }) => {
      if (data) priceHistory.value = data;
      loadingHistory.value = false;
    });
}

async function saveProductEdit() {
  submitting.value = true;
  const newCostPrice = (editForm.cost_per_egg * 10) + editForm.cost_per_packaging + editForm.cost_per_sticker + editForm.cost_per_card;

  const { error } = await supabase
    .from('inventory')
    .update({
      base_price_per_pack: editForm.base_price_per_pack,
      cost_per_egg: editForm.cost_per_egg,
      cost_per_packaging: editForm.cost_per_packaging,
      cost_per_sticker: editForm.cost_per_sticker,
      cost_per_card: editForm.cost_per_card,
      cost_price: newCostPrice,
      updated_at: new Date().toISOString()
    })
    .eq('id', editForm.id);

  if (!error) {
    // Audit Price Changes (Trigger will handle the session if we could set it, but we'll do it manually for reason)
    const authorName = authStore.profile?.full_name || 'Admin';
    if (editForm.base_price_per_pack !== editForm.old_base_price) {
      await supabase.from('price_history').insert({
        inventory_id: editForm.id,
        price_type: 'selling',
        old_value: editForm.old_base_price,
        new_value: editForm.base_price_per_pack,
        changed_by: authorName,
        reason: editForm.reason
      });
    }

    if (newCostPrice !== editForm.old_cost_price) {
      await supabase.from('price_history').insert({
        inventory_id: editForm.id,
        price_type: 'hpp',
        old_value: editForm.old_cost_price,
        new_value: newCostPrice,
        changed_by: authorName,
        reason: editForm.reason
      });
    }

    showToast('Spesifikasi produk diperbarui');
    showEditModal.value = false;
    editForm.reason = '';
    fetchData();
  } else {
    showToast('Gagal update spesifikasi', 'error');
  }
  submitting.value = false;
}

function openPackagingPurchase(item: any) {
  packForm.id = item.id;
  packForm.label = item.label;
  packForm.price = 0;
  packForm.shipping = 0;
  packForm.qty = 0;
  packForm.damaged = 0;
  packForm.supplier = '';
  showPackagingModal.value = true;
}

function calculateEffectivePackCost() {
  const totalCost = packForm.price + packForm.shipping;
  const goodQty = packForm.qty - packForm.damaged;
  if (goodQty <= 0) return 0;
  return Math.round(totalCost / goodQty);
}

async function submitPackagingPurchase() {
  submitting.value = true;
  const effectiveCost = calculateEffectivePackCost();
  const goodQty = packForm.qty - packForm.damaged;

  try {
    // 1. Update Packaging Inventory
    const currentItem = inventory.value.find(i => i.id === packForm.id);
    const newStock = (currentItem?.current_stock ?? 0) + goodQty;

    const { error: invError } = await supabase.from('inventory')
      .update({ 
        current_stock: newStock, 
        cost_per_egg: effectiveCost, // We use this field to store unit cost for supplies
        updated_at: new Date().toISOString() 
      })
      .eq('id', packForm.id);

    if (invError) throw invError;

    // 2. Log Transaction
    const purchaseNotes = `Purchase: Rp${packForm.price.toLocaleString('id-ID')} + Rp${packForm.shipping.toLocaleString('id-ID')} ship (Waste: ${packForm.damaged})`;
    const supplierNote = packForm.supplier ? ` | Supplier: ${packForm.supplier}` : '';

    await supabase.from('stock_logs').insert({
      egg_type: packForm.id,
      change: goodQty,
      log_type: 'arrival',
      notes: purchaseNotes + supplierNote
    });

    // Create Notification
    await supabase.from('notifications').insert({
      type: 'restock_done',
      title: 'Stok Diperbarui',
      message: `${packForm.label} ditambah ${goodQty} unit`,
      link: '/stock'
    });

    // 3. Proactive: Update Egg products HPP based on supply type
    if (packForm.id === 'packaging_standard') {
      await supabase.from('inventory').update({ cost_per_packaging: effectiveCost }).eq('item_type', 'egg');
    } else if (packForm.id === 'sticker_label') {
      await supabase.from('inventory').update({ cost_per_sticker: effectiveCost }).eq('item_type', 'egg');
    } else if (packForm.id === 'mini_card') {
      await supabase.from('inventory').update({ cost_per_card: effectiveCost }).eq('item_type', 'egg');
    }
    
    // Recalculate total cost_price for all eggs
    const { data: eggs } = await supabase.from('inventory').select('*').eq('item_type', 'egg');
    if (eggs) {
      for (const egg of eggs) {
        const totalHpp = (egg.cost_per_egg * 10) + (egg.cost_per_packaging || 0) + (egg.cost_per_sticker || 0) + (egg.cost_per_card || 0);
        await supabase.from('inventory').update({ cost_price: totalHpp }).eq('id', egg.id);
      }
    }

    showPackagingModal.value = false;
    fetchData();
    showToast(`Stok ${packForm.label} diperbarui & HPP telur dihitung ulang`);
  } catch (err: any) {
    showToast('Gagal restock packaging', 'error');
  } finally {
    submitting.value = false;
  }
}

async function recalculateAllHPP() {
  recalculating.value = true;
  try {
    const latestPackaging = supplyInventory.value.find(s => s.id === 'packaging_standard')?.cost_per_egg || 0;
    const latestSticker = supplyInventory.value.find(s => s.id === 'sticker_label')?.cost_per_egg || 0;
    const latestCard = supplyInventory.value.find(s => s.id === 'mini_card')?.cost_per_egg || 0;

    const { data: eggs, error: fetchError } = await supabase.from('inventory').select('*').eq('item_type', 'egg');
    if (fetchError) throw fetchError;

    if (eggs) {
      for (const egg of eggs) {
        const totalHpp = (egg.cost_per_egg * 10) + latestPackaging + latestSticker + latestCard;
        await supabase.from('inventory').update({
          cost_per_packaging: latestPackaging,
          cost_per_sticker: latestSticker,
          cost_per_card: latestCard,
          cost_price: totalHpp,
          updated_at: new Date().toISOString()
        }).eq('id', egg.id);
      }
    }
    await fetchData();
    showToast('Seluruh HPP Telur telah berhasil dihitung ulang!');
  } catch (err: any) {
    showToast('Gagal menghitung ulang HPP: ' + err.message, 'error');
  } finally {
    recalculating.value = false;
  }
}

function calculateEffectiveEggCost() {
  if (form.log_type !== 'arrival') return 0;
  const totalCost = form.change * form.purchase_price;
  const goodQty = form.change - (form.damaged || 0);
  if (goodQty <= 0) return 0;
  return Math.round(totalCost / goodQty);
}

async function submitAdjustment() {
  submitting.value = true;
  
  // 1. Determine direction
  let finalChange = form.change;
  let effectiveEggCost = form.purchase_price;
  let wasteAmount = form.damaged || 0;

  if (form.log_type === 'arrival') {
    if (wasteAmount > 0) {
      finalChange = form.change - wasteAmount; // actual good eggs added to inventory
      effectiveEggCost = calculateEffectiveEggCost(); // new HPP
    }
  } else if (form.log_type === 'sorting_waste' && finalChange > 0) {
    finalChange = -finalChange;
  }

  // 2. Insert Log
  const initialNotes = form.supplier ? `[${form.supplier}] ${form.notes}` : form.notes;
  let finalNotes = initialNotes;
  
  if (form.log_type === 'arrival' && wasteAmount > 0) {
    finalNotes = `${initialNotes} (Waste: ${wasteAmount} butir)`.trim();
  }

  const { data: logData, error: logError } = await supabase.from('stock_logs').insert({
    egg_type: form.egg_type,
    change: finalChange,
    log_type: form.log_type,
    unit_price: form.log_type === 'arrival' ? effectiveEggCost : 0,
    notes: finalNotes
  }).select();

    // Create Notification if it was a restock (arrival)
    if (!logError && form.log_type === 'arrival') {
      const productLabel = inventory.value.find(i => i.id === form.egg_type)?.label || 'Produk';
      await supabase.from('notifications').insert({
        type: 'restock_done',
        title: 'Stok Diperbarui',
        message: `${productLabel} ditambah ${finalChange} unit`,
        link: '/stock'
      });
    }


  if (!logError) {
    // 3. Update Inventory
    const currentItem = inventory.value.find(i => i.id === form.egg_type);
    const newStock = (currentItem?.current_stock ?? 0) + finalChange;
    
    const updatePayload: any = { 
      current_stock: newStock, 
      updated_at: new Date().toISOString() 
    };

    if (form.log_type === 'arrival' && form.purchase_price > 0 && currentItem) {
      updatePayload.cost_per_egg = effectiveEggCost;
      updatePayload.cost_price = (effectiveEggCost * 10) + 
        (currentItem.cost_per_packaging || 0) + 
        (currentItem.cost_per_sticker || 0) + 
        (currentItem.cost_per_card || 0);
    }

    await supabase.from('inventory').update(updatePayload).eq('id', form.egg_type);

    // 4. Handle Financial Depth (Debt vs Bank)
    if (form.log_type === 'arrival' && form.purchase_price > 0) {
      // Find the finance entry created by trigger (if exists) or create manually
      // Since the trigger auto-creates it, let's find it and update it
      const totalAmount = form.change * form.purchase_price;
      
      const { data: fe } = await supabase
        .from('finance_entries')
        .select('*')
        .eq('reference_id', logData[0].id)
        .single();
      
      if (fe) {
        await supabase.from('finance_entries').update({
          payment_status: form.isPaid ? 'paid' : 'unpaid',
          due_date: form.isPaid ? null : (form.due_date || null)
        }).eq('id', fe.id);

        if (form.isPaid && form.paidToAccountId) {
          // Record Bank Transaction
          const { data: bank } = await supabase.from('bank_accounts').select('current_balance').eq('id', form.paidToAccountId).single();
          if (bank) {
              const newBalance = bank.current_balance - totalAmount;
              await supabase.from('bank_transactions').insert({
                bank_account_id: form.paidToAccountId,
                transaction_type: 'keluar',
                amount: totalAmount,
                description: `Restock: ${currentItem?.label || 'Produk'}`,
                reference_type: 'restock',
                reference_id: logData[0].id,
                balance_after: newBalance
              });
              await supabase.from('bank_accounts').update({ current_balance: newBalance }).eq('id', form.paidToAccountId);
          }
        }
      }
    }

    showAdjustmentModal.value = false;
    // Reset form
    form.change = 0;
    form.damaged = 0;
    form.purchase_price = 0;
    form.isPaid = true;
    form.paidToAccountId = '';
    form.due_date = '';
    form.supplier = '';
    form.notes = '';
    fetchData();
    showToast('Stock recording successful');
  }
}

const route = useRoute();

let refreshInterval: any;

onMounted(() => {
  fetchData();
  fetchPurchases();
  refreshInterval = setInterval(() => {
    fetchData();
    fetchPurchases();
  }, 10000);
});

onUnmounted(() => {
  clearInterval(refreshInterval);
});

// Force refresh data on route change
watch(() => route.path, () => {
  fetchData();
});
</script>

<style scoped>
.stock-page {
  display: flex;
  flex-direction: column;
  gap: 32px;
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
}

.brand-tag {
  color: var(--color-primary);
  letter-spacing: 0.2em;
  font-size: 0.75rem;
  margin-bottom: 8px;
}

.text-dim { color: var(--color-text-dim); }

.label-with-badge {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.badge-sync {
  font-size: 0.6rem;
  background: var(--color-success);
  color: black;
  padding: 2px 6px;
  border-radius: 4px;
  font-weight: 800;
  letter-spacing: 0.05em;
}

.input-readonly {
  background: rgba(255, 255, 255, 0.02) !important;
  color: var(--color-text-dim) !important;
  cursor: not-allowed;
  border-style: dashed !important;
}

.section-header-flex {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
}

.section-badge {
  font-family: var(--font-headline);
  font-size: 0.7rem;
  font-weight: 800;
  color: var(--color-primary);
  letter-spacing: 0.15em;
  background: rgba(255, 140, 0, 0.1);
  padding: 4px 12px;
  border-radius: 20px;
  width: fit-content;
  border: 1px solid rgba(255, 140, 0, 0.2);
}

.mini-text {
  font-size: 0.7rem;
  margin-top: 8px;
}

.btn-primary-lite {
  background: var(--color-primary);
  color: white;
  padding: 6px 12px;
  border-radius: var(--radius-sm);
  font-size: 0.8rem;
  font-weight: 700;
  display: flex;
  align-items: center;
  gap: 6px;
  cursor: pointer;
  border: none;
  transition: var(--transition-smooth);
}

.btn-primary-lite:hover {
  transform: translateY(-2px);
  box-shadow: var(--shadow-glow);
}

.supply-card .stock-value {
  color: var(--color-success);
}

.stock-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(450px, 1fr));
  gap: 32px;
}

.stock-card {
  min-height: 380px;
  padding: 0;
  position: relative;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid var(--glass-border);
  border-radius: 24px;
  backdrop-filter: blur(12px);
  transition: all 0.4s cubic-bezier(0.23, 1, 0.32, 1);
}

.stock-card:hover {
  transform: translateY(-8px);
  border-color: rgba(255, 140, 0, 0.3);
  box-shadow: 0 15px 40px rgba(0,0,0,0.4);
}

.stock-card.low-stock {
  border-color: rgba(255, 66, 66, 0.2);
}

.card-bg-icon {
  position: absolute;
  right: -20px;
  top: -20px;
  opacity: 0.03;
  color: white;
  z-index: 1;
}

.card-bg-icon svg {
  width: 180px;
  height: 180px;
}

.card-content {
  position: relative;
  z-index: 2;
  padding: 32px;
  flex: 1;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
}

.top {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.label {
  text-transform: uppercase;
  font-weight: 900;
  letter-spacing: 0.15em;
  font-size: 0.7rem;
  color: var(--color-text-dim);
}

.pulsing-badge {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 4px 10px;
  border-radius: 20px;
  font-size: 0.6rem;
  font-weight: 800;
  letter-spacing: 0.05em;
}

.pulsing-badge.critical {
  background: rgba(255, 66, 66, 0.1);
  color: #ff4242;
  animation: pulse-red 2s infinite;
}

.pulsing-badge.safe {
  background: rgba(0, 255, 157, 0.05);
  color: var(--color-success);
}

.pulsing-badge.safe .dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: var(--color-success);
  box-shadow: 0 0 8px var(--color-success);
}

.main {
  margin: 20px 0;
}

.stock-value {
  display: flex;
  align-items: baseline;
  gap: 12px;
  margin-bottom: 16px;
}

.v-num {
  font-size: 4rem;
  font-weight: 900;
  line-height: 1;
  color: white;
  letter-spacing: -2px;
}

.v-unit {
  font-size: 1rem;
  color: var(--color-text-dim);
  font-weight: 600;
}

.stock-value.supply .v-num { color: var(--color-success); }

.price-info {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  align-items: flex-end;
}

.margin-tag {
  display: flex;
  flex-direction: column;
  padding: 6px 12px;
  border-radius: 10px;
  background: rgba(16, 185, 129, 0.08);
  border: 1px solid rgba(16, 185, 129, 0.2);
}

.margin-tag.low {
  background: rgba(239, 68, 68, 0.08);
  border-color: rgba(239, 68, 68, 0.2);
}

.mt-label { font-size: 0.55rem; text-transform: uppercase; color: var(--color-text-dim); font-weight: 800; }
.margin-tag.good .mt-val { font-size: 0.85rem; font-weight: 900; color: #10b981; }
.margin-tag.low .mt-val { font-size: 0.85rem; font-weight: 900; color: #ef4444; }

.retail-tag {
  display: flex;
  flex-direction: column;
}

.rt-label { font-size: 0.6rem; text-transform: uppercase; color: var(--color-primary); font-weight: 800; }
.rt-val { font-size: 1.1rem; font-weight: 850; color: white; }

.hpp-glass {
  padding: 10px 14px;
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid rgba(255, 255, 255, 0.05);
  border-radius: 12px;
  display: flex;
  align-items: center;
  gap: 12px;
  backdrop-filter: blur(5px);
}

.hpp-glass svg { opacity: 0.3; }

.hpp-inner { display: flex; flex-direction: column; }
.hpp-label { font-size: 0.55rem; text-transform: uppercase; color: var(--color-text-dim); font-weight: 800; }
.hpp-val { font-size: 0.85rem; font-weight: 800; color: white; }

.hpp-glass.supply .hpp-val { color: var(--color-primary); }

.card-footer-elite {
  margin-top: auto;
  padding-top: 20px;
  border-top: 1px solid var(--glass-border);
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.mini-stat { display: flex; flex-direction: column; }
.ms-label { font-size: 0.6rem; color: var(--color-text-dim); text-transform: uppercase; }
.ms-value { font-weight: 800; font-size: 0.9rem; color: white; }

.card-actions { display: flex; display: flex; gap: 12px; }

.btn-icon-circle {
  width: 38px;
  height: 38px;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid var(--glass-border);
  color: var(--color-text-dim);
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.3s ease;
}

.btn-icon-circle:hover {
  background: white;
  color: black;
  transform: rotate(15deg);
}

.btn-tactical {
  background: var(--color-primary);
  color: black;
  border: none;
  padding: 10px 18px;
  border-radius: 12px;
  font-weight: 900;
  font-size: 0.75rem;
  letter-spacing: 0.05em;
  cursor: pointer;
  transition: all 0.3s ease;
}

.btn-tactical:hover {
  transform: scale(1.05);
  box-shadow: 0 0 20px rgba(255, 140, 0, 0.3);
}

.btn-primary-tactical {
  background: var(--color-success);
  color: black;
  border: none;
  padding: 10px 18px;
  border-radius: 12px;
  font-weight: 900;
  font-size: 0.75rem;
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  transition: all 0.3s ease;
}

.btn-primary-tactical:hover {
  transform: scale(1.05);
  box-shadow: 0 0 20px rgba(0, 255, 157, 0.3);
}

@keyframes pulse-red {
  0% { box-shadow: 0 0 0 0 rgba(255, 66, 66, 0.4); }
  70% { box-shadow: 0 0 0 10px rgba(255, 66, 66, 0); }
  100% { box-shadow: 0 0 0 0 rgba(255, 66, 66, 0); }
}

.btn-lite {
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid var(--glass-border);
  color: white;
  padding: 6px 12px;
  border-radius: var(--radius-sm);
  font-size: 0.8rem;
  cursor: pointer;
  transition: var(--transition-smooth);
}

.btn-lite:hover { background: rgba(255, 255, 255, 0.1); }

.btn-secondary-xs {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 6px 12px;
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 8px;
  color: var(--color-text-dim);
  font-size: 0.65rem;
  font-weight: 800;
  cursor: pointer;
  transition: all 0.3s ease;
}

.btn-secondary-xs:hover:not(:disabled) {
  background: rgba(255, 255, 255, 0.08);
  border-color: rgba(255, 255, 255, 0.2);
  color: white;
  transform: translateY(-1px);
}

.btn-secondary-xs:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.animate-spin {
  animation: spin 1s linear infinite;
}

@keyframes spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}

/* LOGS TABLE */
.retail-tag.clickable {
  cursor: pointer;
  background: rgba(255, 140, 0, 0.1);
  border: 1px dashed rgba(255, 140, 0, 0.3);
  transition: all 0.3s ease;
}

.retail-tag.clickable:hover {
  background: var(--color-primary);
  color: black;
  transform: scale(1.05);
  border-style: solid;
}

/* Price Arrival Group */
.price-arrival-group {
  margin-top: 8px;
  padding: 16px;
  background: rgba(255, 140, 0, 0.05);
  border-radius: 12px;
  border: 1px solid rgba(255, 140, 0, 0.1);
}

.price-input-wrapper {
  display: flex;
  align-items: center;
  background: rgba(0, 0, 0, 0.2);
  border: 1px solid var(--glass-border);
  border-radius: 8px;
  padding: 0 12px;
}

.price-input-wrapper .prefix {
  font-weight: 800;
  color: var(--color-primary);
  margin-right: 8px;
}

.price-input-wrapper input {
  border: none !important;
  background: transparent !important;
  padding: 12px 0 !important;
}

.price-suggestions {
  margin-top: 12px;
}

.s-hint {
  font-size: 0.65rem;
  font-weight: 800;
  text-transform: uppercase;
  color: var(--color-text-dim);
  display: block;
  margin-bottom: 8px;
}

.s-chips {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.price-chip {
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid var(--glass-border);
  color: white;
  padding: 6px 12px;
  border-radius: 20px;
  font-size: 0.7rem;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.2s ease;
}

.price-chip:hover {
  background: var(--color-primary);
  color: black;
  border-color: var(--color-primary);
}

.animate-slide {
  animation: slideDown 0.3s cubic-bezier(0.23, 1, 0.32, 1);
}

@keyframes slideDown {
  from { opacity: 0; transform: translateY(-10px); }
  to { opacity: 1; transform: translateY(0); }
}

.logs-section {

  padding: 32px;
}

.section-header { margin-bottom: 24px; }

.logs-table-wrapper {
  overflow-x: auto;
}

.logs-table {
  width: 100%;
  border-collapse: separate;
  border-spacing: 0 8px;
  margin-top: -8px;
}

.logs-table th {
  text-align: left;
  padding: 12px 20px;
  color: var(--color-text-dim);
  font-size: 0.7rem;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  border: none;
}

.logs-table td {
    padding: 20px;
    background: rgba(255, 255, 255, 0.02);
    border-top: 1px solid rgba(255, 255, 255, 0.03);
    border-bottom: 1px solid rgba(255, 255, 255, 0.03);
}

.logs-table td:first-child {
    border-left: 1px solid rgba(255, 255, 255, 0.03);
    border-radius: 12px 0 0 12px;
}

.logs-table td:last-child {
    border-right: 1px solid rgba(255, 255, 255, 0.03);
    border-radius: 0 12px 12px 0;
}

.log-row {
    transition: all 0.3s ease;
}

.log-row:hover td {
    background: rgba(255, 255, 255, 0.05);
    color: white;
}

.log-badge {
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 0.7rem;
  font-weight: 700;
  text-transform: uppercase;
}

.log-badge.arrival { background: rgba(0, 255, 157, 0.1); color: var(--color-success); }
.log-badge.sorting_waste { background: rgba(255, 62, 62, 0.1); color: var(--color-error); }
.log-badge.manual_adjustment { background: rgba(255, 140, 0, 0.1); color: var(--color-primary); }

.change { font-weight: 800; }
.change.pos { color: var(--color-success); }
.change.neg { color: var(--color-error); }

.note-text {
  color: white;
  font-weight: 500;
}

/* MODAL */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0, 0, 0, 0.8);
  backdrop-filter: blur(8px);
  display: flex;
  justify-content: center;
  align-items: flex-start;
  padding: 40px 20px;
  overflow-y: auto;
  z-index: 1000;
}

.modal-card {
  width: 100%;
  max-width: 500px;
  padding: 40px;
  margin: auto;
}

.modal-form {
  margin-top: 24px;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.form-group label {
  font-size: 0.8rem;
  font-weight: 700;
  color: var(--color-text-dim);
  text-transform: uppercase;
}

.history-mini-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin-top: 8px;
  background: rgba(0, 0, 0, 0.2);
  border-radius: 8px;
  padding: 8px;
}

.ph-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 6px 8px;
  border-bottom: 1px dashed var(--glass-border);
  font-size: 0.75rem;
}

.ph-row:last-child {
  border-bottom: none;
}

.ph-type {
  font-weight: 800;
  padding: 2px 6px;
  border-radius: 4px;
  font-size: 0.6rem;
}

.ph-type.selling { background: rgba(0, 255, 157, 0.1); color: var(--color-success); }
.ph-type.hpp { background: rgba(255, 140, 0, 0.1); color: var(--color-primary); }

.ph-details {
  display: flex;
  align-items: center;
  gap: 8px;
}

.ph-old { text-decoration: line-through; color: var(--color-error); }
.ph-arr { color: var(--color-text-dim); }
.ph-new { color: white; font-weight: 700; }
.ph-date { font-size: 0.6rem; }


.form-group select, .form-group input, .form-group textarea {
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid var(--glass-border);
  padding: 12px;
  border-radius: var(--radius-sm);
  color: white;
  font-family: var(--font-body);
}

.modal-actions {
  display: flex;
  justify-content: flex-end;
  gap: 16px;
  margin-top: 12px;
}

.btn-secondary {
  background: transparent;
  border: 1px solid var(--glass-border);
  color: white;
  padding: 12px 24px;
  border-radius: var(--radius-sm);
  cursor: pointer;
}

.animate-pop {
  animation: popIn 0.4s cubic-bezier(0.23, 1, 0.32, 1);
}

/* ━━━ REFINED PURCHASE FORM ━━━ */
.purchase-form-header {
  margin-bottom: 24px;
}

.input-group-premium {
  display: flex;
  align-items: center;
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 12px;
  padding: 0 16px;
  transition: all 0.2s ease;
}

.input-group-premium:focus-within {
  border-color: var(--color-primary);
  background: rgba(255, 255, 255, 0.08);
}

.input-group-premium input {
  flex: 1;
  background: transparent !important;
  border: none !important;
  padding: 14px 0 !important;
  font-weight: 600;
  font-size: 1rem;
  color: white;
}

.prefix {
  font-weight: 800;
  color: var(--color-primary);
  margin-right: 12px;
}

.suffix {
  font-weight: 800;
  color: var(--color-text-dim);
  font-size: 0.7rem;
  margin-left: 12px;
}

.order-summary-box {
  background: rgba(255, 140, 0, 0.05);
  border: 1px solid rgba(255, 140, 0, 0.2);
  border-radius: 16px;
  padding: 20px;
  margin-top: 10px;
}

.summary-line {
  display: flex;
  justify-content: space-between;
  margin-bottom: 8px;
  font-size: 0.9rem;
  color: var(--color-text-dim);
}

.summary-line.highlight {
  font-weight: 800;
  color: white;
  margin-top: 12px;
  padding-top: 12px;
  border-top: 1px dashed rgba(255, 255, 255, 0.1);
}

.summary-line .val {
  color: white;
  font-weight: 700;
}

.btn-primary-action {
  width: 100%;
  background: var(--color-primary);
  color: black;
  border: none;
  padding: 16px;
  border-radius: 12px;
  font-weight: 900;
  font-size: 0.9rem;
  cursor: pointer;
  transition: all 0.2s ease;
  margin-top: 10px;
}

.btn-primary-action:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 5px 15px rgba(255, 140, 0, 0.3);
}

.btn-primary-action:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.form-footer-actions {
  margin-top: 24px;
}

.flex-1 { flex: 1; }

/* ━━━ TAB SYSTEM ━━━ */
.tab-nav {
  display: flex;
  gap: 12px;
  padding: 8px;
  background: rgba(255, 255, 255, 0.02);
  border-radius: 16px;
  margin-bottom: 24px;
}

.tab-btn {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  padding: 14px;
  background: transparent;
  border: 1px solid transparent;
  border-radius: 12px;
  color: var(--color-text-dim);
  font-family: var(--font-headline);
  font-weight: 700;
  font-size: 0.9rem;
  cursor: pointer;
  transition: all 0.3s cubic-bezier(0.23, 1, 0.32, 1);
}

.tab-btn.active {
  background: rgba(255, 140, 0, 0.05);
  border-color: rgba(255, 140, 0, 0.2);
  color: var(--color-primary);
  box-shadow: inset 0 0 20px rgba(255, 140, 0, 0.05);
}

.tab-btn:hover:not(.active) {
  background: rgba(255, 255, 255, 0.04);
  color: white;
}

.animate-fade {
  animation: fadeIn 0.4s ease-out;
}

@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

/* ━━━ STOK OPNAME UI ━━━ */
.stok-opname-layout {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.so-dashboard.elite-hub {
  padding: 48px;
  background: radial-gradient(circle at top right, rgba(255, 140, 0, 0.05), transparent 40%),
              rgba(255, 255, 255, 0.01);
}

.so-header-premium {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-bottom: 32px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.05);
  margin-bottom: 40px;
}

.hub-title {
  font-size: 2.2rem;
  letter-spacing: -0.02em;
  background: linear-gradient(to right, #fff, rgba(255,255,255,0.7));
  -webkit-background-clip: text;
  background-clip: text;
  -webkit-text-fill-color: transparent;
  margin-bottom: 8px;
}

.hub-desc {
  font-size: 1rem;
  max-width: 500px;
}

.btn-hub-primary {
  background: linear-gradient(135deg, var(--color-primary) 0%, #ff8c00 100%);
  color: black;
  border: none;
  padding: 14px 28px;
  border-radius: 16px;
  font-weight: 900;
  font-size: 0.85rem;
  display: flex;
  align-items: center;
  gap: 12px;
  cursor: pointer;
  transition: all 0.4s cubic-bezier(0.23, 1, 0.32, 1);
  box-shadow: 0 10px 30px rgba(255, 140, 0, 0.2);
}

.btn-hub-primary:hover {
  transform: translateY(-4px) scale(1.02);
  box-shadow: 0 15px 40px rgba(255, 140, 0, 0.3);
}

.section-title-wrapper {
    display: flex;
    align-items: center;
    gap: 16px;
}

.section-label-elite {
    font-size: 0.9rem;
    font-weight: 800;
    text-transform: uppercase;
    letter-spacing: 0.15em;
    color: white;
}

.accent-line {
    flex: 1;
    height: 1px;
    background: linear-gradient(to right, rgba(255, 255, 255, 0.1), transparent);
}

.btn-lite-action {
    background: rgba(255, 255, 255, 0.05);
    border: 1px solid rgba(255, 255, 255, 0.1);
    color: rgba(255, 255, 255, 0.8);
    padding: 8px 16px;
    border-radius: 10px;
    font-size: 0.75rem;
    font-weight: 700;
    cursor: pointer;
    transition: all 0.3s ease;
}

.btn-lite-action:hover {
    background: white;
    color: black;
    border-color: white;
}

.v-middle td {
    vertical-align: middle;
}

.sh-actions {
  display: flex;
  gap: 12px;
}

.so-table {
  width: 100%;
  border-collapse: collapse;
}

.so-table th {
  text-align: left;
  padding: 16px;
  color: var(--color-text-dim);
  font-size: 0.75rem;
  text-transform: uppercase;
  background: rgba(255, 255, 255, 0.02);
}

.so-row td {
  padding: 16px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.03);
}

.count-input-wrapper {
  max-width: 120px;
}

.count-input {
  width: 100%;
  background: rgba(255, 140, 0, 0.05) !important;
  border: 1px solid rgba(255, 140, 0, 0.2) !important;
  padding: 10px !important;
  color: white !important;
  font-weight: 800 !important;
  text-align: center;
  border-radius: 8px !important;
}

.diff-cell {
  font-family: 'JetBrains Mono', monospace;
  font-size: 1.1rem;
}

.so-summary-footer {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 16px;
  margin-top: 24px;
}

.summary-pill {
  padding: 20px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  text-align: center;
}

.summary-pill .label {
  font-size: 0.65rem;
  letter-spacing: 0.1em;
  color: var(--color-text-dim);
}

.summary-pill .val {
  font-size: 2rem;
  font-weight: 900;
}

.status-badge {
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 0.65rem;
  font-weight: 800;
}

.status-badge.draft { background: rgba(255, 255, 255, 0.1); color: var(--color-text-dim); }
.status-badge.completed { background: rgba(0, 255, 157, 0.1); color: var(--color-success); }

.badge-draft {
  background: rgba(255, 255, 255, 0.1);
  padding: 2px 8px;
  border-radius: 4px;
  font-size: 0.7rem;
  font-weight: 800;
}

.btn-secondary-glow {
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid var(--glass-border);
  color: white;
  padding: 10px 20px;
  border-radius: 12px;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.3s ease;
}

.btn-secondary-glow:hover {
  background: rgba(255, 255, 255, 0.1);
  box-shadow: 0 0 20px rgba(255, 255, 255, 0.1);
}

.btn-primary-glow {
  background: var(--color-primary);
  color: black;
  border: none;
  padding: 10px 24px;
  border-radius: 12px;
  font-weight: 800;
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 0 0 30px rgba(255, 140, 0, 0.2);
}

.btn-primary-glow:hover {
  transform: translateY(-2px);
  box-shadow: 0 0 40px rgba(255, 140, 0, 0.4);
}

/* ━━━ PRICE HISTORY STYLES ━━━ */
.label-row-between {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.btn-link-xs {
  background: transparent;
  border: none;
  color: var(--color-primary);
  font-size: 0.65rem;
  font-weight: 800;
  cursor: pointer;
  padding: 0;
  opacity: 0.7;
  transition: opacity 0.2s ease;
}

.btn-link-xs:hover { opacity: 1; text-decoration: underline; }

.history-mini-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
  margin-top: 12px;
}

.ph-row {
  display: flex;
  flex-direction: column;
  gap: 6px;
  padding: 10px;
  background: rgba(255, 255, 255, 0.02);
  border-radius: 8px;
  border-left: 3px solid transparent;
}

.ph-row:has(.ph-type.selling) { border-left-color: var(--color-success); }
.ph-row:has(.ph-type.hpp) { border-left-color: var(--color-primary); }

.ph-main {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.ph-meta {
  display: flex;
  justify-content: space-between;
  font-size: 0.65rem;
  color: var(--color-text-dim);
}

.ph-author { font-weight: 700; color: rgba(255, 255, 255, 0.5); }

.icon-xs { width: 12px; height: 12px; }

.text-red { color: var(--color-error); }

/* Financial Summary Grid */
.financial-summary-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 12px;
  margin-top: 12px;
}

.fs-item {
  display: flex;
  flex-direction: column;
  gap: 4px;
  padding: 10px;
  background: rgba(255, 255, 255, 0.03);
  border-radius: 12px;
  border: 1px solid rgba(255, 255, 255, 0.05);
}

.fs-item.highlight {
  background: rgba(255, 140, 0, 0.1);
  border-color: rgba(255, 140, 0, 0.2);
}

.fs-label {
  font-size: 0.6rem;
  color: var(--color-text-dim);
  text-transform: uppercase;
  font-weight: 800;
}

.fs-val {
  font-size: 0.9rem;
  font-weight: 900;
  color: white;
}

.fs-item.highlight .fs-val {
  color: var(--color-primary);
}

/* Payment Status Toggle */
.payment-status-group {
  margin-top: 24px;
  padding: 20px;
  background: rgba(255, 255, 255, 0.02);
  border: 1px solid var(--glass-border);
  border-radius: 16px;
}

.toggle-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.toggle-buttons {
  display: flex;
  background: rgba(0, 0, 0, 0.2);
  padding: 4px;
  border-radius: 12px;
  gap: 4px;
}

.toggle-buttons button {
  padding: 8px 16px;
  border: none;
  background: transparent;
  color: var(--color-text-dim);
  font-size: 0.7rem;
  font-weight: 800;
  cursor: pointer;
  border-radius: 8px;
  transition: all 0.3s ease;
}

.toggle-buttons button.active {
  background: var(--color-primary);
  color: black;
}

/* ━━━ PURCHASE & GRADING SECTION ━━━ */
.purchase-layout {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.grading-cards {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 16px;
  margin-bottom: 24px;
}

.grading-card {
  padding: 24px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16px;
  text-align: center;
  transition: all 0.3s ease;
}

.grading-card:hover {
  transform: translateY(-5px);
  background: rgba(255, 255, 255, 0.05);
}

.gc-header {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
}

.gc-badge {
  padding: 4px 12px;
  border-radius: 20px;
  font-size: 0.75rem;
  font-weight: 900;
}

.gc-badge.hero { background: var(--color-primary); color: black; }
.gc-badge.medium { background: #4ecdc4; color: black; }
.gc-badge.small { background: #ff6b6b; color: black; }

.gc-rule {
  font-size: 0.65rem;
  font-weight: 800;
  color: var(--color-text-dim);
}

.gc-input {
  width: 100% !important;
  font-size: 1.8rem !important;
  text-align: center !important;
  font-weight: 900 !important;
  background: rgba(0, 0, 0, 0.3) !important;
  border-color: rgba(255, 255, 255, 0.1) !important;
}

.gc-unit {
  font-size: 0.7rem;
  font-weight: 800;
  color: var(--color-text-dim);
  text-transform: uppercase;
}

.grading-validation {
  padding: 16px 24px;
  border-radius: 16px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-weight: 800;
  font-size: 1rem;
  transition: all 0.3s ease;
  margin-bottom: 24px;
}

.grading-validation.invalid {
  background: rgba(255, 62, 62, 0.1);
  border: 1px solid rgba(255, 62, 62, 0.2);
  color: var(--color-error);
}

.grading-validation.valid {
  background: rgba(0, 255, 157, 0.1);
  border: 1px solid rgba(0, 255, 157, 0.2);
  color: var(--color-success);
}

.check-text { display: flex; align-items: center; gap: 8px; }
.warning-text { font-size: 0.8rem; opacity: 0.8; }

.status-badge {
  text-transform: uppercase;
  font-size: 0.65rem;
  font-weight: 900;
  padding: 4px 10px;
  border-radius: 6px;
}

.status-badge.lunas { background: rgba(0, 255, 157, 0.1); color: var(--color-success); }
.status-badge.cicilan { background: rgba(255, 140, 0, 0.1); color: var(--color-primary); }
.status-badge.utang { background: rgba(255, 62, 62, 0.1); color: var(--color-error); }

.red-highlight {
  background: rgba(255, 62, 62, 0.1) !important;
  border-color: rgba(255, 62, 62, 0.2) !important;
}

.red-highlight .fs-val {
  color: var(--color-error) !important;
}

@media (max-width: 768px) {
  .grading-cards {
    grid-template-columns: 1fr;
  }
}
</style>
