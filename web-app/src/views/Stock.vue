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
      <section class="inventory-section section-primary-products">
        <div class="section-header">
          <div class="section-header-left">
            <span class="section-badge">PRIMARY PRODUCTS</span>
            <div class="section-divider-line"></div>
          </div>
          <div class="section-header-right" style="display:flex; gap:12px;">
            <div class="search-box-mini glass-panel">
              <SearchIcon class="icon-xs" />
              <input v-model="searchInventoryQuery" placeholder="Cari produk..." />
            </div>
            <button 
              v-if="authStore.isAdmin"
              class="btn-recalculate" 
              @click="recalculateAllHPP"
              :disabled="recalculating"
            >
              <RefreshCwIcon :class="{ 'animate-spin': recalculating }" class="icon-xs" />
              <span>{{ recalculating ? 'RECALCULATING...' : '⟳ RECALCULATE HPP' }}</span>
            </button>
          </div>
        </div>

        <div class="primary-products-grid" v-if="loading">
          <div v-for="i in 2" :key="i" class="skeleton-card-inventory"></div>
        </div>

        <div class="primary-products-grid" v-else-if="eggInventory.length > 0">
          <div v-for="item in eggInventory" :key="item.id" class="product-card">
            <!-- TOP ROW: GRADE & STATUS -->
            <div class="card-header">
              <span class="card-name" :class="getChipClass(item.id)">{{ getGradeLabel(item.id) }}</span>
              <div class="status-badge" :class="`badge-${getStockStatus(item).class}`">
                <span v-if="getStockStatus(item).class === 'kritis'" class="dot-pulse" style="margin-right:6px"></span>
                {{ getStockStatus(item).label }}
              </div>
            </div>

            <!-- BIG NUMBER & PROGRESS -->
            <div class="stock-display">
              <h2 class="stock-number">{{ formatStockCount(item.current_stock) }}</h2>
              <span class="stock-unit">butir</span>
            </div>

            <div class="pack-count">{{ calcMaxPacks(item.current_stock) }} PACK</div>

            <div class="progress-bar-track">
              <div class="progress-bar-fill" 
                :class="`bg-${getStockStatus(item).class}`"
                :style="{ width: getStockProgress(item) + '%' }">
              </div>
            </div>

            <!-- MICRO STATS GRID -->
            <div class="metrics-row">
              <div class="metric-item">
                <span class="metric-label">RETAIL</span>
                <span class="metric-value">{{ formatCurrency(item.retail_price_per_pack || item.base_price_per_pack) }}</span>
              </div>
              <div class="metric-item">
                <span class="metric-label">HPP/BUTIR</span>
                <span class="metric-value">{{ formatCurrency(item.hpp_per_egg || item.cost_per_egg) }}</span>
              </div>
              <div class="metric-item">
                <span class="metric-label">HPP/PACK</span>
                <span class="metric-value">{{ formatCurrency((item.cost_per_egg * 10) + (item.cost_per_packaging || 0) + (item.cost_per_sticker || 0) + (item.cost_per_card || 0)) }}</span>
              </div>
            </div>

            <!-- BOTTOM ROW: SAFETY & ACTION -->
            <div class="card-footer">
              <div class="safety-info">
                <span class="safety-label">Safety:</span>
                <span class="safety-value">{{ item.safety_stock || 20 }} butir</span>
              </div>
              <button class="manage-btn" @click="quickAdjust(item.id)">
                <SettingsIcon class="icon-xs" />
                <span>MANAGE</span>
              </button>
            </div>
          </div>
        </div>
        <EmptyState v-else icon="PackageIcon" title="Inventory Kosong" message="Produk telur belum terdaftar di database." />
      </section>

      <!-- ━━━ SECTION: SUPPLIES & PACKAGING ━━━ -->
      <section class="inventory-section section-supplies">
        <div class="section-header">
          <div class="section-header-left">
            <span class="section-badge">SUPPLIES & PACKAGING</span>
            <div class="section-divider-line"></div>
          </div>
          <div class="section-header-right"></div>
        </div>
        
        <div class="supplies-grid" v-if="loading">
          <div v-for="i in 3" :key="i" class="skeleton-card-inventory mini"></div>
        </div>
        
        <div class="supplies-grid" v-else-if="supplyInventory.length > 0">
          <div v-for="item in supplyInventory" :key="item.id" class="supply-card">
            <div class="card-header">
              <span class="card-name">{{ item.label }}</span>
              <div class="status-badge" :class="item.current_stock <= (item.safety_stock || 20) ? 'badge-low' : 'badge-optimal'">
                {{ item.current_stock <= (item.safety_stock || 20) ? 'LOW' : 'OPTIMAL' }}
              </div>
            </div>

            <div class="stock-display" style="gap: 6px;">
              <h2 class="stock-number" style="color: #10b981;">{{ item.current_stock }}</h2>
              <span class="stock-unit">units</span>
            </div>

            <div class="progress-bar-track" style="margin-top: 12px; margin-bottom: 24px;">
              <div class="progress-bar-fill bg-optimal" :style="{ width: Math.min((item.current_stock / (item.safety_stock * 3 || 60)) * 100, 100) + '%' }"></div>
            </div>

            <div class="metrics-row" style="grid-template-columns: 1fr;">
              <div class="metric-item">
                <span class="metric-label">Effective Cost:</span>
                <span class="metric-value">{{ formatCurrency(item.cost_per_egg || 0) }}</span>
              </div>
            </div>

            <div class="card-footer">
              <div class="safety-info">
                <span class="safety-label">Safety:</span>
                <span class="safety-value">{{ item.safety_stock || 20 }} units</span>
              </div>
              <button class="supply-manage-btn" @click="openPackagingPurchase(item)">
                <PlusIcon class="icon-xs" />
                <span>MANAGE</span>
              </button>
            </div>
          </div>
        </div>
        <EmptyState v-else icon="PackageSearchIcon" title="Supplies Kosong" message="Belum ada data kemasan atau label." />
      </section>

    <!-- ━━━ SECTION: AUDIT TRAIL ━━━ -->
    <section class="audit-trail-section glass-panel">
      <div class="audit-header">
        <div>
          <h3 class="audit-title hero-font">Audit Trail</h3>
          <span class="audit-subtitle">Last 20 operations</span>
        </div>
        <div class="search-box-mini glass-panel audit-search">
          <SearchIcon class="icon-xs" />
          <input v-model="searchAuditLogQuery" placeholder="Filter log..." />
        </div>
      </div>
      
      <div class="audit-table-wrapper">
        <!-- FILTER PILLS -->
        <div class="filter-pills mb-4">
          <button
            v-for="type in ['ALL', 'ARRIVAL', 'SALE', 'SALE_OUT', 'MANUAL_ADJUSTMENT', 'OPNAME']"
            :key="type"
            class="filter-pill"
            :class="{ active: activeAuditFilter === type }"
            :style="activeAuditFilter === type ? {
              background: getAuditConfig(type).bg,
              borderColor: getAuditConfig(type).border,
              color: getAuditConfig(type).text
            } : {}"
            @click="activeAuditFilter = type"
          >
            {{ type.replace('_', ' ') }}
          </button>
        </div>

        <div v-if="loading" class="skeleton-table-rows">
          <div v-for="i in 5" :key="i" class="skeleton-row"></div>
        </div>
        
        <div v-else-if="logs.length > 0">
          <!-- 🖥️ PREMIUM GRID LIST (DESKTOP) -->
          <div class="audit-list-premium table-desktop">
            <div class="audit-header-grid">
              <span>TIMESTAMP</span>
              <span>TYPE</span>
              <span>CHANGE</span>
              <span>REASON</span>
              <span>ADMIN</span>
            </div>
            
            <div
              v-for="log in filteredLogs"
              :key="log.id"
              class="audit-row"
              :class="{ 'is-void': log.log_type?.includes('void') }"
              :style="{
                background: getAuditConfig(log.log_type).rowBg,
                borderLeft: `3px solid ${getAuditConfig(log.log_type).rowBorder}`
              }"
            >
              <!-- TIMESTAMP -->
              <div class="col-timestamp">
                <span class="time-relative">{{ formatRelativeDate(log.created_at) }}</span>
                <span class="time-exact">• {{ formatExactTime(log.created_at) }}</span>
              </div>

              <!-- TYPE BADGE -->
              <div class="col-type">
                <span
                  class="type-badge"
                  :style="{
                    background: getAuditConfig(log.log_type).bg,
                    border: `1px solid ${getAuditConfig(log.log_type).border}`,
                    color: getAuditConfig(log.log_type).text
                  }"
                >
                  <span class="type-icon">{{ getAuditConfig(log.log_type).icon }}</span>
                  {{ log.log_type?.replace('_', ' ').toUpperCase() }}
                </span>
              </div>

              <!-- CHANGE -->
              <div class="col-change">
                <span
                  class="change-value"
                  :class="{
                    'is-positive': log.change > 0,
                    'is-negative': log.change < 0,
                    'is-zero': log.change === 0
                  }"
                >
                  {{ log.change > 0 ? '+' : '' }}{{ log.change.toLocaleString('id-ID') }}
                </span>
              </div>

              <!-- REASON -->
              <div class="col-reason">
                <span
                  class="reason-text"
                  :style="{ color: !log.log_type?.includes('void') ? getAuditConfig(log.log_type).text : 'rgba(255,255,255,0.4)' }"
                >
                  {{ log.notes || '-' }}
                </span>
              </div>

              <!-- ADMIN -->
              <div class="col-admin">
                <span class="admin-text">System Admin</span>
              </div>
            </div>
          </div>

          <!-- 📱 MOBILE CARDS -->
          <div class="cards-mobile">
            <div 
              v-for="log in filteredLogs" 
              :key="'m-'+log.id" 
              class="mobile-audit-card glass-panel"
              :style="{ borderLeft: `3px solid ${getAuditConfig(log.log_type).text}` }"
            >
              <div class="mac-header">
                <span 
                  class="type-badge-mini" 
                  :style="{ color: getAuditConfig(log.log_type).text }"
                >
                  {{ getAuditConfig(log.log_type).icon }} {{ log.log_type?.replace('_', ' ').toUpperCase() }}
                </span>
                <span class="mac-time font-mono">{{ formatRelativeDate(log.created_at) }}</span>
              </div>
              <div class="mac-body">
                <div class="mac-change" :class="{ 'is-positive': log.change > 0, 'is-negative': log.change < 0 }">
                  {{ log.change > 0 ? '+' : '' }}{{ log.change.toLocaleString('id-ID') }} butir
                </div>
                <div class="mac-notes" :style="{ color: getAuditConfig(log.log_type).text }">{{ log.notes || '-' }}</div>
              </div>
            </div>
          </div>
        </div>
        <EmptyState v-else icon="HistoryIcon" title="Belum ada riwayat" message="Semua pergerakan stok akan tercatat di sini." />
      </div>
    </section>
    </div>

    <!-- ━━━ TAB 2: PEMBELIAN & GRADING ━━━ -->
    <div v-else-if="activeTab === 'pembelian'" class="tab-content pembelian-tab animate-fade">
      <div class="pembelian-card">
        <div class="pembelian-card-header">
          <div>
            <h3 class="pembelian-card-title hero-font">Riwayat Pembelian</h3>
            <p class="pembelian-card-sub">Catatan seluruh pembelian dari supplier</p>
          </div>
          <button class="catat-btn" @click="showChoiceModal = true">
            <PlusIcon class="icon-xs" />
            + Catat Pembelian Baru
          </button>
        </div>

        <div class="pembelian-kpi-row">
          <div class="kpi-card">
            <div class="kpi-label">TOTAL PEMBELIAN</div>
            <div class="kpi-value">{{ formatCurrency(purchaseStats.totalCost) }}</div>
          </div>
          <div class="kpi-card">
            <div class="kpi-label">TOTAL BUTIR</div>
            <div class="kpi-value">{{ purchaseStats.totalEggs.toLocaleString('id-ID') }}</div>
          </div>
          <div class="kpi-card utang">
            <div class="kpi-label">UTANG AKTIF</div>
            <div class="kpi-value">{{ formatCurrency(purchaseStats.totalDebt) }}</div>
          </div>
        </div>

        <div class="pembelian-divider"></div>

        <div v-if="purchases.length === 0" class="empty-state">
          <div class="empty-icon">📦</div>
          <h4 class="empty-title">Belum Ada Pembelian</h4>
          <p class="empty-sub">Klik tombol '+ Catat Pembelian Baru' di atas untuk mencatat batch pertama.</p>
        </div>

        <table v-else class="pembelian-table">
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
            <tr v-for="p in purchases" :key="p.id">
              <td><strong>{{ formatDate(p.purchase_date || p.created_at) }}</strong></td>
              <td>{{ suppliers.find(s => s.id === p.supplier_id)?.name || '-' }}</td>
              <td>{{ p.total_eggs_bought.toLocaleString('id-ID') }}</td>
              <td>{{ formatCurrency(p.price_per_egg) }}</td>
              <td><strong>{{ formatCurrency(p.total_cost) }}</strong></td>
              <td>
                <span class="status-badge" :class="p.status">
                  {{ p.status === 'lunas' ? 'LUNAS' : p.status === 'cicilan' ? 'CICILAN' : 'UTANG' }}
                </span>
              </td>
              <td :class="p.remaining_debt > 0 ? 'text-red font-bold' : 'text-green'">
                {{ formatCurrency(p.remaining_debt || 0) }}
              </td>
              <td>
                <button 
                  v-if="p.remaining_debt > 0"
                  class="btn-secondary" 
                  @click="openDetails(p)"
                >Detail →</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- ━━━ FEATURE 1: STOK OPNAME SECTION ━━━ -->
    <div v-else-if="activeTab === 'stok_opname'" class="tab-content opname-tab animate-fade">
      <!-- INFO BANNER FULL WIDTH -->
      <div class="tips-banner">
        <div class="tips-icon">💡</div>
        <div class="tips-text">
          <strong>Tips:</strong> Gunakan tab ini khusus untuk pencatatan verifikasi fisik bulanan/mingguan. Untuk input barang datang (Restock), gunakan tombol <strong>TAMBAH STOK BARU</strong> di pojok kanan atas.
        </div>
      </div>

      <div class="stok-opname-layout">
        <!-- Dashboard / History -->
        <div v-if="!activeStokTake" class="opname-card">
          <div class="opname-card-header">
            <div>
              <h2 class="opname-title hero-font">Pusat Verifikasi Stok</h2>
              <p class="opname-sub">Audit dan sinkronisasi stok fisik dengan pencatatan digital secara akurat.</p>
            </div>
            <button 
              v-if="authStore.profile?.role === 'admin'"
              class="opname-start-btn" 
              @click="startNewStokOpname"
              :disabled="loadingSO"
            >
              <PlusIcon class="icon-sm" />
              MULAI STOK OPNAME BARU
            </button>
          </div>

          <div class="riwayat-header">
             <div class="riwayat-label">RIWAYAT VERIFIKASI</div>
             <div class="riwayat-line"></div>
          </div>

          <table class="opname-table table-desktop" v-if="opnameHistory.length > 0">
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
                  <tr v-for="so in opnameHistory" :key="so.id">
                  <td><strong>{{ formatDate(so.opname_date) }}</strong></td>
                  <td>{{ so.conducted_by }}</td>
                  <td :class="so.total_difference < 0 ? 'text-red' : 'text-green'">
                      <strong>{{ so.total_difference > 0 ? '+' : '' }}{{ formatStockCount(so.total_difference || 0) }}</strong>
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

          <div v-if="opnameHistory.length === 0" class="empty-state">
              <div class="empty-icon">📋</div>
              <h4 class="empty-title">Riwayat Masih Kosong</h4>
              <p class="empty-sub">Belum ada riwayat verifikasi. Klik 'MULAI STOK OPNAME BARU' untuk sinkronisasi stok fisik pertama Anda.</p>
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

    <RestockSuppliesSlideOver 
      :show="showSuppliesSlideOver" 
      @close="showSuppliesSlideOver = false"
      @restockDone="fetchData"
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
              <textarea v-model="form.notes" v-titlecase placeholder="Tuliskan alasan perubahan..."></textarea>
            </div>

            <div class="modal-actions">
              <button type="button" class="btn-secondary" @click="showAdjustmentModal = false">BATAL</button>
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
          <h2 class="hero-font">Manage {{ packForm.label }}</h2>
          <p class="text-dim">Update stock levels manually or via purchase.</p>

          <form @submit.prevent="submitPackagingPurchase" class="modal-form">
            <!-- Mode Selector -->
            <div class="form-group">
              <div class="segmented-control">
                <button 
                  type="button" 
                  :class="{ active: packForm.mode === 'restock' }"
                  @click="packForm.mode = 'restock'"
                >PEMBELIAN</button>
                <button 
                  type="button" 
                  :class="{ active: packForm.mode === 'adjust' }"
                  @click="packForm.mode = 'adjust'"
                >KOREKSI</button>
              </div>
            </div>

            <!-- RESTOCK MODE FIELDS -->
            <template v-if="packForm.mode === 'restock'">
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
            </template>

            <!-- ADJUST MODE FIELDS -->
            <template v-else>
              <div class="form-group">
                <label>Perubahan Stok (+ / -)</label>
                <input type="number" v-model.number="packForm.qty" placeholder="e.g. -5 to reduce" required />
                <p class="text-dim mini-text">Gunakan tanda minus (-) untuk mengurangi stok.</p>
              </div>
              <div class="form-group">
                <label>Catatan Koreksi</label>
                <textarea v-model="packForm.notes" v-titlecase placeholder="Contoh: Stok rusak atau hilang..." rows="2"></textarea>
              </div>
            </template>

            <div class="modal-actions">
              <button type="button" class="btn-secondary" @click="showPackagingModal = false">Cancel</button>
              <button type="submit" class="btn-primary" :disabled="submitting">
                {{ submitting ? 'PROCESSING...' : (packForm.mode === 'restock' ? 'CONFIRM PURCHASE' : 'UPDATE STOCK') }}
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
import { withTimeout } from '../utils/safeAsync';
import { useRoute } from 'vue-router';
import CustomDropdown from '../components/ui/CustomDropdown.vue';
import StockHistoryModal from '../components/modals/StockHistoryModal.vue';
import AddStockChoiceModal from '../components/inventory/AddStockChoiceModal.vue';
import PembelianTelurSlideOver from '../components/inventory/PembelianTelurSlideOver.vue';
import RestockSuppliesSlideOver from '../components/inventory/RestockSuppliesSlideOver.vue';
import { sanitizePayload } from '../utils/sanitize';
import { 
  PlusIcon,
  SearchIcon,
  SettingsIcon,
  TruckIcon,
  ClipboardListIcon,
  PackageIcon,
  RefreshCwIcon
} from 'lucide-vue-next';

