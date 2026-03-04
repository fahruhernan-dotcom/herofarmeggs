<template>
  <div class="stock-page">
    <header v-if="!isMobile" class="header desktop-only">
      <div class="header-left">
        <h4 class="brand-tag">B2B LOGISTICS</h4>
        <h1 class="hero-font">Manajemen Stok</h1>
        <p class="text-dim">Monitoring inventory & input barang datang.</p>
      </div>
      <div class="header-actions">
        <button class="btn-primary" @click="showChoiceModal = true" :disabled="loading">
          <PlusIcon class="icon" />
          <span>TAMBAH STOK BARU</span>
        </button>
      </div>
    </header>

    <!-- Mobile Actions Bar (only buttons, title is in TopBar) -->
    <div v-if="isMobile" class="mobile-actions-bar mobile-only mb-6">
      <button class="btn-primary w-full" @click="showChoiceModal = true" :disabled="loading">
        <PlusIcon class="icon" />
        <span>TAMBAH STOK BARU</span>
      </button>
    </div>

    <nav class="tab-nav-wrapper scroll-x mb-6">
      <div class="tab-nav glass-panel">
        <button 
          class="tab-btn" 
          :class="{ active: activeTab === 'inventory' }"
          @click="activeTab = 'inventory'"
        >
          <PackageIcon class="icon-sm" />
          <span>Inventory</span>
        </button>
        <button 
          class="tab-btn" 
          :class="{ active: activeTab === 'pembelian' }"
          @click="activeTab = 'pembelian'"
        >
          <TruckIcon class="icon-sm" />
          <span>Pembelian</span>
        </button>
        <button 
          class="tab-btn" 
          :class="{ active: activeTab === 'stok_opname' }"
          @click="activeTab = 'stok_opname'"
        >
          <ClipboardListIcon class="icon-sm" />
          <span>Opname</span>
        </button>
      </div>
    </nav>

    <div v-if="activeTab === 'inventory'" class="tab-content animate-fade">
      <!-- ━━━ SECTION: PRIMARY PRODUCTS ━━━ -->
      <section class="inventory-section">
        <div class="section-header-flex">
          <div class="section-badge pulse-gold">PRIMARY PRODUCTS</div>
          <button 
            v-if="authStore.isAdmin"
            class="btn-recalculate" 
            @click="recalculateAllHPP"
            :disabled="recalculating"
          >
            <RefreshCwIcon :class="{ 'animate-spin': recalculating }" class="icon-xs" />
            <span>{{ recalculating ? 'RECALCULATING...' : '⟳ RECALCULATE ALL HPP' }}</span>
          </button>
        </div>

        <div class="inventory-grid" v-if="loading">
          <div v-for="i in 3" :key="i" class="skeleton-card-inventory"></div>
        </div>

        <div class="inventory-grid" v-else-if="eggInventory.length > 0">
          <div v-for="item in eggInventory" :key="item.id" class="grade-card glass-panel" :class="item.id">
            <!-- TOP ROW: GRADE & STATUS -->
            <div class="gc-header">
              <span class="grade-chip" :class="getChipClass(item.id)">{{ getGradeLabel(item.id) }}</span>
              <div class="status-badge" :class="getStockStatus(item).class">
                <span v-if="getStockStatus(item).class === 'kritis'" class="dot-pulse"></span>
                {{ getStockStatus(item).label }}
              </div>
            </div>

            <!-- MAIN STOCK INFO -->
            <div class="gc-main">
              <div class="stock-display">
                <h2 class="stock-val-large font-mono">{{ formatStockCount(item.current_stock) }}</h2>
                <span class="stock-unit">butir</span>
              </div>

              <!-- PROGRESS BAR -->
              <div class="progress-container">
                <div class="progress-meta">
                  <span class="pack-count font-mono">{{ calcMaxPacks(item.current_stock) }} PACK</span>
                </div>
                <div class="progress-track">
                  <div class="progress-bar" 
                    :class="getStockStatus(item).class"
                    :style="{ width: getStockProgress(item) + '%' }">
                  </div>
                </div>
              </div>
            </div>

            <!-- MICRO STATS GRID -->
            <div class="gc-stats-grid">
              <div class="ms-item">
                <span class="ms-label">RETAIL</span>
                <span class="ms-val font-mono">{{ formatCurrency(item.retail_price_per_pack || item.base_price_per_pack) }}</span>
              </div>
              <div class="ms-item">
                <span class="ms-label">HPP/BUTIR</span>
                <span class="ms-val font-mono">{{ formatCurrency(item.hpp_per_egg || item.cost_per_egg) }}</span>
              </div>
              <div class="ms-item">
                <span class="ms-label">HPP/PACK</span>
                <span class="ms-val font-mono">{{ formatCurrency((item.hpp_per_egg || item.cost_per_egg) * 10 * 1.073) }}</span>
              </div>
            </div>

            <!-- BOTTOM ROW: SAFETY & ACTION -->
            <div class="gc-footer">
              <div class="safety-info">
                <span class="info-label">Safety:</span>
                <span class="info-val font-mono">{{ item.safety_stock || 20 }} butir</span>
              </div>
              <button class="btn-adjust" @click="quickAdjust(item.id)">
                <span>ADJUST STOCK</span>
              </button>
            </div>
          </div>
        </div>
        <EmptyState v-else icon="PackageIcon" title="Inventory Kosong" message="Produk telur belum terdaftar di database." />
      </section>

      <!-- ━━━ SECTION: SUPPLIES & PACKAGING ━━━ -->
      <section class="inventory-section">
        <div class="section-badge">SUPPLIES & PACKAGING</div>
        <div class="inventory-grid mt-6" v-if="loading">
          <div v-for="i in 3" :key="i" class="skeleton-card-inventory mini"></div>
        </div>
        <div class="inventory-grid mt-6" v-else-if="supplyInventory.length > 0">
          <div v-for="item in supplyInventory" :key="item.id" class="grade-card glass-panel supply-card">
            <div class="gc-header">
              <span class="supply-label">{{ item.label }}</span>
              <div class="status-badge" :class="item.current_stock <= (item.safety_stock || 20) ? 'low' : 'optimal'">
                {{ item.current_stock <= (item.safety_stock || 20) ? 'LOW' : 'OPTIMAL' }}
              </div>
            </div>

            <div class="gc-main mini">
              <h2 class="stock-val-medium font-mono text-green">{{ item.current_stock }}</h2>
              <span class="stock-unit-mini">units</span>
              <div class="progress-track mini">
                <div class="progress-bar optimal" :style="{ width: Math.min((item.current_stock/60)*100, 100) + '%' }"></div>
              </div>
            </div>

            <div class="gc-stats-mini">
              <span class="ms-label">Effective Cost:</span>
              <span class="ms-val font-mono">{{ formatCurrency(item.cost_per_egg || 0) }}</span>
            </div>

            <div class="gc-footer">
              <div class="safety-info">
                <span class="info-label">Safety:</span>
                <span class="info-val font-mono">{{ item.safety_stock || 20 }}</span>
              </div>
              <button class="btn-restock-outline" @click="openPackagingPurchase(item)">
                <span>RESTOCK</span>
              </button>
            </div>
          </div>
        </div>
        <EmptyState v-else icon="PackageSearchIcon" title="Supplies Kosong" message="Belum ada data kemasan atau label." />
      </section>

    <!-- ━━━ SECTION: AUDIT TRAIL ━━━ -->
    <section class="logs-section glass-panel elevated">
      <div class="logs-header-elite">
        <div>
          <h3 class="hero-font text-heading">Audit Trail</h3>
          <span class="text-muted text-xs">Last 20 operations</span>
        </div>
      </div>
      
      <div class="logs-container mt-6">
        <div v-if="loading" class="skeleton-table-rows">
          <div v-for="i in 5" :key="i" class="skeleton-row"></div>
        </div>
        
        <div v-else-if="logs.length > 0">
          <!-- 🖥️ DESKTOP TABLE -->
          <table class="audit-table table-desktop">
            <thead>
              <tr>
                <th>TIMESTAMP</th>
                <th>TYPE</th>
                <th>CHANGE</th>
                <th>REASON</th>
                <th>ADMIN</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="log in logs" :key="log.id" class="audit-row">
                <td class="time-cell font-mono">
                  <span class="rel-time">{{ formatRelativeDate(log.created_at) }}</span>
                  <span class="exact-time">• {{ formatExactTime(log.created_at) }}</span>
                </td>
                <td class="type-cell">
                  <span class="audit-badge" :class="log.log_type.toLowerCase()">
                    {{ log.log_type.toUpperCase().replace('_', ' ') }}
                  </span>
                </td>
                <td class="change-cell font-mono" :class="log.change > 0 ? 'text-green' : 'text-red'">
                  {{ log.change > 0 ? '+' : '' }}{{ log.change.toLocaleString('id-ID') }}
                </td>
                <td class="notes-cell">
                  <span class="note-pill" :class="{ 'void-line': log.log_type === 'void_return' || log.notes?.toLowerCase().includes('void') }">
                    {{ log.notes || '-' }}
                  </span>
                </td>
                <td class="admin-cell">System Admin</td>
              </tr>
            </tbody>
          </table>

          <!-- 📱 MOBILE CARDS -->
          <div class="cards-mobile">
            <div v-for="log in logs" :key="'m-'+log.id" class="mobile-audit-card glass-panel">
              <div class="mac-header">
                <span class="audit-badge" :class="log.log_type.toLowerCase()">
                  {{ log.log_type.toUpperCase().replace('_', ' ') }}
                </span>
                <span class="mac-time font-mono">{{ formatRelativeDate(log.created_at) }}</span>
              </div>
              <div class="mac-body">
                <div class="mac-change" :class="log.change > 0 ? 'text-green' : 'text-red'">
                  {{ log.change > 0 ? '+' : '' }}{{ log.change.toLocaleString('id-ID') }} butir
                </div>
                <div class="mac-notes">{{ log.notes || '-' }}</div>
              </div>
            </div>
          </div>
        </div>
        <EmptyState v-else icon="HistoryIcon" title="Belum ada riwayat" message="Semua pergerakan stok akan tercatat di sini." />
      </div>
    </section>
    </div>

    <!-- ━━━ TAB 2: PEMBELIAN & GRADING ━━━ -->
    <div v-else-if="activeTab === 'pembelian'" class="tab-content animate-fade">
      <div class="purchase-layout">
        <!-- PURCHASE HISTORY -->
        <div class="glass-panel purchase-history-panel">
          <div class="section-header-flex">
            <div>
              <h3 class="hero-font" style="font-size:18px;">Riwayat Pembelian</h3>
              <p class="text-dim text-xs">Catatan seluruh pembelian dari supplier</p>
            </div>
            <button class="btn-secondary" @click="showChoiceModal = true">
              <PlusIcon class="icon-xs" />
              <span>+ Catat Pembelian Baru</span>
            </button>
          </div>

          <!-- SUMMARY STATS -->
          <div class="purchase-stats-row mt-4">
            <div class="ps-card glass-panel">
              <span class="ps-label">TOTAL PEMBELIAN</span>
              <span class="ps-val font-mono">{{ formatCurrency(purchaseStats.totalCost) }}</span>
            </div>
            <div class="ps-card glass-panel">
              <span class="ps-label">TOTAL BUTIR</span>
              <span class="ps-val font-mono">{{ purchaseStats.totalEggs.toLocaleString('id-ID') }}</span>
            </div>
            <div class="ps-card glass-panel">
              <span class="ps-label">UTANG AKTIF</span>
              <span class="ps-val font-mono" :class="purchaseStats.totalDebt > 0 ? 'text-red' : 'text-green'">{{ formatCurrency(purchaseStats.totalDebt) }}</span>
            </div>
          </div>

          <div class="table-container-elite mt-4">
            <!-- 🖥️ DESKTOP TABLE -->
            <table v-if="purchases.length > 0" class="logs-table v-middle table-desktop">
              <thead>
                <tr>
                  <th>Tanggal</th>
                  <th>Supplier</th>
                  <th>Qty (butir)</th>
                  <th>Harga/Butir</th>
                  <th>Total</th>
                  <th>Status</th>
                  <th>Sisa Utang</th>
                  <th>Grading</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="p in purchases" :key="p.id" class="log-row">
                  <td class="font-bold">{{ formatDate(p.purchase_date || p.created_at) }}</td>
                  <td>{{ suppliers.find(s => s.id === p.supplier_id)?.name || '-' }}</td>
                  <td>{{ p.total_eggs_bought.toLocaleString('id-ID') }}</td>
                  <td>{{ formatCurrency(p.price_per_egg) }}</td>
                  <td class="font-bold">{{ formatCurrency(p.total_cost) }}</td>
                  <td>
                    <span class="status-badge" :class="p.status">{{ p.status === 'lunas' ? 'LUNAS' : p.status === 'cicilan' ? 'CICILAN' : 'UTANG' }}</span>
                  </td>
                  <td :class="p.remaining_debt > 0 ? 'text-red font-bold' : 'text-green'">
                    {{ formatCurrency(p.remaining_debt || 0) }}
                  </td>
                  <td>
                    <button 
                      v-if="!purchaseHasGrading(p.id)"
                      class="btn-secondary" 
                      @click="openGradingForPurchase(p)"
                    >⏳ Grading →</button>
                    <span v-else class="text-dim text-xs">✓ Graded</span>
                  </td>
                </tr>
              </tbody>
            </table>

            <!-- 📱 MOBILE CARDS -->
            <div v-if="purchases.length > 0" class="cards-mobile">
              <div v-for="p in purchases" :key="'p-m-'+p.id" class="purchase-mobile-card glass-panel">
                <div class="pmc-header">
                  <span class="pmc-date font-mono">{{ formatDate(p.purchase_date || p.created_at) }}</span>
                  <span class="status-badge" :class="p.status">{{ p.status.toUpperCase() }}</span>
                </div>
                <div class="pmc-supplier">{{ suppliers.find(s => s.id === p.supplier_id)?.name || 'Unknown Supplier' }}</div>
                <div class="pmc-stats">
                  <div class="pmc-stat">
                    <span class="label">QTY</span>
                    <span class="val">{{ p.total_eggs_bought.toLocaleString('id-ID') }}</span>
                  </div>
                  <div class="pmc-stat">
                    <span class="label">TOTAL</span>
                    <span class="val">{{ formatCurrency(p.total_cost) }}</span>
                  </div>
                </div>
                <div class="pmc-footer">
                  <div v-if="p.remaining_debt > 0" class="pmc-debt text-red">
                    Sisa: {{ formatCurrency(p.remaining_debt) }}
                  </div>
                  <button 
                    v-if="!purchaseHasGrading(p.id)"
                    class="btn-primary-xs" 
                    @click="openGradingForPurchase(p)"
                  >Grading →</button>
                  <span v-else class="text-green text-xs">Grading ✓</span>
                </div>
              </div>
            </div>

            <EmptyState v-else icon="TruckIcon" title="Belum Ada Pembelian" message="Klik '+ Catat Pembelian Baru' untuk mencatat batch pertama." />
          </div>
        </div>
      </div>
    </div>

    <!-- ━━━ FEATURE 1: STOK OPNAME SECTION ━━━ -->
    <div v-else-if="activeTab === 'stok_opname'" class="tab-content animate-fade">
      <!-- INFO BANNER -->
      <div class="info-banner-premium glass-panel mb-6">
        <div class="ib-icon">💡</div>
        <div class="ib-text">
          <strong>Tips:</strong> Gunakan tab ini khusus untuk pencatatan verifikasi fisik bulanan/mingguan. Untuk input barang datang (Restock), gunakan tombol <strong>TAMBAH STOK BARU</strong> di pojok kanan atas.
        </div>
      </div>

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
              class="btn-primary" 
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
                <!-- 🖥️ DESKTOP TABLE -->
                <table class="logs-table v-middle table-desktop" v-if="opnameHistory.length > 0">
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
                            {{ so.total_difference > 0 ? '+' : '' }}{{ formatStockCount(so.total_difference || 0) }}
                        </td>
                        <td>
                            <span class="status-badge" :class="so.status">{{ so.status === 'completed' ? 'SELESAI' : 'DRAFT' }}</span>
                        </td>
                        <td class="text-right">
                            <button class="btn-secondary" @click="viewStokTake(so)">Detail</button>
                        </td>
                        </tr>
                    </tbody>
                </table>

                <!-- 📱 MOBILE CARDS -->
                <div v-if="opnameHistory.length > 0" class="cards-mobile">
                  <div v-for="so in opnameHistory" :key="'so-m-'+so.id" class="so-history-card glass-panel" @click="viewStokTake(so)">
                    <div class="sohc-header">
                      <span class="font-bold">{{ formatDate(so.opname_date) }}</span>
                      <span class="status-badge" :class="so.status">{{ so.status.toUpperCase() }}</span>
                    </div>
                    <div class="sohc-body">
                      <div class="sohc-diff" :class="so.total_difference < 0 ? 'text-red' : 'text-green'">
                        Selisih: {{ so.total_difference > 0 ? '+' : '' }}{{ formatStockCount(so.total_difference || 0) }}
                      </div>
                      <span class="text-muted text-xs">Oleh: {{ so.conducted_by }}</span>
                    </div>
                  </div>
                </div>

                <EmptyState 
                    v-else 
                    icon="ClipboardCheckIcon" 
                    title="Riwayat Masih Kosong" 
                    message="Belum ada riwayat verifikasi. Klik 'MULAI STOK OPNAME BARU' untuk sinkronisasi stok fisik pertama Anda."
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
              <button class="btn-secondary" @click="saveSODraft" :disabled="submittingSO">Simpan Draft</button>
              <button class="btn-primary" @click="finalizeStokOpname" :disabled="submittingSO">
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


    <!-- NEW INVENTORY COMPONENTS -->
    <AddStockChoiceModal 
      :show="showChoiceModal" 
      @close="showChoiceModal = false"
      @select="handleChoiceSelect"
    />

    <PembelianTelurSlideOver 
      :show="showPembelianSlideOver" 
      @close="showPembelianSlideOver = false"
      @purchaseCreated="handlePurchaseCreated"
    />

    <GradingModal 
      :show="showGradingModal" 
      :purchase="gradingPurchase"
      :supplierName="gradingSupplierName"
      @close="showGradingModal = false"
      @gradingDone="handleGradingDone"
    />

    <RestockSuppliesSlideOver 
      :show="showSuppliesSlideOver" 
      @close="showSuppliesSlideOver = false"
      @restockDone="handleRestockDone"
    />

    <!-- QUICK ADJUST MODAL (kept for waste/price-update/manual on grade cards) -->
    <Teleport to="body">
      <div v-if="showAdjustmentModal" class="modal-overlay" @click.self="showAdjustmentModal = false">
        <div class="modal-card glass-panel animate-pop">
          <h2 class="hero-font">Koreksi Stok</h2>
          <p class="text-dim">Sortir limbah, koreksi manual, atau update harga.</p>

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
                :options="adjustOperationTypes" 
                label="Tipe Operasi" 
                placeholder="Pilih tipe..."
              />
            </div>

            <div v-if="form.log_type === 'price_update'" class="price-update-fields animate-slide">
              <div class="form-row">
                <div class="form-group">
                  <label>HPP Telur (Per Butir)</label>
                  <input type="number" v-model.number="editForm.cost_per_egg" placeholder="e.g. 1500" required />
                </div>
                <div class="form-group">
                  <label>Harga Jual (Per Pack)</label>
                  <input type="number" v-model.number="editForm.base_price_per_pack" required />
                </div>
              </div>
              
              <div class="form-group info-box mt-3">
                <label>Info HPP Total (Auto-calculated)</label>
                <div class="calc-result">
                  {{ formatCurrency((editForm.cost_per_egg * 10) + editForm.cost_per_packaging + editForm.cost_per_sticker + editForm.cost_per_card) }}
                </div>
                <p class="text-xs text-muted">Termasuk: Kemasan {{ formatCurrency(editForm.cost_per_packaging) }}, Stiker {{ formatCurrency(editForm.cost_per_sticker) }}, Kartu {{ formatCurrency(editForm.cost_per_card) }}</p>
                
                <div class="mt-4 flex justify-between items-center pt-4 border-t border-white/5">
                  <span class="text-xs text-muted">Lihat Riwayat Evolusi Harga</span>
                  <button type="button" class="btn-link-xs" @click="showFullHistory = true">Buka Log →</button>
                </div>
              </div>
            </div>

            <div v-else class="adjustment-quantity-fields">
              <div class="form-row">
                <div class="form-group">
                  <label>Jumlah (Butir)</label>
                  <input type="number" v-model.number="form.change" placeholder="Contoh: 100" />
                </div>
              </div>
            </div>

            <div class="form-group">
              <label>Catatan / Alasan</label>
              <textarea v-model="form.notes" placeholder="Tuliskan alasan perubahan..."></textarea>
            </div>

            <div class="modal-actions">
              <button type="button" class="btn-secondary" @click="showAdjustmentModal = false">Batal</button>
              <button type="submit" class="btn-primary" :disabled="submitting">
                {{ submitting ? 'MENYIMPAN...' : 'SIMPAN KOREKSI' }}
              </button>
            </div>
          </form>
        </div>
      </div>
    </Teleport>

<!-- Redundant Edit Modal Deleted (Folded into Adjustment) -->

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
                {{ formatCurrency(calculateEffectivePackCost()) }}
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
import AddStockChoiceModal from '../components/inventory/AddStockChoiceModal.vue';
import PembelianTelurSlideOver from '../components/inventory/PembelianTelurSlideOver.vue';
import GradingModal from '../components/inventory/GradingModal.vue';
import RestockSuppliesSlideOver from '../components/inventory/RestockSuppliesSlideOver.vue';
import { 
  TruckIcon,
  ClipboardListIcon,
  PlusIcon,
  PackageIcon,
  RefreshCwIcon
} from 'lucide-vue-next';

// @ts-ignore
import { GRADES } from '../constants/grades';
// @ts-ignore
import { formatCurrency, formatStock, formatRelativeDate, formatExactTime } from '../utils/formatters';
// @ts-ignore
import { calcHppPerPack, calcMargin, calcMaxPacks } from '../utils/calculations';

function formatStockCount(val: number) {
  return val.toLocaleString('id-ID');
}

function getGradeLabel(id: string) {
  if (id === 'hero_size') return GRADES.hero.label;
  if (id === 'standard_size' || id === 'medium_size') return GRADES.medium.label;
  if (id === 'small_size' || id === 'salted_egg') return GRADES.small.label;
  return id;
}

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
const showPackagingModal = ref(false);
const showConfirmModal = ref(false);
const showChoiceModal = ref(false);
const showPembelianSlideOver = ref(false);
const showGradingModal = ref(false);
const showSuppliesSlideOver = ref(false);
const gradingPurchase = ref<any>(null);
const gradingSupplierName = ref('');
const confirmData = reactive({
  title: '',
  message: '',
  onConfirm: () => {}
});
const submitting = ref(false);