// @ts-ignore
import { GRADES, getGradeLabel as getGlobalLabel, normalizeGrade } from '../constants/grades';

import { formatCurrency, formatStock, formatRelativeDate, formatExactTime } from '../utils/formatters';

import { calcMaxPacks } from '../utils/calculations';

function formatStockCount(val: number) {
  return formatStock(val);
}

function getGradeLabel(id: string) {
  return getGlobalLabel(id)
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
const searchInventoryQuery = ref('');
const searchAuditLogQuery = ref('');
const activeAuditFilter = ref('ALL');
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
const showSuppliesSlideOver = ref(false);
const confirmData = reactive({
  title: '',
  message: '',
  onConfirm: () => {}
});
const submitting = ref(false);

// removed priceHistory as it's folded into adjustment flow

// ━━━ PURCHASE STATE ━━━
const purchases = ref<any[]>([]);
const bankAccounts = ref<any[]>([]);
const purchaseStats = reactive({
  totalEggs: 0,
  totalCost: 0,
  totalDebt: 0
});

function calculatePurchaseStats() {
  let totalCost = 0, totalEggs = 0, totalDebt = 0;
  purchases.value.forEach(p => {
    totalCost += (p.total_cost || 0);
    totalEggs += (p.total_eggs_bought || 0);
    totalDebt += (p.remaining_debt || 0);
  });
  purchaseStats.totalCost = totalCost;
  purchaseStats.totalEggs = totalEggs;
  purchaseStats.totalDebt = totalDebt;
}


function getStockStatus(item: any) {
  const safety = item.safety_stock || 20;
  const current = item.current_stock;
  if (current <= safety) return { label: 'KRITIS', class: 'kritis' };
  if (current <= safety * 2) return { label: 'LOW', class: 'low' };
  return { label: 'OPTIMAL', class: 'optimal' };
}

function getChipClass(id: string) {
  const normalized = normalizeGrade(id)
  if (normalized === 'hero') return 'chip-hero'
  if (normalized === 'salted_egg') return 'chip-small'
  return ''
}

function getStockProgress(item: any) {
  const safety = item.safety_stock || 20;
  const max = safety * 3;
  return Math.min((item.current_stock / max) * 100, 100);
}

const AUDIT_TYPE_CONFIG: Record<string, any> = {
  'ARRIVAL': {
    bg:     'rgba(16, 185, 129, 0.12)',
    border: 'rgba(16, 185, 129, 0.25)',
    text:   '#10b981',
    icon:   '↙',
    rowBg:  'rgba(16, 185, 129, 0.03)',
    rowBorder: 'rgba(16, 185, 129, 0.08)'
  },
  'PURCHASE': {
    bg:     'rgba(16, 185, 129, 0.12)',
    border: 'rgba(16, 185, 129, 0.25)',
    text:   '#10b981',
    icon:   '↙',
    rowBg:  'rgba(16, 185, 129, 0.03)',
    rowBorder: 'rgba(16, 185, 129, 0.08)'
  },
  'SALE': {
    bg:     'rgba(56, 189, 248, 0.12)',
    border: 'rgba(56, 189, 248, 0.25)',
    text:   '#38bdf8',
    icon:   '↗',
    rowBg:  'rgba(56, 189, 248, 0.03)',
    rowBorder: 'rgba(56, 189, 248, 0.08)'
  },
  'SALE_OUT': {
    bg:     'rgba(239, 68, 68, 0.12)',
    border: 'rgba(239, 68, 68, 0.25)',
    text:   '#ef4444',
    icon:   '↗',
    rowBg:  'rgba(239, 68, 68, 0.03)',
    rowBorder: 'rgba(239, 68, 68, 0.08)'
  },
  'MANUAL_ADJUSTMENT': {
    bg:     'rgba(245, 158, 11, 0.12)',
    border: 'rgba(245, 158, 11, 0.25)',
    text:   '#f59e0b',
    icon:   '⚙',
    rowBg:  'rgba(245, 158, 11, 0.03)',
    rowBorder: 'rgba(245, 158, 11, 0.08)'
  },
  'SORTING_WASTE': {
    bg:     'rgba(245, 158, 11, 0.12)',
    border: 'rgba(245, 158, 11, 0.25)',
    text:   '#f59e0b',
    icon:   '⚙',
    rowBg:  'rgba(245, 158, 11, 0.03)',
    rowBorder: 'rgba(245, 158, 11, 0.08)'
  },
  'OPNAME': {
    bg:     'rgba(139, 92, 246, 0.12)',
    border: 'rgba(139, 92, 246, 0.25)',
    text:   '#8b5cf6',
    icon:   '📋',
    rowBg:  'rgba(139, 92, 246, 0.03)',
    rowBorder: 'rgba(139, 92, 246, 0.08)'
  },
  'VOID': {
    bg:     'rgba(239, 68, 68, 0.08)',
    border: 'rgba(239, 68, 68, 0.20)',
    text:   '#ef4444',
    icon:   '✕',
    rowBg:  'rgba(239, 68, 68, 0.04)',
    rowBorder: 'rgba(239, 68, 68, 0.10)'
  },
  'VOID_RETURN': {
    bg:     'rgba(239, 68, 68, 0.08)',
    border: 'rgba(239, 68, 68, 0.20)',
    text:   '#ef4444',
    icon:   '✕',
    rowBg:  'rgba(239, 68, 68, 0.04)',
    rowBorder: 'rgba(239, 68, 68, 0.10)'
  }
};

function getAuditConfig(type: string) {
  return AUDIT_TYPE_CONFIG[type?.toUpperCase()] ?? {
    bg: 'rgba(100,116,139,0.10)',
    border: 'rgba(100,116,139,0.20)',
    text: '#64748b',
    icon: '•',
    rowBg: 'transparent',
    rowBorder: 'transparent'
  };
}


const filteredLogs = computed(() => {
  let list = logs.value;
  
  if (activeAuditFilter.value !== 'ALL') {
    list = list.filter(l => l.log_type?.toUpperCase() === activeAuditFilter.value);
  }
  
  if (searchAuditLogQuery.value.trim()) {
    const q = searchAuditLogQuery.value.toLowerCase();
    list = list.filter(l => 
      l.notes?.toLowerCase().includes(q) || 
      l.log_type?.toLowerCase().includes(q)
    );
  }
  
  return list;
});


async function fetchPurchases() {
  const { data: pData } = await supabase.from('purchases').select('*').order('created_at', { ascending: false }).limit(50);
  if (pData) purchases.value = pData;
  calculatePurchaseStats();
}

const eggInventory = computed(() => {
  const items = inventory.value.filter(i => i.item_type !== 'packaging');
  if (!searchInventoryQuery.value) return items;
  const q = searchInventoryQuery.value.toLowerCase();
  return items.filter(i => 
    i.label?.toLowerCase().includes(q) || 
    getGradeLabel(i.id).toLowerCase().includes(q)
  );
});

const supplyInventory = computed(() => {
  const items = inventory.value.filter(i => i.item_type === 'packaging');
  if (!searchInventoryQuery.value) return items;
  const q = searchInventoryQuery.value.toLowerCase();
  return items.filter(i => i.label?.toLowerCase().includes(q));
});

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

function handleChoiceSelect(type: 'telur' | 'supplies') {
  showChoiceModal.value = false;
  if (type === 'telur') {
    showPembelianSlideOver.value = true;
  } else {
    showSuppliesSlideOver.value = true;
  }
}

async function handlePurchaseCreated() {
  showPembelianSlideOver.value = false;
  fetchData();
}



function openDetails(purchase: any) {
  showToast(`Detail pembelian ${purchase.id.slice(0,8)}...`, 'warning');
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
  supplier: '',
  notes: '',
  mode: 'restock' // 'restock' or 'adjust'
});

async function fetchData() {
  loading.value = true;
  try {
    const [
      { data: inv },
      { data: logData },
      { data: sup },
      { data: soData },
      { data: bAcc }
    ] = await withTimeout(Promise.all([
      supabase.from('inventory').select('*').order('id'),
      supabase.from('stock_logs').select('*').order('created_at', { ascending: false }).limit(20),
      supabase.from('suppliers').select('*').eq('is_deleted', false).order('name'),
      supabase.from('stock_opname').select('*').order('opname_date', { ascending: false }),
      supabase.from('bank_accounts').select('*').eq('is_active', true)
    ]), 15000, 'stock-fetch');

    if (inv) inventory.value = inv;
    if (logData) logs.value = logData;
    if (sup) suppliers.value = sup;
    if (soData) opnameHistory.value = soData;
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
      const { error: itemError } = await withTimeout(
        supabase.from('stock_opname_items').upsert(
          activeSOItems.value.map(i => ({
            opname_id: activeStokTake.value.id,
            inventory_id: i.inventory_id,
            grade: i.grade,
            system_count: i.system_count,
            physical_count: i.physical_count,
            difference: i.difference
          }))
        ),
        10000, 'so-upsert'
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
          
          // Insert adjusting log for initial SO alignment
          const soId = activeStokTake.value.id.slice(0,8);
          const difference = item.difference;
          await supabase.from('stock_logs').insert(sanitizePayload({
            inventory_id: item.inventory_id,
            log_type: 'stock_opname',
            change: difference,
            notes: `Penyesuaian awal Stock Opname #${soId}`,
            created_by: authStore.profile?.id
          }));
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
  packForm.notes = '';
  packForm.mode = 'restock';
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
  
  const isRestock = packForm.mode === 'restock';
  const effectiveCost = isRestock ? calculateEffectivePackCost() : 0;
  const changeQty = isRestock ? (packForm.qty - packForm.damaged) : packForm.qty;

  try {
    const currentItem = inventory.value.find(i => i.id === packForm.id);
    const newStock = (currentItem?.current_stock ?? 0) + changeQty;

    // 1. Update Packaging Inventory
    const updatePayload: any = { 
      current_stock: newStock, 
      updated_at: new Date().toISOString() 
    };
    
    // Only update cost if it's a restock/purchase
    if (isRestock) {
      updatePayload.cost_per_egg = effectiveCost;
    }

    const { error: invError } = await withTimeout(
      supabase.from('inventory').update(updatePayload).eq('id', packForm.id),
      8000, 'update-packaging-inv'
    );

    if (invError) throw invError;

    // 2. Log Transaction
    let finalNotes = '';
    if (isRestock) {
      const purchaseNotes = `Purchase: Rp${packForm.price.toLocaleString('id-ID')} + Rp${packForm.shipping.toLocaleString('id-ID')} ship (Waste: ${packForm.damaged})`;
      const supplierNote = packForm.supplier ? ` | Supplier: ${packForm.supplier}` : '';
      finalNotes = purchaseNotes + supplierNote;
    } else {
      finalNotes = packForm.notes || 'Koreksi stok manual';
    }

    await supabase.from('stock_logs').insert({
      egg_type: packForm.id,
      change: changeQty,
      log_type: isRestock ? 'arrival' : 'manual_adjustment',
      notes: finalNotes
    });

    // Create Notification
    await supabase.from('notifications').insert({
      type: isRestock ? 'restock_done' : 'stock_alert',
      title: isRestock ? 'Stok Diperbarui' : 'Koreksi Stok',
      message: `${packForm.label}: ${changeQty > 0 ? '+' : ''}${changeQty} unit`,
      link: '/stock'
    });

    // 3. Proactive Updates - ONLY for restock
    if (isRestock) {
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
    }

    showPackagingModal.value = false;
    fetchData();
    showToast(isRestock ? `Stok ${packForm.label} diperbarui & HPP telur dihitung ulang` : `Stok ${packForm.label} berhasil dikoreksi`);
  } catch (err: any) {
    showToast('Gagal memproses stok', 'error');
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
    const updateInventory = supabase.from('inventory').update({
      base_price_per_pack: editForm.base_price_per_pack,
      cost_per_egg: editForm.cost_per_egg,
      cost_price: newCostPrice,
      updated_at: new Date().toISOString()
    }).eq('id', editForm.id);

    const priceHistoryTask = (async () => {
      const authorName = authStore.profile?.full_name || 'Admin';
      if (editForm.base_price_per_pack !== editForm.old_base_price) {
        return supabase.from('price_history').insert({
          inventory_id: editForm.id,
          price_type: 'selling',
          old_value: editForm.old_base_price,
          new_value: editForm.base_price_per_pack,
          changed_by: authorName,
          reason: form.notes
        });
      }
    })();

    const [invRes] = await Promise.all([updateInventory, priceHistoryTask]);

    if (!invRes.error) {
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

  const { data: logData, error: logError } = await withTimeout(
    supabase.from('stock_logs').insert(sanitizePayload({
      inventory_id: form.egg_type,
      log_type: form.log_type,
      change: finalChange,
      unit_price: form.log_type === 'arrival' ? effectiveEggCost : 0,
      notes: finalNotes,
      created_by: authStore.profile?.id
    })).select(),
    8000, 'insert-stock-log'
  );

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
  padding: 32px 40px 64px;
  width: 100%;
  max-width: 100%;
  margin: 0;
  display: flex;
  flex-direction: column;
  gap: 0;
  box-sizing: border-box;
}

/* Gap between PAGE HEADER and TABS */
.header { margin-bottom: 32px; width: 100%; }

/* Gap between TABS and CONTENT */
.tab-content { margin-top: 0; width: 100%; }

/* Gap between PRIMARY PRODUCTS section and SUPPLIES section */
.section-primary-products { margin-bottom: 40px; }

/* Gap between SUPPLIES section and AUDIT TRAIL */
.section-supplies { margin-bottom: 40px; }

/* PURCHASE STATS ROW */
.purchase-stats-row {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 12px;
}

@media (max-width: 768px) {
  .stock-page { padding: 16px; }
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
  margin: 0 0 32px 0;
  padding: 0;
  display: flex;
  justify-content: flex-start;
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
.primary-products-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 16px;
  margin-top: 20px;
}

@media (max-width: 900px) {
  .primary-products-grid { grid-template-columns: 1fr; }
}

.supplies-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 16px;
  margin-top: 20px;
}

@media (max-width: 900px) {
  .supplies-grid { grid-template-columns: 1fr; }
}

/* ━━━ SECTION HEADERS ━━━ */
.section-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 20px;
}

.section-header-left {
  display: flex;
  align-items: center;
  gap: 16px;
  flex: 1;
}

.section-badge {
  font-family: var(--font-ui);
  font-size: 11px;
  font-weight: 800;
  color: var(--gold);
  letter-spacing: 2px;
  background: rgba(245, 158, 11, 0.10);
  padding: 6px 14px;
  border-radius: 4px;
  text-transform: uppercase;
  border: 1px solid rgba(245, 158, 11, 0.20);
  white-space: nowrap;
}

.section-divider-line {
  flex: 1;
  height: 1px;
  background: linear-gradient(to right, rgba(245,158,11,0.25), rgba(245,158,11,0.02));
}

.search-box-mini {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 16px;
  border-radius: 12px;
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid rgba(255, 255, 255, 0.08);
  transition: all 0.3s ease;
}

.search-box-mini:focus-within {
  background: rgba(255, 255, 255, 0.06);
  border-color: var(--gold);
  box-shadow: 0 0 0 4px rgba(245, 158, 11, 0.1);
}

.search-box-mini input {
  background: transparent;
  border: none;
  color: white;
  font-size: 13px;
  outline: none;
  width: 150px;
}

.search-box-mini input::placeholder {
  color: var(--muted);
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

/* ━━━ PRODUCT CARDS ━━━ */
.product-card, .supply-card {
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-radius: var(--radius-lg);
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 20px;
  position: relative;
  transition: border-color 200ms, box-shadow 200ms;
}

.product-card:hover, .supply-card:hover {
  transform: translateY(-4px);
  border-color: var(--border-hover);
  box-shadow: var(--shadow-premium);
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.card-name {
  padding: 4px 12px;
  border-radius: 100px;
  font-size: 12px;
  font-weight: 700;
  text-transform: uppercase;
  font-family: var(--font-ui);
}

/* Base chips from getChipClass */
.chip-hero { background: var(--gold); color: black; }
.chip-small { background: var(--sky); color: black; }

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

.badge-optimal { background: rgba(16, 185, 129, 0.15); color: var(--green); border-color: rgba(16, 185, 129, 0.3); }
.badge-low { background: rgba(245, 158, 11, 0.15); color: var(--gold); border-color: rgba(245, 158, 11, 0.3); }
.badge-kritis { 
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
.stock-display {
  display: flex;
  align-items: baseline;
  gap: 8px;
}

.stock-number {
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

.pack-count {
  font-size: 18px;
  font-weight: 600;
  color: white;
  text-align: right;
  margin-top: -12px;
}

/* ━━━ PROGRESS BAR ━━━ */
.progress-bar-track {
  height: 6px;
  background: rgba(255, 255, 255, 0.05);
  border-radius: 100px;
  overflow: hidden;
  margin-top: 4px;
}

.progress-bar-fill {
  height: 100%;
  border-radius: 100px;
  transition: width 0.6s cubic-bezier(0.23, 1, 0.32, 1);
}

.bg-optimal { background: var(--green); }
.bg-low { background: var(--gold); }
.bg-kritis { background: var(--red); }

/* ━━━ MICRO STATS ━━━ */
.metrics-row {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 12px;
  padding: 16px 0;
  border-top: 1px solid var(--border);
  border-bottom: 1px solid var(--border);
  margin-top: 8px;
}

.metric-item {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.metric-label {
  font-size: 10px;
  font-weight: 700;
  color: var(--muted);
}

.metric-value {
  font-size: 13px;
  font-weight: 600;
  color: white;
}

/* ━━━ FOOTER ━━━ */
.card-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 4px;
}

.safety-info {
  display: flex;
  gap: 6px;
  font-size: 12px;
}

.safety-label { color: var(--muted); }
.safety-value { color: white; font-weight: 600; }

.manage-btn, .supply-manage-btn {
  display: flex;
  align-items: center;
  gap: 8px;
  font-weight: 800;
  font-size: 11px;
  padding: 8px 16px;
  border-radius: 10px;
  cursor: pointer;
  transition: all 0.2s ease;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.manage-btn {
  background: var(--gold);
  color: black;
  border: none;
}

.manage-btn:hover {
  filter: brightness(1.1);
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(245, 158, 11, 0.2);
}

.supply-manage-btn {
  background: transparent;
  border: 1px solid rgba(255, 140, 0, 0.3);
  color: var(--gold);
}

.supply-manage-btn:hover {
  background: rgba(255, 140, 0, 0.05);
  border-color: var(--gold);
  color: white;
}

/* ━━━ AUDIT TRAIL ━━━ */
.audit-trail-section {
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-radius: var(--radius-lg);
  padding: 28px;
  position: relative;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.audit-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 1px solid rgba(255, 255, 255, 0.05);
  padding-bottom: 16px;
}

.audit-title { font-size: 1.25rem; color: white; margin-bottom: 2px; }
.audit-subtitle { font-size: 0.85rem; color: var(--muted); }

.audit-table-wrapper {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.audit-filters {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
  padding-top: 4px;
}

.audit-list-premium {
  display: flex;
  flex-direction: column;
}

.audit-header-grid {
  display: grid;
  grid-template-columns: 160px 180px 80px 1fr 140px;
  gap: 16px;
  padding: 12px 20px;
  padding-left: 17px;
  font-size: 10px;
  font-weight: 800;
  letter-spacing: 1px;
  color: var(--muted);
  border-bottom: 1px solid var(--border);
  text-transform: uppercase;
}

.audit-row {
  display: grid;
  grid-template-columns: 160px 180px 80px 1fr 140px;
  align-items: center;
  gap: 16px;
  padding: 16px 20px;
  min-height: 64px;
  border-bottom: 1px solid rgba(255,255,255,0.04);
  transition: background 150ms;
  padding-left: 17px;
}
.audit-row:hover { background: rgba(255,255,255,0.02); }
.audit-row:last-child { border-bottom: none; }

.audit-row.is-void {
  opacity: 0.5;
}
.audit-row.is-void .reason-text {
  text-decoration: line-through;
}

/* Timestamp */
.col-timestamp { display: flex; flex-direction: column; gap: 2px; }
.time-relative {
  font-size: 13px;
  font-weight: 600;
  color: white;
}
.time-exact {
  font-size: 11px;
  color: rgba(255,255,255,0.35);
}

/* Type badge */
.type-badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 4px 10px;
  border-radius: 20px;
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.5px;
  white-space: nowrap;
}
.type-icon {
  font-size: 12px;
}

/* Change value */
.change-value {
  font-family: var(--font-mono);
  font-size: 15px;
  font-weight: 700;
}
.is-positive { color: var(--green); }
.is-negative { color: var(--red); }
.is-zero     { color: #64748b; }

/* Reason */
.reason-text {
  font-size: 13px;
  font-weight: 500;
}

/* Admin */
.admin-text {
  font-size: 11px;
  color: rgba(255,255,255,0.35);
}

/* Filter Pills */
.filter-pills {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}
.filter-pill {
  padding: 6px 14px;
  border-radius: 20px;
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.5px;
  border: 1px solid rgba(255,255,255,0.10);
  background: transparent;
  color: rgba(255,255,255,0.45);
  cursor: pointer;
  transition: all 150ms;
  text-transform: uppercase;
}
.filter-pill:hover {
  color: white;
  border-color: rgba(255,255,255,0.20);
}
.filter-pill.active {
  font-weight: 800;
}

/* Mobile Adjustments */
.type-badge-mini {
  font-size: 11px;
  font-weight: 800;
  letter-spacing: 1px;
}

.mac-change.is-positive { color: var(--green); }
.mac-change.is-negative { color: var(--red); }

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
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.85);
  backdrop-filter: blur(8px);
  z-index: 9999;
  display: flex;
  align-items: flex-start; /* Permudah scroll dari atas */
  justify-content: center;
  padding: 40px 20px; /* Tambah padding atas bawah agar tidak nempel layar */
  overflow-y: auto; /* Aktifkan scroll pada overlay */
}

.modal-card {
  width: 100%;
  max-width: 500px;
  background: var(--bg-card);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 24px;
  padding: 40px;
  box-shadow: 0 40px 100px -20px rgba(0,0,0,0.8);
  position: relative;
  margin-bottom: 40px; /* Margin bawah agar tidak nempel ujung saat scroll */
}

.modal-card .hero-font {
  font-size: 1.8rem;
  margin-bottom: 8px;
}

.modal-form {
  margin-top: 32px;
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
  font-size: 11px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 1px;
  color: var(--muted);
}

.form-group input,
.form-group textarea {
  width: 100%;
  box-sizing: border-box;
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 12px;
  padding: 14px 16px;
  color: white;
  font-family: inherit;
  font-size: 15px;
  transition: all 0.3s ease;
  outline: none;
}

/* Neutralize number spinners */
.form-group input[type="number"]::-webkit-inner-spin-button,
.form-group input[type="number"]::-webkit-outer-spin-button {
  -webkit-appearance: none;
  margin: 0;
}
.form-group input[type="number"] {
  -moz-appearance: textfield;
  appearance: textfield;
}

.form-group input:focus,
.form-group textarea:focus {
  border-color: var(--gold);
  background: rgba(255, 255, 255, 0.06);
  box-shadow: 0 0 0 4px rgba(245, 158, 11, 0.1);
}

.form-group textarea {
  min-height: 100px;
  resize: vertical;
}

.info-box {
  background: rgba(99, 102, 241, 0.05);
  border: 1px solid rgba(99, 102, 241, 0.2);
  border-radius: 16px;
  padding: 20px;
}

.segmented-control {
  display: grid;
  grid-template-columns: 1fr 1fr;
  background: rgba(255, 255, 255, 0.04);
  padding: 4px;
  border-radius: 12px;
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.segmented-control button {
  background: transparent;
  border: none;
  color: #64748b;
  padding: 10px;
  font-size: 11px;
  font-weight: 800;
  letter-spacing: 1.5px;
  border-radius: 9px;
  cursor: pointer;
  transition: all 0.3s ease;
}

.segmented-control button.active {
  background: var(--gold);
  color: black;
  box-shadow: 0 4px 12px rgba(245, 158, 11, 0.3);
}

.calc-result {
  font-size: 1.8rem;
  font-weight: 900;
  color: white;
  margin: 12px 0;
  font-family: var(--font-mono);
}

.btn-link-xs {
  background: transparent;
  border: none;
  color: var(--gold);
  font-size: 11px;
  font-weight: 800;
  cursor: pointer;
  padding: 0;
  transition: opacity 0.2s ease;
}

.btn-link-xs:hover {
  text-decoration: underline;
  opacity: 0.8;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

.modal-actions {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
  margin-top: 20px;
}

.btn-secondary {
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
  color: white;
  padding: 14px;
  border-radius: 12px;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.2s ease;
}

.btn-secondary:hover {
  background: rgba(255, 255, 255, 0.1);
}

.btn-primary {
  background: var(--gold);
  color: black;
  border: none;
  padding: 14px;
  border-radius: 12px;
  font-weight: 800;
  cursor: pointer;
  transition: all 0.2s ease;
}

.btn-primary:hover {
  filter: brightness(1.1);
  transform: translateY(-2px);
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

/* ========================================================================= */
/* FIX TAB LAYOUT WIDTHS                                                     */
/* ========================================================================= */
.tab-content,
.tab-panel,
[class*="tab-content"],
[class*="pembelian"],
[class*="opname"] {
  width: 100% !important;
  max-width: 100% !important;
  margin: 0 !important;
}

.stock-tabs {
  display: flex;
  gap: 4px;
  background: rgba(255,255,255,0.04);
  border: 1px solid rgba(255,255,255,0.08);
  border-radius: 12px;
  padding: 4px;
  width: fit-content;
  margin-top: 0;
  margin-bottom: 0;
}
.tab-item {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 20px;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: all 150ms;
  color: rgba(255,255,255,0.45);
  background: transparent;
  border: none;
  white-space: nowrap;
}
.tab-item.active { background: #f59e0b; color: #000; }
.tab-item:not(.active):hover { color: white; background: rgba(255,255,255,0.06); }

/* PEMBELIAN TAB REDESIGN */
.pembelian-tab {
  width: 100%;
  display: flex;
  flex-direction: column;
  gap: 0;
  margin-top: 28px;
}
.pembelian-card {
  background: #141418;
  border: 1px solid rgba(255,255,255,0.08);
  border-radius: 16px;
  padding: 28px;
  width: 100%;
  box-sizing: border-box;
}
.pembelian-card-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  margin-bottom: 24px;
}
.pembelian-card-title {
  font-size: 18px;
  font-weight: 700;
  color: white;
  margin-bottom: 4px;
}
.pembelian-card-sub { font-size: 13px; color: rgba(255,255,255,0.40); }
.catat-btn {
  background: #f59e0b; color: #000; border: none; border-radius: 10px;
  padding: 10px 20px; font-size: 13px; font-weight: 700; cursor: pointer;
  display: flex; align-items: center; gap: 8px; white-space: nowrap;
  transition: filter 150ms, transform 150ms; flex-shrink: 0;
}
.catat-btn:hover { filter: brightness(1.10); transform: scale(1.02); }
.pembelian-kpi-row { display: grid; grid-template-columns: repeat(3, 1fr); gap: 16px; margin-bottom: 28px; }
.kpi-card { 
  background: rgba(255,255,255,0.03); 
  border: 1px solid rgba(255,255,255,0.06); 
  border-radius: 12px; 
  padding: 20px; 
  transition: border-color 200ms, transform 200ms;
}
.kpi-card:hover { 
  border-color: rgba(255,255,255,0.15); 
  transform: translateY(-2px); 
}
.kpi-label { font-size: 10px; font-weight: 700; letter-spacing: 1.5px; color: rgba(255,255,255,0.45); text-transform: uppercase; margin-bottom: 8px; }
.kpi-value { font-size: 24px; font-weight: 700; color: white; font-family: 'DM Mono', monospace; }
.kpi-card.utang .kpi-value { color: #ef4444; }
.kpi-card.utang { border-color: rgba(239,68,68,0.15); background: rgba(239,68,68,0.04); }
.pembelian-divider { height: 1px; background: rgba(255,255,255,0.06); margin-bottom: 28px; }
.pembelian-table { width: 100%; border-collapse: collapse; }
.pembelian-table th { font-size: 10px; font-weight: 700; letter-spacing: 1.5px; color: rgba(255,255,255,0.30); text-transform: uppercase; padding: 8px 12px; text-align: left; border-bottom: 1px solid rgba(255,255,255,0.06); }
.pembelian-table td { padding: 16px 12px; font-size: 13px; color: rgba(255,255,255,0.80); border-bottom: 1px solid rgba(255,255,255,0.04); vertical-align: middle; }
.pembelian-table tr:last-child td { border-bottom: none; }
.pembelian-table tr:hover td { background: rgba(255,255,255,0.02); }

/* ━━━ OPNAME TAB PREMIUM REDESIGN ━━━ */
.opname-tab { 
  width: 100%; 
  margin-top: 32px; 
  display: flex; 
  flex-direction: column; 
  gap: 24px; 
}

/* ━━━ TIPS BANNER ━━━ */
.tips-banner { 
  width: 100%; 
  background: rgba(56, 189, 248, 0.04); 
  border: 1px solid rgba(56, 189, 248, 0.12); 
  border-radius: 12px; 
  padding: 16px 20px; 
  display: flex; 
  align-items: center; 
  gap: 14px; 
  box-sizing: border-box; 
}
.tips-icon { 
  font-size: 20px; 
  flex-shrink: 0; 
  line-height: 1;
}
.tips-text { 
  font-size: 13px; 
  color: rgba(255, 255, 255, 0.50); 
  line-height: 1.6; 
  margin: 0; 
}
.tips-text strong { 
  color: #38bdf8; 
  font-weight: 700; 
}

/* ━━━ MAIN CARD ━━━ */
.stok-opname-layout { width: 100%; }
.opname-card { 
  background: #111114; 
  border: 1px solid rgba(255, 255, 255, 0.05); 
  border-radius: 20px; 
  padding: 40px; 
  width: 100%; 
  box-sizing: border-box; 
  box-shadow: 0 10px 40px -10px rgba(0,0,0,0.5);
}

/* ━━━ REFINED HEADER (FIXED BOX MODEL) ━━━ */
.opname-card-header { 
  display: flex; 
  align-items: flex-start; /* Align to top to prevent weird centering */
  justify-content: space-between; 
  gap: 40px; 
  margin-bottom: 32px; 
  padding-bottom: 32px; 
  border-bottom: 1px solid rgba(255, 255, 255, 0.04); 
}
.opname-card-header > div:first-child {
  flex: 1; /* Title container takes sremaining space */
  min-width: 300px; /* Ensure title doesn't squeeze too much */
}
.opname-title { 
  font-size: 24px; 
  font-weight: 800; 
  color: #fff; 
  margin: 0 0 10px; 
  letter-spacing: -0.5px;
  line-height: 1.2;
}
.opname-sub { 
  font-size: 14px; 
  color: rgba(255, 255, 255, 0.35); 
  margin: 0; 
  line-height: 1.6; 
  max-width: 500px;
}

/* ━━━ BUTTON STYLING (FIXED WIDTH) ━━━ */
.opname-start-btn { 
  width: auto !important; /* Force override of any global resets */
  background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
  color: #000; 
  border: none; 
  border-radius: 12px; 
  padding: 14px 28px; 
  font-size: 13px; 
  font-weight: 800; 
  cursor: pointer; 
  display: flex; 
  align-items: center; 
  gap: 10px; 
  white-space: nowrap; 
  flex-shrink: 0; /* Important: prevents button from squashing */
  transition: all 200ms ease;
  box-shadow: 0 4px 12px rgba(245, 158, 11, 0.2);
}
.opname-start-btn:hover { 
  transform: translateY(-2px);
  box-shadow: 0 8px 20px rgba(245, 158, 11, 0.3);
  filter: brightness(1.1);
}
.opname-start-btn:active { transform: translateY(0); }

/* ━━━ SECTION DIVIDER ━━━ */
.riwayat-header { 
  display: flex; 
  align-items: center; 
  gap: 20px; 
  margin-bottom: 28px; 
}
.riwayat-label { 
  font-size: 11px; 
  font-weight: 700; 
  letter-spacing: 2.5px; 
  color: rgba(255, 255, 255, 0.35); 
  text-transform: uppercase; 
  white-space: nowrap; 
}
.riwayat-line { 
  flex: 1; 
  height: 1px; 
  background: linear-gradient(90deg, rgba(255, 255, 255, 0.08) 0%, transparent 100%); 
}

/* ━━━ TABLE REFINEMENT ━━━ */
.opname-table { width: 100%; border-collapse: collapse; }
.opname-table th { 
  font-size: 10px; 
  font-weight: 700; 
  letter-spacing: 1.5px; 
  color: rgba(255, 255, 255, 0.30); 
  text-transform: uppercase; 
  padding: 12px; 
  text-align: left; 
  border-bottom: 1px solid rgba(255, 255, 255, 0.06); 
}
.opname-table td { 
  padding: 20px 12px; 
  font-size: 14px; 
  color: rgba(255, 255, 255, 0.70); 
  border-bottom: 1px solid rgba(255, 255, 255, 0.03); 
  vertical-align: middle; 
}
.opname-table tr:hover td { background: rgba(255, 255, 255, 0.015); }
.opname-table tr:last-child td { border-bottom: none; }

/* ━━━ EMPTY STATE ━━━ */
.empty-state { 
  display: flex; 
  flex-direction: column; 
  align-items: center; 
  justify-content: center; 
  padding: 80px 40px; 
  text-align: center; 
  background: rgba(255, 255, 255, 0.01);
  border-radius: 16px;
  border: 1px dashed rgba(255, 255, 255, 0.04);
}
.empty-icon { 
  font-size: 56px; 
  margin-bottom: 24px; 
  line-height: 1;
}
.empty-title { 
  font-size: 18px; 
  font-weight: 700; 
  color: #fff; 
  margin: 0 0 10px; 
}
.empty-sub { 
  font-size: 14px; 
  color: rgba(255, 255, 255, 0.35); 
  margin: 0; 
  max-width: 400px; 
  line-height: 1.6; 
}

/* HELPER CLASSES */
.status-badge { 
  display: inline-flex; 
  align-items: center; 
  padding: 4px 12px; 
  border-radius: 30px; 
  font-size: 11px; 
  font-weight: 700; 
  letter-spacing: 0.5px;
}
.status-badge.completed { background: rgba(16, 185, 129, 0.1); color: #10b981; border: 1px solid rgba(16, 185, 129, 0.1); }
.status-badge.draft { background: rgba(245, 158, 11, 0.1); color: #f59e0b; border: 1px solid rgba(245, 158, 11, 0.1); }

.mono { font-family: 'DM Mono', monospace; font-weight: 500; }
.text-red { color: #ef4444; }
.text-green { color: #10b981; }


/* RESPONSIVE OVERRIDES */
@media (max-width: 768px) {
  .pembelian-card { padding: 16px; }
  .pembelian-card-header { flex-direction: column; }
  .pembelian-kpi-row { grid-template-columns: 1fr; gap: 10px; }
  .catat-btn { width: 100%; justify-content: center; }
  .opname-card { padding: 16px; }
  .opname-card-header { flex-direction: column; gap: 16px; }
  .opname-start-btn { width: 100%; justify-content: center; }
  .tips-banner { padding: 12px 14px; }
  .opname-table { display: none; }
}
</style>