// removed priceHistory as it's folded into adjustment flow

// ━━━ PURCHASE & GRADING STATE ━━━
const purchases = ref<any[]>([]);
const gradings = ref<any[]>([]);
const bankAccounts = ref<any[]>([]);

function purchaseHasGrading(purchaseId: string) {
  return gradings.value.some((g: any) => g.purchase_id === purchaseId);
}


function getStockStatus(item: any) {
  const safety = item.safety_stock || 20;
  const current = item.current_stock;
  if (current <= safety) return { label: 'KRITIS', class: 'kritis' };
  if (current <= safety * 2) return { label: 'LOW', class: 'low' };
  return { label: 'OPTIMAL', class: 'optimal' };
}

function getChipClass(id: string) {
  if (id === 'hero_size' || id === 'hero') return 'chip-hero'
  if (id === 'standard_size' || id === 'medium_size' || id === 'medium') return 'chip-medium'
  if (id === 'small_size' || id === 'salted_egg' || id === 'small') return 'chip-small'
  return ''
}

function getStockProgress(item: any) {
  const safety = item.safety_stock || 20;
  const max = safety * 3;
  return Math.min((item.current_stock / max) * 100, 100);
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


const adjustOperationTypes = [
  { label: 'Waste / Pecah (-)', value: 'sorting_waste' },
  { label: 'Koreksi Manual', value: 'manual_adjustment' },
  { label: 'Update Spesifikasi (Harga/HPP)', value: 'price_update' }
];

const purchaseStats = computed(() => {
  let totalCost = 0, totalEggs = 0, totalDebt = 0;
  purchases.value.forEach(p => {
    totalCost += (p.total_cost || 0);
    totalEggs += (p.total_eggs_bought || 0);
    totalDebt += (p.remaining_debt || 0);
  });
  return { totalCost, totalEggs, totalDebt };
});

function handleChoiceSelect(type: 'telur' | 'supplies') {
  showChoiceModal.value = false;
  if (type === 'telur') {
    showPembelianSlideOver.value = true;
  } else {
    showSuppliesSlideOver.value = true;
  }
}

function handlePurchaseCreated(purchase: any) {
  showPembelianSlideOver.value = false;
  gradingPurchase.value = purchase;
  gradingSupplierName.value = suppliers.value.find(s => s.id === purchase?.supplier_id)?.name || 'Supplier';
  showGradingModal.value = true;
  fetchPurchases();
}

async function handleGradingDone() {
  showGradingModal.value = false;
  gradingPurchase.value = null;
  await fetchData();
  await fetchPurchases();
}

async function handleRestockDone() {
  showSuppliesSlideOver.value = false;
  await fetchData();
}

function openGradingForPurchase(purchase: any) {
  gradingPurchase.value = purchase;
  gradingSupplierName.value = suppliers.value.find(s => s.id === purchase?.supplier_id)?.name || 'Supplier';
  showGradingModal.value = true;
}

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


function formatExactTime(date: string) {
  return new Date(date).toLocaleString('id-ID', { 
    day: '2-digit', 
    month: 'short', 
    hour: '2-digit', 
    minute: '2-digit' 
  });
}



function quickAdjust(gradeId: string) {
  const item = inventory.value.find(i => i.id === gradeId);
  if (item) {
    form.egg_type = gradeId;
    form.log_type = 'manual_adjustment';
    
    // Prep EditForm for potential price_update type usage
    editForm.id = item.id;
    editForm.label = item.label;
    editForm.base_price_per_pack = item.base_price_per_pack;
    editForm.cost_per_egg = item.cost_per_egg || 0;
    
    const latestPackaging = supplyInventory.value.find(s => s.id === 'packaging_standard')?.cost_per_egg || 0;
    const latestSticker = supplyInventory.value.find(s => s.id === 'sticker_label')?.cost_per_egg || 0;
    const latestCard = supplyInventory.value.find(s => s.id === 'mini_card')?.cost_per_egg || 0;
    
    editForm.cost_per_packaging = latestPackaging || item.cost_per_packaging || 0;
    editForm.cost_per_sticker = latestSticker || item.cost_per_sticker || 0;
    editForm.cost_per_card = latestCard || item.cost_per_card || 0;
    
    editForm.old_base_price = item.base_price_per_pack;
    editForm.old_cost_price = item.cost_price || 0;
  }
  showAdjustmentModal.value = true;
}

// removed openEditProduct and saveProductEdit as they're folded into adjustment flow
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

  // 0. Handle Price Update (folded logic)
  if (form.log_type === 'price_update') {
    const newCostPrice = (editForm.cost_per_egg * 10) + editForm.cost_per_packaging + editForm.cost_per_sticker + editForm.cost_per_card;
    const { error } = await supabase.from('inventory').update({
      base_price_per_pack: editForm.base_price_per_pack,
      cost_per_egg: editForm.cost_per_egg,
      cost_price: newCostPrice,
      updated_at: new Date().toISOString()
    }).eq('id', editForm.id);

    if (!error) {
       // Audit Price Changes
       const authorName = authStore.profile?.full_name || 'Admin';
       if (editForm.base_price_per_pack !== editForm.old_base_price) {
         await supabase.from('price_history').insert({
           inventory_id: editForm.id,
           price_type: 'selling',
           old_value: editForm.old_base_price,
           new_value: editForm.base_price_per_pack,
           changed_by: authorName,
           reason: form.notes
         });
       }
       showToast('Spesifikasi produk diperbarui');
       showAdjustmentModal.value = false;
       fetchData();
    } else {
       showToast('Gagal update spesifikasi', 'error');
    }
    submitting.value = false;
    return;
  }
  
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

const isMobile = ref(window.innerWidth <= 768)
function checkMobile() {
  isMobile.value = window.innerWidth <= 768
}

onMounted(() => {
  fetchData();
  fetchPurchases();
  checkMobile()
  window.addEventListener('resize', checkMobile)
});

onUnmounted(() => {
  window.removeEventListener('resize', checkMobile)
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
  gap: 40px;
  padding-bottom: 60px;
}

/* PURCHASE STATS ROW */
.purchase-stats-row {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 12px;
}

@media (max-width: 768px) {
  .purchase-stats-row {
    grid-template-columns: 1fr;
  }
  
  .purchase-history-panel {
    padding: 16px;
  }
}

.ps-card {
  padding: 14px 18px;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.ps-label {
  font-size: 10px;
  font-weight: 700;
  letter-spacing: 1.5px;
  color: var(--color-text-dim, #64748b);
  text-transform: uppercase;
}

.ps-val {
  font-size: 16px;
  font-weight: 700;
  color: #fff;
}

.purchase-history-panel {
  padding: 24px;
}

.purchase-layout {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

/* INFO BANNER */
.info-banner-premium {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 16px 20px;
  background: rgba(45, 212, 191, 0.05); /* Teal accent */
  border: 1px solid rgba(45, 212, 191, 0.2);
  border-radius: 12px;
}

.ib-icon {
  font-size: 20px;
}

.ib-text {
  font-size: 0.85rem;
  color: #ccfbf1;
  line-height: 1.5;
}

.ib-text strong {
  color: #2dd4bf;
}

/* ━━━ HEADER ━━━ */
.header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
}

.brand-tag {
  color: var(--gold);
  letter-spacing: 0.2em;
  font-size: 0.75rem;
  font-weight: 800;
  margin-bottom: 8px;
  font-family: var(--font-ui);
}

.hero-font {
  font-family: var(--font-headline);
  font-size: 2.5rem;
  font-weight: 800;
  letter-spacing: -0.02em;
}

@media (max-width: 768px) {
  .hero-font {
    font-size: 1.8rem;
  }
}

/* ━━━ TABS ━━━ */
.tab-nav-wrapper {
  margin: -16px;
  margin-bottom: 24px;
  padding: 16px;
  -webkit-overflow-scrolling: touch;
}

.tab-nav {
  display: flex;
  gap: 8px;
  padding: 6px;
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-radius: var(--radius-lg);
  width: fit-content;
  min-width: max-content;
}

.tab-btn {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 20px;
  border-radius: var(--radius-md);
  color: var(--muted);
  font-family: var(--font-ui);
  font-weight: 600;
  font-size: 0.9rem;
  transition: all 0.2s ease;
  background: transparent;
  border: none;
  cursor: pointer;
}

.tab-btn:hover {
  color: white;
  background: rgba(255, 255, 255, 0.03);
}

.tab-btn.active {
  color: black;
  background: var(--gold);
  box-shadow: 0 4px 15px rgba(245, 158, 11, 0.3);
}

/* ━━━ GRID SYSTEM ━━━ */
.inventory-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 16px;
  margin-top: 20px;
}

@media (min-width: 1201px) { .inventory-grid { grid-template-columns: repeat(3, 1fr) !important; } }
@media (max-width: 1200px) { .inventory-grid { grid-template-columns: repeat(2, 1fr); } }
@media (max-width: 768px) { .inventory-grid { grid-template-columns: 1fr; } }

/* ━━━ SECTION HEADERS ━━━ */
.section-header-flex {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.section-badge {
  font-family: var(--font-ui);
  font-size: 11px;
  font-weight: 800;
  color: var(--gold);
  letter-spacing: 2px;
  background: rgba(245, 158, 11, 0.1);
  padding: 6px 14px;
  border-radius: 4px;
  text-transform: uppercase;
  border: 1px solid rgba(245, 158, 11, 0.2);
}

.btn-recalculate {
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid var(--border);
  color: var(--muted);
  font-family: var(--font-ui);
  font-size: 11px;
  font-weight: 700;
  padding: 6px 12px;
  border-radius: 4px;
  cursor: pointer;
  transition: all 0.2s ease;
  letter-spacing: 1px;
}

.btn-recalculate:hover:not(:disabled) {
  background: white;
  color: black;
  border-color: white;
}

/* ━━━ GRADE CARDS ━━━ */
.grade-card {
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-radius: var(--radius-lg);
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 24px;
  transition: all 0.3s cubic-bezier(0.23, 1, 0.32, 1);
  position: relative;
}

.grade-card:hover {
  transform: translateY(-4px);
  border-color: var(--border-hover);
  box-shadow: var(--shadow-premium);
}

.gc-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.grade-chip {
  padding: 4px 12px;
  border-radius: 100px;
  font-size: 12px;
  font-weight: 700;
  text-transform: uppercase;
  font-family: var(--font-ui);
}

.grade-chip.hero_size, .grade-chip.hero { background: var(--gold); color: black; }
.grade-chip.standard_size, .grade-chip.medium { background: var(--violet); color: white; }
.grade-chip.salted_egg, .grade-chip.small { background: var(--sky); color: black; }

.status-badge {
  padding: 4px 10px;
  border-radius: 4px;
  font-size: 10px;
  font-weight: 800;
  display: flex;
  align-items: center;
  gap: 6px;
  border: 1px solid transparent;
}

.status-badge.optimal { background: rgba(16, 185, 129, 0.15); color: var(--green); border-color: rgba(16, 185, 129, 0.3); }
.status-badge.low { background: rgba(245, 158, 11, 0.15); color: var(--gold); border-color: rgba(245, 158, 11, 0.3); }
.status-badge.kritis { 
  background: rgba(239, 68, 68, 0.15); 
  color: var(--red); 
  border-color: var(--red);
  box-shadow: 0 0 10px rgba(239, 68, 68, 0.2);
  animation: border-pulse 2s infinite;
}

@keyframes border-pulse {
  0% { box-shadow: 0 0 0 0 rgba(239, 68, 68, 0.4); }
  70% { box-shadow: 0 0 0 6px rgba(239, 68, 68, 0); }
  100% { box-shadow: 0 0 0 0 rgba(239, 68, 68, 0); }
}

.dot-pulse {
  width: 6px;
  height: 6px;
  background: var(--red);
  border-radius: 50%;
}

/* ━━━ MAIN STOCK ━━━ */
.gc-main {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.stock-display {
  display: flex;
  align-items: baseline;
  gap: 8px;
}

.stock-val-large {
  font-size: 3.5rem;
  font-weight: 700;
  color: white;
  line-height: 1;
  letter-spacing: -0.04em;
}

.stock-unit {
  font-size: 1.1rem;
  color: var(--muted);
  font-weight: 600;
}

/* ━━━ PROGRESS BAR ━━━ */
.progress-container {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.progress-meta {
  display: flex;
  justify-content: flex-end;
}

.pack-count {
  font-size: 18px;
  font-weight: 600;
  color: white;
}

.progress-track {
  height: 6px;
  background: rgba(255, 255, 255, 0.05);
  border-radius: 100px;
  overflow: hidden;
}

.progress-bar {
  height: 100%;
  border-radius: 100px;
  transition: width 0.6s cubic-bezier(0.23, 1, 0.32, 1);
}

.progress-bar.optimal { background: var(--green); }
.progress-bar.low { background: var(--gold); }
.progress-bar.kritis { background: var(--red); }

/* ━━━ MICRO STATS ━━━ */
.gc-stats-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 12px;
  padding: 16px 0;
  border-top: 1px solid var(--border);
  border-bottom: 1px solid var(--border);
}

.ms-item {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.ms-label {
  font-size: 10px;
  font-weight: 700;
  color: var(--muted);
}

.ms-val {
  font-size: 13px;
  font-weight: 600;
  color: white;
}

/* ━━━ FOOTER ━━━ */
.gc-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.safety-info {
  display: flex;
  gap: 4px;
  font-size: 12px;
}

.info-label { color: var(--muted); }
.info-val { color: white; font-weight: 600; }

.btn-adjust {
  background: var(--gold);
  color: black;
  font-weight: 700;
  font-size: 12px;
  padding: 8px 16px;
  border-radius: var(--radius-sm);
  border: none;
  cursor: pointer;
  transition: all 0.2s ease;
}

.btn-adjust:hover {
  filter: brightness(1.1);
  transform: scale(1.02);
}

/* ━━━ SUPPLIES STYLES ━━━ */
.supply-label {
  font-family: var(--font-ui);
  font-size: 14px;
  font-weight: 600;
  color: white;
}

.gc-main.mini {
  display: flex;
  align-items: baseline;
  gap: 8px;
}

.stock-val-medium {
  font-size: 2.2rem;
  font-weight: 700;
}

.stock-unit-mini {
  color: var(--muted);
  font-size: 0.9rem;
  font-weight: 600;
}

.progress-track.mini { margin-top: 8px; }

.gc-stats-mini {
  display: flex;
  gap: 8px;
  align-items: center;
  font-size: 13px;
}

.btn-restock {
  background: transparent;
  border: 1px solid var(--green);
  color: var(--green);
  font-weight: 700;
  font-size: 12px;
  padding: 8px 16px;
  border-radius: var(--radius-sm);
  cursor: pointer;
  transition: all 0.2s ease;
}

.btn-restock:hover {
  background: rgba(16, 185, 129, 0.05);
  border-color: white;
  color: white;
}

/* ━━━ AUDIT TRAIL ━━━ */
.logs-section.elevated {
  background: var(--bg-card);
  padding: 32px;
}

.text-heading { font-size: 1.1rem; color: white; font-weight: 600; }

.audit-table {
  width: 100%;
  border-collapse: collapse;
}

.audit-table th {
  text-align: left;
  padding: 12px;
  font-size: 10px;
  font-weight: 800;
  letter-spacing: 1px;
  color: var(--muted);
  border-bottom: 1px solid var(--border);
}

.audit-row { transition: all 0.2s ease; }
.audit-row:nth-child(odd) { background: rgba(255, 255, 255, 0.01); }
.audit-row:hover { background: rgba(255, 255, 255, 0.02); }

.audit-table td {
  padding: 16px 12px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.03);
  font-size: 13px;
}

.time-cell { display: flex; flex-direction: column; gap: 2px; }
.rel-time { color: white; font-weight: 600; }
.exact-time { color: var(--muted); font-size: 11px; }

.audit-badge {
  padding: 2px 8px;
  border-radius: 4px;
  font-size: 10px;
  font-weight: 800;
  display: inline-block;
  border-width: 1px;
  border-style: solid;
}

.audit-badge.sale { background: rgba(239, 68, 68, 0.12); color: var(--red); border-color: rgba(239, 68, 68, 0.2); }
.audit-badge.arrival { background: rgba(16, 185, 129, 0.12); color: var(--green); border-color: rgba(16, 185, 129, 0.2); }
.audit-badge.opname { background: rgba(99, 102, 241, 0.12); color: #818cf8; border-color: rgba(99, 102, 241, 0.2); }
.audit-badge.void { background: rgba(239, 68, 68, 0.2); color: var(--red); border-color: rgba(239, 68, 68, 0.3); }

/* 📱 MOBILE AUDIT CARDS */
.mobile-audit-card {
  padding: 12px;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.mac-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.mac-time {
  font-size: 10px;
  color: var(--muted);
}

.mac-body {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.mac-change {
  font-size: 0.95rem;
  font-weight: 700;
}

.mac-notes {
  font-size: 0.8rem;
  color: var(--muted);
  max-width: 60%;
  text-align: right;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.note-pill { color: white; font-weight: 500; }
.void-line { text-decoration: line-through; opacity: 0.6; }

/* ━━━ UTILITIES ━━━ */
.animate-spin { animation: spin 1s linear infinite; }
@keyframes spin { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }

.skeleton-card-inventory {
  height: 320px;
  background: linear-gradient(90deg, rgba(255,255,255,0.03) 25%, rgba(255,255,255,0.08) 50%, rgba(255,255,255,0.03) 75%);
  background-size: 200% 100%;
  animation: loading 1.5s infinite;
  border-radius: var(--radius-lg);
}

@keyframes loading {
  0% { background-position: 200% 0; }
  100% { background-position: -200% 0; }
}

/* ━━━ REFINED MODAL & FORM ELEMENTS ━━━ */
.purchase-form-card {
  border: 1px solid rgba(255, 140, 0, 0.2);
  border-radius: 16px;
  padding: 20px;
  margin-top: 10px;
  background: rgba(255, 255, 255, 0.02);
}

.summary-line {
  display: flex;
  justify-content: space-between;
  margin-bottom: 8px;
  font-size: 0.9rem;
  color: var(--muted);
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
  background: var(--gold);
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
  box-shadow: 0 5px 15px rgba(245, 158, 11, 0.3);
}

.btn-primary-action:disabled {
  opacity: 0.5;
  cursor: not-allowed;
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
  background: linear-gradient(135deg, var(--gold) 0%, #ff8c00 100%);
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

.so-table-wrapper {
  width: 100%;
  overflow-x: auto;
  border-radius: 12px;
  background: rgba(255, 255, 255, 0.01);
  border: 1px solid rgba(255, 255, 255, 0.05);
}

.so-table {
  width: 100%;
  border-collapse: collapse;
  min-width: 600px; /* Ensure table doesn't squash too much */
}

.so-table th {
  text-align: left;
  padding: 16px;
  color: var(--muted);
  font-size: 0.75rem;
  text-transform: uppercase;
  background: rgba(255, 255, 255, 0.02);
}

.so-row td {
  padding: 16px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.03);
}

.count-input-wrapper {
  max-width: 100px;
  margin: 0 auto;
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
  color: var(--muted);
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

.status-badge.draft { background: rgba(255, 255, 255, 0.1); color: var(--muted); }
.status-badge.completed { background: rgba(0, 255, 157, 0.1); color: var(--green); }

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
  background: var(--gold);
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
  color: var(--gold);
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

.ph-row:has(.ph-type.selling) { border-left-color: var(--green); }
.ph-row:has(.ph-type.hpp) { border-left-color: var(--gold); }

.ph-main {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.ph-meta {
  display: flex;
  justify-content: space-between;
  font-size: 0.65rem;
  color: var(--muted);
}

.ph-author { font-weight: 700; color: rgba(255, 255, 255, 0.5); }

.icon-xs { width: 12px; height: 12px; }

.text-red { color: var(--red); }

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
  color: var(--muted);
  text-transform: uppercase;
  font-weight: 800;
}

.fs-val {
  font-size: 0.9rem;
  font-weight: 900;
  color: white;
}

.fs-item.highlight .fs-val {
  color: var(--gold);
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
  color: var(--muted);
  font-size: 0.7rem;
  font-weight: 800;
  cursor: pointer;
  border-radius: 8px;
  transition: all 0.3s ease;
}

.toggle-buttons button.active {
  background: var(--gold);
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

.gc-badge.hero { background: var(--gold); color: black; }
.gc-badge.medium { background: #4ecdc4; color: black; }
.gc-badge.small { background: #ff6b6b; color: black; }

.gc-rule {
  font-size: 0.65rem;
  font-weight: 800;
  color: var(--muted);
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
  color: var(--muted);
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
  color: var(--red);
}

.grading-validation.valid {
  background: rgba(0, 255, 157, 0.1);
  border: 1px solid rgba(0, 255, 157, 0.2);
  color: var(--green);
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

.status-badge.lunas { background: rgba(0, 255, 157, 0.1); color: var(--green); }
.status-badge.cicilan { background: rgba(255, 140, 0, 0.1); color: var(--gold); }
.status-badge.utang { background: rgba(255, 62, 62, 0.1); color: var(--red); }

.red-highlight {
  background: rgba(255, 62, 62, 0.1) !important;
  border-color: rgba(255, 62, 62, 0.2) !important;
}

.red-highlight .fs-val {
  color: var(--red) !important;
}

@media (max-width: 768px) {
  .grading-cards {
    grid-template-columns: 1fr;
  }
  
  /* 📱 PURCHASE MOBILE CARDS */
  .purchase-mobile-card {
    padding: 16px;
    display: flex;
    flex-direction: column;
    gap: 8px;
  }
  
  .pmc-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }
  
  .pmc-date {
    font-size: 11px;
    color: var(--muted);
  }
  
  .pmc-supplier {
    font-weight: 700;
    font-size: 1rem;
    color: white;
  }
  
  .pmc-stats {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 12px;
    padding: 8px 0;
    border-top: 1px solid rgba(255, 255, 255, 0.05);
  }
  
  .pmc-stat {
    display: flex;
    flex-direction: column;
  }
  
  .pmc-stat .label {
    font-size: 9px;
    color: var(--muted);
    text-transform: uppercase;
  }
  
  .pmc-stat .val {
    font-weight: 700;
    font-size: 0.9rem;
    color: white;
  }
  
  .pmc-footer {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-top: 4px;
  }
  
  .pmc-debt {
    font-size: 0.75rem;
    font-weight: 700;
  }
  
  /* 📱 STOK OPNAME HISTORY CARDS */
  .so-history-card {
    padding: 16px;
    display: flex;
    flex-direction: column;
    gap: 8px;
  }
  
  .sohc-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }
  
  .sohc-body {
    display: flex;
    justify-content: space-between;
    align-items: flex-end;
  }
  
  .sohc-diff {
    font-weight: 700;
    font-size: 1.1rem;
    font-family: var(--font-mono);
  }
  
  .btn-primary-xs {
    background: var(--gold);
    color: black;
    padding: 6px 12px;
    border-radius: 6px;
    font-size: 0.75rem;
    font-weight: 800;
    border: none;
  }
}
</style>
