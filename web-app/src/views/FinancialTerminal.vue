<template>
  <div class="financial-terminal animate-fade-in">
    <!-- HEADER SECTION -->
    <header class="terminal-header">
      <div class="header-left">
        <h1 class="gradient-text hero-font">Financial Terminal</h1>
        <p class="text-dim">Pusat laporan keuangan Hero Farm</p>
      </div>

      <!-- GLOBAL DATE FILTER -->
      <div class="header-right">
        <div class="date-filter-group glass-panel">
          <button 
            v-for="p in periods" 
            :key="p.id"
            @click="activePeriod = p.id"
            :class="['period-btn', { active: activePeriod === p.id }]"
          >
            {{ p.label }}
          </button>
          <div class="date-divider"></div>
          <div class="date-display">
            <span class="range-text">{{ formattedDateRange }}</span>
            <button class="btn-apply" @click="fetchData">Apply</button>
          </div>
        </div>
      </div>
    </header>

    <!-- TAB NAVIGATION -->
    <nav class="tab-nav glass-panel">
      <button 
        v-for="t in tabs" 
        :key="t.id"
        @click="activeTab = t.id"
        :class="['tab-pill', { active: activeTab === t.id }]"
      >
        <component :is="t.icon" class="icon-sm" />
        <span>{{ t.label }}</span>
      </button>
    </nav>

    <!-- TAB CONTENT AREA -->
    <main class="terminal-content">
      <transition name="tab-fade" mode="out-in">
        <div :key="activeTab" class="tab-pane">
          
          <!-- 📊 TAB 1: P&L OVERVIEW -->
          <div v-if="activeTab === 'pnl'" class="tab-pnl">
            <!-- KPI ROW -->
            <div class="kpi-grid">
              <div v-for="k in pnlKpis" :key="k.label" class="kpi-card glass-panel animate-fade-up" :style="{ '--delay': k.delay }">
                <div class="kpi-header">
                  <span class="kpi-label">{{ k.label }}</span>
                  <div v-if="k.trend !== 0" class="trend-pill" :class="k.trend > 0 ? 'up' : 'down'">
                    <component :is="k.trend > 0 ? TrendingUpIcon : TrendingDownIcon" class="icon-xs" />
                    {{ Math.abs(k.trend).toFixed(1) }}%
                  </div>
                </div>
                <div class="kpi-body">
                  <h2 class="kpi-value" :class="k.color">{{ k.prefix }}{{ k.displayValue }}{{ k.suffix }}</h2>
                </div>
              </div>
            </div>

            <!-- CHART & TABLE ROW -->
            <div class="pnl-main-grid">
              <!-- CHART -->
              <div class="glass-panel pnl-chart-box">
                <div class="box-header">
                  <h3>Revenue vs HPP vs Profit</h3>
                </div>
                <div class="chart-wrapper">
                  <LineChart :data="pnlChartData" :options="pnlChartOptions" />
                </div>
              </div>

              <!-- P&L TABLE (Formal) -->
              <div class="glass-panel formal-pnl-box">
                <div class="box-header">
                  <h3>Laporan Laba Rugi</h3>
                </div>
                <div class="pnl-table-formal">
                  <div class="pnl-sec">
                    <div class="sec-title">PENDAPATAN</div>
                    <div v-for="item in pnlRevenueBreakdown" :key="item.label" class="pnl-row">
                      <span>{{ item.label }}</span>
                      <div class="pnl-vals">
                        <span class="pnl-money">{{ formatIDR(item.value) }}</span>
                        <span class="pnl-perc">{{ item.perc.toFixed(1) }}%</span>
                      </div>
                    </div>
                    <div class="pnl-row total teal">
                      <span>TOTAL PENDAPATAN</span>
                      <span class="pnl-money">{{ formatIDR(pnlSummary.revenue) }}</span>
                    </div>
                  </div>

                  <div class="pnl-sec">
                    <div class="sec-title">HPP / BEBAN POKOK</div>
                    <!-- HPP Breakdown per Item -->
                    <div v-for="b in pnlHppBreakdown" :key="b.label" class="pnl-row sub-row pl-4">
                      <span class="text-dim">{{ b.label }}</span>
                      <div class="pnl-vals">
                        <span class="pnl-money text-dim">{{ formatIDR(b.value) }}</span>
                        <span class="pnl-perc text-dim italic">{{ b.perc.toFixed(1) }}%</span>
                      </div>
                    </div>
                    <div class="pnl-row total red">
                      <span>TOTAL HPP</span>
                      <span class="pnl-money">{{ formatIDR(pnlSummary.totalHPP) }}</span>
                    </div>
                  </div>

                  <div class="pnl-grand-total">
                    <div class="gt-row">
                      <span class="gt-label">LABA KOTOR</span>
                      <span class="gt-val green">{{ formatIDR(pnlSummary.grossProfit) }}</span>
                    </div>
                    <div class="gt-row">
                      <span class="gt-label">MARGIN</span>
                      <span class="gt-val">{{ pnlSummary.margin.toFixed(1) }}%</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <!-- ━━━ FEATURE 3: DISCOUNT RECAP SECTION ━━━ -->
            <div class="glass-panel discount-recap-box animate-fade-up mt-8" style="--delay: 7">
              <div class="box-header">
                <div class="bh-left">
                  <h3>Rekap Diskon & Override Harga</h3>
                  <p class="text-dim">Akuntabilitas pemotongan harga manual oleh kasir.</p>
                </div>
                <div class="bh-stats">
                  <div class="mini-stat">
                    <span class="ms-lab">Total Diskon</span>
                    <span class="ms-val red">{{ formatIDR(discountSummary.total) }}</span>
                  </div>
                  <div class="mini-stat">
                    <span class="ms-lab">Avg Disc %</span>
                    <span class="ms-val amber">{{ discountSummary.avgPct.toFixed(1) }}%</span>
                  </div>
                </div>
              </div>

              <div class="table-container mt-4">
                <table class="financial-table">
                  <thead>
                    <tr>
                      <th>Tanggal</th>
                      <th>Produk</th>
                      <th>Normal</th>
                      <th>Actual</th>
                      <th>Diskon</th>
                      <th>Oleh</th>
                      <th>Alasan</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="ov in allOverrides" :key="ov.id">
                      <td>{{ formatDate(ov.override_at) }}</td>
                      <td class="font-bold">{{ ov.product_name }}</td>
                      <td>{{ formatIDR(ov.original_price) }}</td>
                      <td class="teal font-bold">{{ formatIDR(ov.override_price) }}</td>
                      <td class="red">-{{ formatIDR(ov.discount_amount) }}</td>
                      <td>{{ ov.override_by }}</td>
                      <td class="italic text-dim">{{ ov.reason }}</td>
                    </tr>
                    <tr v-if="allOverrides.length === 0">
                      <td colspan="7" class="empty-text">Tidak ada override harga pada periode ini.</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          
          <!-- 💵 TAB 2: ARUS KAS / BANK -->
          <div v-if="activeTab === 'cashflow'" class="tab-cashflow">
            <!-- BANK ACCOUNT CARDS -->
            <div class="bank-section animate-fade-up">
              <div class="section-header">
                <div class="sh-left">
                  <h2 class="hero-font text-2xl">Arus Kas & Perbankan</h2>
                  <p class="text-dim">Total Saldo: <span class="text-white font-bold">{{ formatIDR(totalBankBalance) }}</span></p>
                </div>
                <button class="btn-primary" @click="showBankModal = true">
                  <PlusIcon class="icon-sm" />
                  <span>Tambah Rekening</span>
                </button>
              </div>

              <div class="bank-grid mt-6">
                <div v-for="bank in bankAccounts" :key="bank.id" class="bank-card glass-panel">
                  <div class="card-glow"></div>
                  <div class="bc-header">
                    <div class="bank-icon">
                      <Building2Icon class="icon-md" />
                    </div>
                    <div class="bank-info">
                      <h4 class="bank-name text-white">{{ bank.bank_name }}</h4>
                      <p class="acc-num text-xs text-dim">{{ bank.account_number }}</p>
                    </div>
                  </div>
                  <div class="bc-body">
                    <p class="acc-label text-xs uppercase tracking-widest text-dim">Saldo Saat Ini</p>
                    <h3 class="acc-balance hero-font text-xl text-white">{{ formatIDR(bank.current_balance) }}</h3>
                  </div>
                  <div class="bc-footer">
                    <span class="acc-type text-xs px-2 py-0.5 rounded-full bg-white/5 border border-white/10 uppercase">{{ bank.account_type }}</span>
                  </div>
                </div>
                
                <div v-if="bankAccounts.length === 0" class="bank-card empty glass-panel border-dashed" @click="showBankModal = true">
                  <PlusIcon class="icon-lg text-dim mb-2" />
                  <p class="text-dim font-bold">Tambah Rekening Baru</p>
                </div>
              </div>
            </div>

            <!-- AREA CHART -->
            <div class="glass-panel chart-box-full animate-fade-up mt-8" style="--delay: 1">
              <div class="box-header flex justify-between items-center">
                <h3>Visualisasi Trend Saldo (30 Hari)</h3>
                <div class="flex gap-4">
                  <div class="mini-stat">
                    <span class="ms-lab">Masuk</span>
                    <span class="ms-val text-green text-sm">{{ formatIDR(cashFlowSummary.in) }}</span>
                  </div>
                  <div class="mini-stat">
                    <span class="ms-lab">Keluar</span>
                    <span class="ms-val text-red text-sm">{{ formatIDR(cashFlowSummary.out) }}</span>
                  </div>
                </div>
              </div>
              <div class="chart-wrapper-large">
                <LineChart :data="cashFlowTrendData" :options="cashFlowChartOptions" />
              </div>
            </div>

            <!-- RECENT TRANSACTIONS -->
            <div class="glass-panel list-box animate-fade-up mt-8" style="--delay: 2">
              <div class="box-header teal-border">
                <h3>MUTASI BANK TERAKHIR</h3>
              </div>
              <div class="table-container">
                <table class="financial-table" v-if="bankTransactions.length > 0">
                  <thead>
                    <tr>
                      <th>Tanggal</th>
                      <th>Rekening</th>
                      <th>Keterangan</th>
                      <th>Tipe</th>
                      <th class="text-right">Jumlah</th>
                      <th class="text-right">Balance</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="tx in bankTransactions" :key="tx.id">
                      <td>{{ formatDate(tx.transaction_date) }}</td>
                      <td>{{ bankAccounts.find(b => b.id === tx.bank_account_id)?.bank_name || 'Bank' }}</td>
                      <td>{{ tx.description }}</td>
                      <td>
                        <span :class="['tx-pill', tx.transaction_type]">
                          {{ tx.transaction_type === 'masuk' ? 'MASUK' : 'KELUAR' }}
                        </span>
                      </td>
                      <td class="text-right font-bold" :class="tx.transaction_type === 'masuk' ? 'text-green' : 'text-red'">
                        {{ tx.transaction_type === 'masuk' ? '+' : '-' }}{{ formatIDR(tx.amount) }}
                      </td>
                      <td class="text-right text-dim">{{ formatIDR(tx.balance_after) }}</td>
                    </tr>
                  </tbody>
                </table>
                <EmptyState v-else icon="WalletIcon" title="Belum ada transaksi" message="Transaksi bank akan muncul di sini otomatis setalah ada pergerakan kas." />
              </div>
            </div>

            <!-- JOURNAL ENTRIES (finance_entries) -->
            <div class="glass-panel list-box animate-fade-up mt-8" style="--delay: 3">
              <div class="box-header amber-border">
                <h3>JURNAL KAS INSTITUSIONAL</h3>
              </div>
              <div class="table-container">
                <table class="financial-table" v-if="journalEntries.length > 0">
                  <thead>
                    <tr>
                      <th>Tanggal</th>
                      <th>Kategori</th>
                      <th>Keterangan</th>
                      <th class="text-right">Jumlah</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="entry in journalEntries" :key="entry.id">
                      <td>{{ formatDate(entry.entry_date || entry.created_at) }}</td>
                      <td class="font-bold text-dim uppercase text-xs">{{ entry.category }}</td>
                      <td class="text-xs">{{ entry.description }}</td>
                      <td class="text-right font-bold" :class="entry.entry_type === 'income' ? 'text-green' : 'text-red'">
                        {{ entry.entry_type === 'income' ? '+' : '-' }}{{ formatIDR(entry.amount) }}
                      </td>
                    </tr>
                  </tbody>
                </table>
                <EmptyState v-else icon="FileTextIcon" title="Jurnal Kosong" message="Semua pencatatan keuangan otomatis akan muncul di sini." />
              </div>
            </div>
          </div>
          <!-- ⏳ TAB 3: PIUTANG -->
          <div v-if="activeTab === 'piutang'" class="tab-piutang">
            <!-- HEADER STATS -->
            <div class="piutang-header-stats glass-panel animate-fade-up">
              <div class="stat-item">
                <span class="label">Total Piutang</span>
                <span class="val">{{ formatIDR(kpiData.total_piutang) }}</span>
              </div>
              <div class="stat-divider"></div>
              <div class="stat-item">
                <span class="label">Invoice Terbuka</span>
                <span class="val">{{ piutangList.length }} Unit</span>
              </div>
              <div class="stat-divider"></div>
              <div class="stat-item">
                <span class="label">Invoice Tertua</span>
                <span class="val">{{ oldestPiutangDays }} Hari</span>
              </div>
            </div>

            <!-- BUCKET CARDS -->
            <div class="bucket-grid">
              <div v-for="b in piutangBuckets" :key="b.label" class="bucket-card glass-panel animate-fade-up" :class="b.class" :style="{ '--delay': b.delay }">
                <div class="bucket-icon">
                  <div class="dot" :class="b.class"></div>
                </div>
                <div class="bucket-info">
                  <span class="bucket-label">{{ b.label }}</span>
                  <div class="bucket-vals">
                    <span class="bucket-count">{{ b.count }} Inv</span>
                    <span class="bucket-amount">{{ formatIDR(b.amount) }}</span>
                  </div>
                </div>
              </div>
            </div>

            <!-- MAIN TABLE -->
            <div class="glass-panel table-box-full animate-fade-up" style="--delay: 5">
              <div class="box-header">
                <h3>Daftar Piutang Aktif</h3>
              </div>
              <div class="table-container">
                <table class="financial-table">
                  <thead>
                    <tr>
                      <th>Invoice ID</th>
                      <th>Pelanggan</th>
                      <th>Tgl Order</th>
                      <th>Hari Tertunggak</th>
                      <th>Sisa Tagihan</th>
                      <th class="text-right">Aksi</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="p in piutangList" :key="p.id" :class="getPiutangRowClass(p)">
                      <td class="code">{{ p.invoice_no }}</td>
                      <td>{{ p.customers?.name || 'Umum' }}</td>
                      <td>{{ formatDate(p.created_at) }}</td>
                      <td class="days-col" :class="getPiutangDaysClass(p)">
                        {{ getDaysBetween(p.created_at, new Date()) }} Hari
                      </td>
                      <td class="font-bold red">{{ formatIDR(p.remaining) }}</td>
                      <td class="text-right">
                        <div class="action-btns">
                          <button class="btn-action success" @click="handleMarkPaid(p)" :disabled="loading">
                            <CheckIcon class="icon-xs" />
                            <span>Terima Bayar</span>
                          </button>
                        </div>
                      </td>
                    </tr>
                    <tr v-if="piutangList.length === 0">
                      <td colspan="6" class="empty-text">Tidak ada piutang aktif. Semua lunas! 🚀</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          <!-- 💸 TAB 4: UTANG SUPPLIER (NEW) -->
          <div v-if="activeTab === 'utang'" class="tab-utang">
            <!-- HEADER STATS -->
            <div class="piutang-header-stats glass-panel animate-fade-up">
              <div class="stat-item">
                <span class="label">Total Utang Supplier</span>
                <span class="val red">{{ formatIDR(kpiData.total_utang) }}</span>
              </div>
              <div class="stat-divider"></div>
              <div class="stat-item">
                <span class="label">Nota Belum Lunas</span>
                <span class="val">{{ utangList.length }} Nota</span>
              </div>
              <div class="stat-divider"></div>
              <div class="stat-item">
                <span class="label">Likuiditas Stok</span>
                <span class="val teal">{{ formatIDR(kpiData.stock_value) }}</span>
              </div>
            </div>

            <div class="glass-panel table-box-full animate-fade-up" style="--delay: 5">
              <div class="box-header">
                <h3>Daftar Kewajiban Supplier</h3>
              </div>
              <div class="table-container">
                <table class="financial-table">
                  <thead>
                    <tr>
                      <th>Ref Nota</th>
                      <th>Supplier</th>
                      <th>Tanggal Pembelian</th>
                      <th>Jatuh Tempo (Est)</th>
                      <th>Sisa Utang</th>
                      <th class="text-right">Aksi</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="u in utangList" :key="u.id">
                      <td class="code">PO-{{ u.purchase_id }}</td>
                      <td class="font-bold">{{ u.suppliers?.name || 'Unknown' }}</td>
                      <td>{{ formatDate(u.created_at) }}</td>
                      <td>{{ formatDate(new Date(new Date(u.created_at).getTime() + 7 * 24 * 60 * 60 * 1000)) }}</td>
                      <td class="font-bold red">{{ formatIDR(u.remaining) }}</td>
                      <td class="text-right">
                        <div class="action-btns">
                          <button class="btn-action danger" @click="handlePayUtang(u)" :disabled="loading">
                            <ZapIcon class="icon-xs" />
                            <span>Bayar Sekarang</span>
                          </button>
                        </div>
                      </td>
                    </tr>
                    <tr v-if="utangList.length === 0">
                      <td colspan="6" class="empty-text">Hebat! Tidak ada utang ke supplier. 🥚</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          <!-- 🥚 TAB 5: PROFITABILITAS -->
          <div v-if="activeTab === 'profit'" class="tab-profit">
            <!-- SORT & HEADER -->
            <div class="header-actions animate-fade-up">
              <h3>Analisis Profit Margin per Produk</h3>
              <div class="sort-group glass-panel">
                <span class="label">Urutkan:</span>
                <button v-for="s in sortOptions" :key="s.id" @click="profitSort = s.id" :class="['sort-btn', { active: profitSort === s.id }]">
                  {{ s.label }}
                </button>
              </div>
            </div>

            <!-- PRODUCT CARDS GRID -->
            <div class="product-profit-grid">
              <div v-for="p in sortedProfitability" :key="p.id" class="profit-card glass-panel animate-fade-up" :style="{ '--delay': p.delay }">
                <div class="card-accent" :style="{ background: p.accentColor }"></div>
                <div v-if="p.isStar" class="star-badge">
                  <TrendingUpIcon class="icon-xs" />
                  Star Product
                </div>
                
                <div class="card-top">
                  <h4 class="product-name">{{ p.name }}</h4>
                  <span class="product-variant">{{ p.variant }}</span>
                </div>

                <div class="price-compare">
                  <div class="price-item">
                    <span class="lab">Jual</span>
                    <span class="val">{{ formatIDR(p.sellingPrice) }}</span>
                  </div>
                  <div class="price-item">
                    <span class="lab">HPP</span>
                    <span class="val">{{ formatIDR(p.hpp) }}</span>
                  </div>
                </div>

                <div class="profit-box">
                  <span class="lab">Profit / Pack</span>
                  <h3 class="profit-val">{{ formatIDR(p.profitPerPack) }}</h3>
                </div>

                <div class="margin-progress">
                  <div class="margin-header">
                    <span class="lab">Margin</span>
                    <span class="margin-perc" :class="getMarginClass(p.margin)">{{ p.margin.toFixed(1) }}%</span>
                  </div>
                  <div class="progress-bg">
                    <div class="progress-fill" :style="{ width: Math.min(p.margin, 100) + '%', background: getMarginColor(p.margin) }"></div>
                  </div>
                </div>

                <div class="card-footer">
                  <div class="footer-item">
                    <span class="lab">Terjual</span>
                    <span class="val-sm">{{ p.unitsSold }} Pack</span>
                  </div>
                  <div class="footer-item text-right">
                    <span class="lab">Total Profit</span>
                    <span class="val-sm amber">{{ formatIDR(p.totalProfit) }}</span>
                  </div>
                </div>
              </div>
            </div>

            <!-- RADAR CHART SECTION -->
            <div class="glass-panel radar-section animate-fade-up" style="--delay: 6">
              <div class="box-header">
                <h3>Perbandingan Performansi Produk</h3>
              </div>
              <div class="radar-container">
                <div class="radar-box">
                  <RadarChart :data="radarChartData" :options="radarChartOptions" />
                </div>
                <div class="radar-legend">
                  <div v-for="p in sortedProfitability" :key="p.id" class="legend-item">
                    <div class="legend-dot" :style="{ background: p.accentColor }"></div>
                    <span>{{ p.name }}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <!-- 📤 TAB 6: EXPORT LAPORAN -->
          <div v-if="activeTab === 'export'" class="tab-export">
            <div class="export-header animate-fade-up">
              <div class="lock-notice" v-if="!authStore.isAdmin">
                <ShieldAlertIcon class="icon-md" />
                <span>Section Restricted to Administrators</span>
              </div>
              <p v-else class="text-dim">Pilih laporan yang ingin diunduh atau atur jadwal pengiriman otomatis.</p>
            </div>

            <!-- MANUAL EXPORT ACTIONS -->
            <div class="export-grid">
              <div v-for="ex in exportButtons" :key="ex.id" class="export-card glass-panel animate-fade-up" :style="{ '--delay': ex.delay }">
                <div class="ex-icon-box" :class="ex.color">
                  <component :is="ex.icon" class="icon-lg" />
                </div>
                <div class="ex-info">
                  <h4>{{ ex.label }}</h4>
                  <p class="ex-meta">Format: {{ ex.format }} | Last: {{ ex.lastExport || 'Never' }}</p>
                  <div class="ex-progress" v-if="exportingId === ex.id">
                    <div class="progress-bar-loading"></div>
                  </div>
                </div>
                <button class="btn-export" @click="handleExport(ex)" :disabled="!!exportingId">
                  <DownloadIcon class="icon-sm" />
                  <span>Download</span>
                </button>
              </div>
            </div>

            <!-- ━━━ FEATURE 2: SCHEDULED REPORTS ━━━ -->
            <div class="schedule-section mt-12 animate-fade-up" style="--delay: 6">
              <div class="section-header flex justify-between items-center mb-6">
                <div class="sh-left">
                  <h3 class="hero-font text-xl">🚀 Jadwal Otomatis</h3>
                  <p class="text-dim text-sm">Laporan akan dikirim rutin ke email Anda.</p>
                </div>
                <button class="btn-secondary" @click="showReportModal = true">
                  <PlusIcon class="icon-sm" />
                  <span>Tambah Jadwal</span>
                </button>
              </div>

              <div class="schedule-grid">
                <div v-for="s in scheduledReports" :key="s.id" class="schedule-card glass-panel" :class="{ inactive: !s.is_active }">
                  <div class="sc-header">
                    <div class="sc-icon-box" :class="s.report_type">
                      <MailIcon v-if="s.format === 'email'" class="icon-md" />
                      <FileSpreadsheetIcon v-else class="icon-md" />
                    </div>
                    <div class="sc-meta">
                      <h4>{{ s.report_name }}</h4>
                      <p class="text-xs text-dim">{{ s.recipient_email }}</p>
                    </div>
                    <div class="sc-actions">
                      <button @click="toggleReportActive(s)" class="btn-icon">
                        <ToggleRightIcon v-if="s.is_active" class="icon-md text-green" />
                        <ToggleLeftIcon v-else class="icon-md text-dim" />
                      </button>
                      <button @click="deleteReport(s.id)" class="btn-icon text-red">
                        <Trash2Icon class="icon-sm" />
                      </button>
                    </div>
                  </div>
                  <div class="sc-body mt-4">
                    <div class="sc-info-row">
                      <CalendarIcon class="icon-xs text-dim" />
                      <span>Setiap {{ s.frequency }} ({{ s.send_time }})</span>
                    </div>
                    <div class="sc-info-row mt-1">
                      <EyeIcon class="icon-xs text-dim" />
                      <span>Format: {{ s.format.toUpperCase() }}</span>
                    </div>
                  </div>
                  <div class="sc-footer mt-4">
                    <p class="text-xs text-dim italic">Next send: {{ formatDate(s.next_send_at) }}</p>
                  </div>
                </div>
                
                <div v-if="scheduledReports.length === 0" class="empty-schedule glass-panel border-dashed" @click="showReportModal = true">
                  <p class="text-dim">Belum ada jadwal laporan otomatis.</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </transition>
    </main>

    <!-- CUSTOM CONFIRM MODAL -->
    <CustomConfirmModal 
      :modelValue="showConfirmModal"
      @update:modelValue="showConfirmModal = $event"
      :title="confirmData.title"
      :message="confirmData.message"
      @confirm="confirmData.onConfirm()"
    />

    <!-- MODAL: TAMBAH REKENING -->
    <div v-if="showBankModal" class="modal-overlay" @click.self="showBankModal = false">
      <div class="glass-panel slide-over-form animate-slide-in">
        <div class="form-header">
          <h2 class="hero-font text-xl">🏦 Tambah Rekening</h2>
          <button @click="showBankModal = false" class="btn-close">&times;</button>
        </div>
        <div class="form-body">
          <div class="form-group">
            <label>BANK</label>
            <select v-model="bankForm.bank_name" class="form-input">
              <option>BCA</option>
              <option>Mandiri</option>
              <option>BNI</option>
              <option>BRI</option>
              <option>CIMB Niaga</option>
              <option>Lainnya</option>
            </select>
          </div>
          <div class="form-group">
            <label>NAMA PEMILIK</label>
            <input v-model="bankForm.account_name" type="text" placeholder="Contoh: Hero Farm (Operasional)" class="form-input" />
          </div>
          <div class="form-group">
            <label>NOMOR REKENING</label>
            <input v-model="bankForm.account_number" type="text" placeholder="000111222" class="form-input" />
          </div>
          <div class="form-group">
            <label>SALDO AWAL</label>
            <input v-model="bankForm.initial_balance" type="number" class="form-input" />
          </div>
        </div>
        <div class="form-footer">
          <button class="btn-primary w-full" @click="handleAddBankAccount" :disabled="loading">SIMPAN REKENING</button>
        </div>
      </div>
    </div>

    <!-- MODAL: TAMBAH JADWAL -->
    <div v-if="showReportModal" class="modal-overlay" @click.self="showReportModal = false">
      <div class="glass-panel slide-over-form animate-slide-in">
        <div class="form-header">
          <h2 class="hero-font text-xl">🚀 Penjadwalan Laporan</h2>
          <button @click="showReportModal = false" class="btn-close">&times;</button>
        </div>
        <div class="form-body">
          <div class="form-group">
            <label>NAMA JADWAL</label>
            <input v-model="reportForm.report_name" type="text" placeholder="Laporan Harian Kasir" class="form-input" />
          </div>
          <div class="form-group">
            <label>EMAIL PENERIMA</label>
            <input v-model="reportForm.recipient_email" type="email" placeholder="owner@herofarm.com" class="form-input" />
          </div>
          <div class="form-row">
            <div class="form-group">
              <label>FREKUENSI</label>
              <select v-model="reportForm.frequency" class="form-input">
                <option value="daily">Harian</option>
                <option value="weekly">Mingguan</option>
                <option value="monthly">Bulanan</option>
              </select>
            </div>
            <div class="form-group">
              <label>WAKTU</label>
              <input v-model="reportForm.send_time" type="time" class="form-input" />
            </div>
          </div>
          <div class="form-group">
            <label>TIPE LAPORAN</label>
            <select v-model="reportForm.report_type" class="form-input">
              <option value="pnl">Untung Rugi (P&L)</option>
              <option value="sales">Rekap Penjualan</option>
              <option value="stock">Mutasi Stok</option>
              <option value="complete">Semua Laporan</option>
            </select>
          </div>
        </div>
        <div class="form-footer">
          <button class="btn-primary w-full" @click="handleAddScheduledReport" :disabled="loading">AKTIFKAN JADWAL</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { supabase } from '../lib/supabase';
import { useAuthStore } from '../stores/auth';
import { useRouter } from 'vue-router';
import { 
  BarChart3Icon, 
  WalletIcon, 
  HourglassIcon, 
  EggIcon, 
  DownloadIcon,
  TrendingUpIcon,
  TrendingDownIcon,
  CheckIcon,
  FileSpreadsheetIcon,
  ShieldAlertIcon,
  ZapIcon,
  Building2Icon,
  PlusIcon,
  CalendarIcon,
  MailIcon,
  Trash2Icon,
  EyeIcon,
  ToggleLeftIcon,
  ToggleRightIcon,
} from 'lucide-vue-next';
import { useToast } from '../composables/useToast';
import CustomConfirmModal from '../components/ui/CustomConfirmModal.vue';
import EmptyState from '../components/ui/EmptyState.vue';
import { 
  Chart as ChartJS, 
  Title, Tooltip, Legend, 
  LineElement, CategoryScale, LinearScale, PointElement,
  BarElement, ArcElement, RadialLinearScale, Filler
} from 'chart.js';
import { Line as LineChart, Radar as RadarChart } from 'vue-chartjs';

ChartJS.register(
  Title, Tooltip, Legend, 
  LineElement, CategoryScale, LinearScale, PointElement,
  BarElement, ArcElement, RadialLinearScale, Filler
);

const authStore = useAuthStore();
const router = useRouter();

// Admin Only Guard
if (!authStore.isAdmin) {
  router.push('/');
}

// NAVIGATION
const activeTab = ref('pnl');
const tabs = [
  { id: 'pnl', label: 'P&L Overview', icon: BarChart3Icon },
  { id: 'cashflow', label: 'Arus Kas', icon: WalletIcon },
  { id: 'piutang', label: 'Piutang (Receivables)', icon: HourglassIcon },
  { id: 'utang', label: 'Utang (Payables)', icon: ZapIcon },
  { id: 'profit', label: 'Profitabilitas', icon: EggIcon },
  { id: 'export', label: 'Export', icon: DownloadIcon },
];

// FILTERS
const activePeriod = ref('month');
const periods = [
  { id: 'week', label: 'This Week' },
  { id: 'month', label: 'This Month' },
  { id: 'quarter', label: 'This Quarter' },
  { id: 'custom', label: 'Custom' },
];

const dateRange = ref({ start: new Date(), end: new Date() });

const formattedDateRange = computed(() => {
  const options: Intl.DateTimeFormatOptions = { day: '2-digit', month: 'short', year: 'numeric' };
  return `${dateRange.value.start.toLocaleDateString('id-ID', options)} — ${dateRange.value.end.toLocaleDateString('id-ID', options)}`;
});

// DATA
const allSales = ref<any[]>([]);
const allStockLogs = ref<any[]>([]);
const allFinanceEntries = ref<any[]>([]);
const allOverrides = ref<any[]>([]);
const inventory = ref<any[]>([]);
const bankAccounts = ref<any[]>([]);
const bankTransactions = ref<any[]>([]);
const scheduledReports = ref<any[]>([]);
const piutangData = ref<any[]>([]);
const utangData = ref<any[]>([]);
const kpiData = ref<any>({
  total_revenue: 0,
  gross_profit: 0,
  total_piutang: 0,
  total_utang: 0,
  stock_value: 0
});
const loading = ref(false);
const { showToast } = useToast();

const showBankModal = ref(false);
const showReportModal = ref(false);
const showConfirmModal = ref(false);
const confirmData = ref({ title: '', message: '', onConfirm: () => {} });

const bankForm = ref({
  bank_name: 'BCA',
  account_name: '',
  account_number: '',
  account_type: 'tabungan',
  initial_balance: 0
});

const reportForm = ref({
  report_type: 'pnl',
  report_name: '',
  frequency: 'daily',
  day_of_week: 1,
  day_of_month: 1,
  send_time: '07:00',
  recipient_email: '',
  format: 'csv'
});

const fetchData = async () => {
  loading.value = true;
  try {
    // 1. Set dates based on activePeriod
    const now = new Date();
    let start = new Date();
    let end = new Date();

    if (activePeriod.value === 'week') {
      const day = now.getDay();
      start = new Date(now.getFullYear(), now.getMonth(), now.getDate() - (day === 0 ? 6 : day - 1));
      start.setHours(0, 0, 0, 0);
    } else if (activePeriod.value === 'month') {
      start = new Date(now.getFullYear(), now.getMonth(), 1);
    } else if (activePeriod.value === 'quarter') {
      const quarter = Math.floor(now.getMonth() / 3);
      start = new Date(now.getFullYear(), quarter * 3, 1);
    }
    dateRange.value = { start, end };

    // 2. Fetch data from Supabase
    const { data: sales } = await supabase
      .from('sales')
      .select('*, sale_items(*), customers(name)')
      .gte('created_at', start.toISOString())
      .lte('created_at', end.toISOString());
    
    const { data: logs } = await supabase
      .from('stock_logs')
      .select('*')
      .gte('created_at', start.toISOString())
      .lte('created_at', end.toISOString());

    const { data: finance } = await supabase
      .from('finance_entries')
      .select('*')
      .gte('entry_date', start.toISOString().split('T')[0]!)
      .lte('entry_date', end.toISOString().split('T')[0]!);

    const { data: inv } = await supabase
      .from('inventory')
      .select('*');

    const { data: overrides } = await supabase
      .from('price_overrides')
      .select('*')
      .gte('override_at', start.toISOString())
      .lte('override_at', end.toISOString());

    const { data: bAcc } = await supabase.from('bank_accounts').select('*').eq('is_active', true);
    const { data: bTx } = await supabase.from('bank_transactions').select('*').order('created_at', { ascending: false }).limit(50);
    const { data: sRep } = await supabase.from('scheduled_reports').select('*');
    
    // 3. New Data for Phase 3
    const { data: pData } = await supabase.from('piutang').select('*, customers(name)').neq('status', 'lunas');
    const { data: uData } = await supabase.from('utang_supplier').select('*, suppliers(name)').neq('status', 'lunas');
    const { data: kpis } = await supabase.rpc('get_dashboard_kpis');

    allSales.value = sales || [];
    allStockLogs.value = logs || [];
    allFinanceEntries.value = finance || [];
    allOverrides.value = overrides || [];
    inventory.value = inv || [];
    bankAccounts.value = bAcc || [];
    bankTransactions.value = bTx || [];
    scheduledReports.value = sRep || [];
    piutangData.value = pData || [];
    utangData.value = uData || [];

    if (kpis) {
      kpiData.value = {
        ...kpis,
        total_piutang: kpis.total_piutang_aktif || 0,
        total_utang: kpis.total_utang_aktif || 0,
        stock_value: (inv || []).reduce((acc: number, i: any) => acc + (Number(i.current_stock || 0) * (Number(i.hpp_per_egg || i.unit_cost || 0))), 0)
      };
    }
  } catch (err) {
    console.error('Error fetching financial data:', err);
  } finally {
    loading.value = false;
  }
};

onMounted(fetchData);

// ─── DISCOUNT COMPUTATIONS ─────────────────────
const discountSummary = computed(() => {
  const total = allOverrides.value.reduce((acc, o) => acc + (Number(o.discount_amount) || 0), 0);
  const avgPct = allOverrides.value.length > 0 
    ? allOverrides.value.reduce((acc, o) => acc + (Number(o.discount_pct) || 0), 0) / allOverrides.value.length 
    : 0;
  return { total, avgPct };
});

// ─── TAB 1: P&L COMPUTATIONS ───────────────────
interface PnlSummary {
  revenue: number;
  totalHPP: number;
  grossProfit: number;
  margin: number;
  piutang: number;
  voidTotal: number;
}

const pnlSummary = computed<PnlSummary>(() => {
  const sales: any[] = Array.isArray(allSales.value) ? allSales.value : [];
  
  const revenue = sales
    .filter(s => s?.payment_status === 'paid')
    .reduce((acc, s) => acc + (Number(s?.total_price) || 0), 0);
  
  const totalHPP = sales
    .filter(s => s?.payment_status === 'paid')
    .reduce((acc, s) => {
      const items = Array.isArray(s?.sale_items) ? s.sale_items : [];
      // Use hpp_total from new schema or fallback to cost_price * quantity
      const itemsHpp = items.reduce((iAcc: number, i: any) => iAcc + (Number(i?.hpp_total) || (Number(i?.cost_price || i?.unit_cost || 0) * (Number(i?.quantity) || 0))), 0);
      return acc + itemsHpp;
    }, 0);

  const grossProfit = revenue - totalHPP;
  const margin = revenue > 0 ? (grossProfit / revenue) * 100 : 0;
  const piutang = sales
    .filter(s => s?.payment_status === 'pending')
    .reduce((acc, s) => acc + (Number(s?.total_price) || 0), 0);
  
  const voidTotal = sales
    .filter(s => s?.payment_status === 'voided')
    .reduce((acc, s) => acc + (Number(s?.total_price) || 0), 0);

  return { revenue, totalHPP, grossProfit, margin, piutang, voidTotal };
});

// P&L Chart Data
const pnlChartData = computed(() => {
  const dataMap = new Map<string, { rev: number; hpp: number; gp: number }>();
  
  const sales: any[] = allSales.value || [];
  for (const s of sales) {
    if (s.payment_status !== 'paid' || !s.created_at) continue;
    
    const date: string = String(s.created_at).split('T')[0]!;
    let entry = dataMap.get(date);
    if (!entry) {
      entry = { rev: 0, hpp: 0, gp: 0 };
      dataMap.set(date, entry);
    }
    
    entry.rev += Number(s.total_price) || 0;
    
    let hppVal = 0;
    const items: any[] = Array.isArray(s.sale_items) ? s.sale_items : [];
    for (const item of items) {
      if (item) hppVal += (Number(item.cost_price) || 0) * (Number(item.quantity) || 0);
    }
    entry.hpp += hppVal;
    entry.gp += (Number(s.total_price) || 0) - hppVal;
  }

  const keys: string[] = Array.from(dataMap.keys()).sort();
  const displayLabels = keys.map((k: string) => new Date(k).toLocaleDateString('id-ID', { day: '2-digit', month: 'short' }));
  
  return {
    labels: displayLabels,
    datasets: [
      { label: 'Revenue', data: keys.map((k: string) => dataMap.get(k)?.rev ?? 0), borderColor: '#f59e0b', backgroundColor: 'rgba(245, 158, 11, 0.1)', tension: 0.4, fill: true },
      { label: 'HPP', data: keys.map((k: string) => dataMap.get(k)?.hpp ?? 0), borderColor: '#ef4444', backgroundColor: 'rgba(239, 68, 68, 0.1)', tension: 0.4, fill: true },
      { label: 'Profit', data: keys.map((k: string) => dataMap.get(k)?.gp ?? 0), borderColor: '#10b981', backgroundColor: 'rgba(16, 185, 129, 0.1)', tension: 0.4, fill: true },
    ]
  };
});

const pnlChartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: { display: false },
    tooltip: { 
      mode: 'index' as const, 
      intersect: false,
      callbacks: {
        label: (context: any) => `${context.dataset.label}: ${formatIDR(context.parsed?.y || 0)}`
      }
    }
  },
  scales: {
    x: { grid: { display: false }, ticks: { color: 'rgba(255,255,255,0.3)', font: { size: 10 } } },
    y: { 
      grid: { color: 'rgba(255,255,255,0.05)' }, 
      ticks: { 
        color: 'rgba(255,255,255,0.3)', 
        font: { size: 10 },
        callback: (v: any) => formatIDR(v)
      } 
    }
  }
};

interface PnlKpi {
  label: string;
  displayValue: string;
  prefix: string;
  suffix: string;
  color: string;
  delay: string;
  trend: number;
}

const pnlKpis = computed<PnlKpi[]>(() => [
  { label: 'Total Pendapatan', displayValue: formatIDR(kpiData.value.total_revenue), prefix: '', suffix: '', color: 'green', delay: '1', trend: 0 },
  { label: 'Laba Kotor', displayValue: formatIDR(kpiData.value.gross_profit), prefix: '', suffix: '', color: 'amber', delay: '2', trend: 0 },
  { label: 'Piutang Aktif', displayValue: formatIDR(kpiData.value.total_piutang), prefix: '', suffix: '', color: 'yellow', delay: '3', trend: 0 },
  { label: 'Utang Supplier', displayValue: formatIDR(kpiData.value.total_utang), prefix: '', suffix: '', color: 'red', delay: '4', trend: 0 },
  { label: 'Nilai Stok', displayValue: formatIDR(kpiData.value.stock_value), prefix: '', suffix: '', color: 'teal', delay: '5', trend: 0 },
  { label: 'Margin (%)', displayValue: (Number(pnlSummary.value.margin || 0)).toFixed(1), prefix: '', suffix: '%', color: 'amber', delay: '6', trend: 0 },
]);

const pnlRevenueBreakdown = computed(() => {
  const map: Record<string, number> = { 'Telur Hero': 0, 'Telur Standar': 0, 'Telur Asin': 0 };
  const paidSales: any[] = (allSales.value || []).filter((s: any) => s.payment_status === 'paid');
  for (const s of paidSales) {
    const saleItems: any[] = Array.isArray(s.sale_items) ? s.sale_items : [];
    for (const i of saleItems) {
      if (!i) continue;
      const lbl: string = String(i.item_label || i.grade || '');
      const amt: number = Number(i.revenue) || (Number(i.unit_price || i.price_per_pack || 0) * (Number(i.quantity || i.packs_sold || 0)));
      if (lbl.includes('Hero')) map['Telur Hero']! += amt;
      else if (lbl.includes('Asin')) map['Telur Asin']! += amt;
      else map['Telur Standar']! += amt;
    }
  }
  const rev = Object.values(map).reduce((a, b) => a + b, 0);
  return Object.entries(map).map(([label, value]) => ({
    label,
    value,
    perc: rev > 0 ? (value / rev) * 100 : 0
  }));
});

const pnlHppBreakdown = computed(() => {
  const map: Record<string, number> = { 'Telur Hero': 0, 'Telur Standar': 0, 'Telur Asin': 0 };
  const paidSales: any[] = (allSales.value || []).filter((s: any) => s.payment_status === 'paid');
  for (const s of paidSales) {
    const saleItems: any[] = Array.isArray(s.sale_items) ? s.sale_items : [];
    for (const i of saleItems) {
      if (!i) continue;
      const lbl: string = String(i.item_label || i.grade || '');
      const amt: number = Number(i.hpp_total) || (Number(i.unit_cost || i.hpp_per_pack || 0) * (Number(i.quantity || i.packs_sold || 0)));
      if (lbl.includes('Hero')) map['Telur Hero']! += amt;
      else if (lbl.includes('Asin')) map['Telur Asin']! += amt;
      else map['Telur Standar']! += amt;
    }
  }
  const hpp = Object.values(map).reduce((a, b) => a + b, 0);
  return Object.entries(map).map(([label, value]) => ({
    label,
    value,
    perc: hpp > 0 ? (value / hpp) * 100 : 0
  }));
});

// ─── TAB 2: CASH FLOW COMPUTATIONS ────────────
const cashInList = computed(() => (allFinanceEntries.value || []).filter(e => e.entry_type === 'income' || e.type === 'income'));
const cashOutList = computed(() => (allFinanceEntries.value || []).filter(e => e.entry_type === 'expense' || e.type === 'expense'));

const journalEntries = computed(() => {
  return [...allFinanceEntries.value].sort((a, b) => {
    const d1 = new Date(a.entry_date || a.created_at).getTime();
    const d2 = new Date(b.entry_date || b.created_at).getTime();
    return d2 - d1;
  }).slice(0, 50);
});

const cashFlowSummary = computed(() => {
  const incoming = cashInList.value.reduce((acc, e) => acc + (Number(e.amount) || 0), 0);
  const outgoing = cashOutList.value.reduce((acc, e) => acc + (Number(e.amount) || 0), 0);
  const net = incoming - outgoing;
  const ratio = incoming + outgoing > 0 ? (incoming / (incoming + outgoing)) * 100 : 0;
  return { in: incoming, out: outgoing, net, ratio };
});

const cashFlowChartOptions = {
  ...pnlChartOptions,
  plugins: {
    ...pnlChartOptions.plugins,
    legend: { display: true, labels: { color: 'white', font: { size: 10 } } }
  }
};

// ───── TAB 3: PIUTANG COMPUTATIONS ──────────────
const piutangList = computed<any[]>(() => {
  return (piutangData.value || [])
    .sort((a, b) => {
      const d1 = a?.created_at ? new Date(a.created_at).getTime() : 0;
      const d2 = b?.created_at ? new Date(b.created_at).getTime() : 0;
      return d1 - d2;
    });
});

const utangList = computed<any[]>(() => {
  return (utangData.value || [])
    .sort((a, b) => {
      const d1 = a?.created_at ? new Date(a.created_at).getTime() : 0;
      const d2 = b?.created_at ? new Date(b.created_at).getTime() : 0;
      return d1 - d2;
    });
});

const getDaysBetween = (start: any, end: any): number => {
  if (!start || !end) return 0;
  const d1 = new Date(start);
  const d2 = new Date(end);
  if (isNaN(d1.getTime()) || isNaN(d2.getTime())) return 0;
  const diff = d2.getTime() - d1.getTime();
  return Math.floor(diff / (1000 * 60 * 60 * 24));
};

const oldestPiutangDays = computed<number>(() => {
  const list = piutangList.value;
  if (list.length === 0 || !list[0]?.created_at) return 0;
  return getDaysBetween(list[0]!.created_at, new Date());
});

interface PiutangBucket {
  label: string;
  count: number;
  amount: number;
  class: string;
  delay: string;
}

const piutangBuckets = computed<PiutangBucket[]>(() => {
  const buckets: PiutangBucket[] = [
    { label: 'Aman (0-7)', count: 0, amount: 0, class: 'safe', delay: '1' },
    { label: 'Warning (8-14)', count: 0, amount: 0, class: 'warning', delay: '2' },
    { label: 'Kritis (15+)', count: 0, amount: 0, class: 'danger', delay: '3' },
    { label: 'Total Piutang', count: piutangList.value.length, amount: kpiData.value.total_piutang, class: 'lunas', delay: '4' },
  ];

  piutangList.value.forEach(s => {
    if (!s?.created_at) return;
    const days = getDaysBetween(s.created_at, new Date());
    const amount = Number(s.remaining) || 0;
    if (days <= 7) { buckets[0]!.count++; buckets[0]!.amount += amount; }
    else if (days <= 14) { buckets[1]!.count++; buckets[1]!.amount += amount; }
    else { buckets[2]!.count++; buckets[2]!.amount += amount; }
  });

  return buckets;
});

const getPiutangDaysClass = (s: any) => {
  const days = getDaysBetween(s.created_at, new Date());
  if (days <= 7) return '';
  if (days <= 14) return 'text-amber';
  return 'text-red';
};

const getPiutangRowClass = (s: any) => {
  const days = getDaysBetween(s.created_at, new Date());
  if (days > 7 && days <= 14) return 'row-warning';
  if (days > 14) return 'row-danger';
  return '';
};

const handleMarkPaid = async (p: any) => {
  if (!confirm(`Tandai piutang ${p.invoice_no} sebagai Lunas?`)) return;
  loading.value = true;
  try {
    const { error } = await supabase.rpc('collect_piutang', {
      p_piutang_id: p.id,
      p_amount: p.remaining,
      p_method: 'Tunai',
      p_note: 'Pelunasan via Financial Terminal'
    });
    
    if (error) throw error;
    showToast('Pembayaran piutang berhasil dicatat');
    await fetchData();
  } catch (err: any) {
    showToast('Gagal mencatat pembayaran: ' + err.message, 'error');
  } finally {
    loading.value = false;
  }
};

const handlePayUtang = async (u: any) => {
  if (!confirm(`Tandai utang ke ${u.suppliers?.name} senilai ${formatIDR(u.remaining)} sebagai Lunas?`)) return;
  loading.value = true;
  try {
    const { error } = await supabase.rpc('pay_utang_supplier', {
      p_utang_id: u.id,
      p_amount: u.remaining,
      p_payer: authStore.profile?.full_name || 'Admin',
      p_note: 'Pelunasan via Financial Terminal'
    });
    
    if (error) throw error;
    showToast('Pembayaran utang berhasil dicatat');
    await fetchData();
  } catch (err: any) {
    showToast('Gagal mencatat pembayaran: ' + err.message, 'error');
  } finally {
    loading.value = false;
  }
};

// ─── TAB 4: PROFITABILITY COMPUTATIONS ───────
const profitSort = ref('margin');
const sortOptions = [
  { id: 'margin', label: 'Margin %' },
  { id: 'profit', label: 'Total Profit' },
  { id: 'sold', label: 'Terjual' },
];

interface ProductProfit {
  id: string;
  name: string;
  variant: string;
  sellingPrice: number;
  hpp: number;
  profitPerPack: number;
  totalProfit: number;
  unitsSold: number;
  revenue: number;
  margin: number;
  accentColor: string;
  delay: string;
  isStar?: boolean;
}

const productProfitability = computed<ProductProfit[]>(() => {
  const eggInventory = (inventory.value || []).filter(i => i?.category === 'Telur');
  const paidSales = (allSales.value || []).filter(s => s?.payment_status === 'paid');
  const salesItems = paidSales.flatMap(s => Array.isArray(s?.sale_items) ? s.sale_items : []);
  
  const results = eggInventory.map((egg, idx) => {
    const items = salesItems.filter((i: any) => i?.inventory_id === egg?.id);
    const unitsSold = items.reduce((acc, i) => acc + (Number(i?.quantity) || 0), 0);
    const sellingPrice = Number(egg?.price) || 0;
    const hpp = Number(egg?.cost_price) || 0;
    const profitPerPack = sellingPrice - hpp;
    const totalProfit = profitPerPack * unitsSold;
    const revenue = sellingPrice * unitsSold;
    const margin = sellingPrice > 0 ? (profitPerPack / sellingPrice) * 100 : 0;

    let accentColor = '#f59e0b';
    const eggName = String(egg?.name || '');
    if (eggName.includes('Hero')) accentColor = '#f59e0b';
    else if (eggName.includes('Standard')) accentColor = '#3b82f6';
    else if (eggName.includes('Asin')) accentColor = '#a855f7';

    return {
      id: String(egg?.id || ''),
      name: eggName,
      variant: String(egg?.variant || 'Standard Pack'),
      sellingPrice,
      hpp,
      profitPerPack,
      totalProfit,
      unitsSold,
      revenue,
      margin,
      accentColor,
      delay: (idx + 1).toString()
    } as ProductProfit;
  });

  // Identify Star Product (Highest Total Profit)
  if (results.length > 0) {
    const sorted = [...results].sort((a, b) => b.totalProfit - a.totalProfit);
    if (sorted[0] && sorted[0].totalProfit > 0) {
      const star = results.find(r => r.id === (sorted[0]?.id || ''));
      if (star) star.isStar = true;
    }
  }

  return results;
});

const sortedProfitability = computed(() => {
  return [...productProfitability.value].sort((a: any, b: any) => {
    if (profitSort.value === 'margin') return b.margin - a.margin;
    if (profitSort.value === 'profit') return b.totalProfit - a.totalProfit;
    return b.unitsSold - a.unitsSold;
  });
});

const getMarginColor = (m: number) => {
  if (m < 20) return '#ef4444';
  if (m < 35) return '#f59e0b';
  return '#10b981';
};

const getMarginClass = (m: number) => {
  if (m < 20) return 'text-red';
  if (m < 35) return 'text-amber';
  return 'text-green';
};

const radarChartData = computed(() => {
  const prods: ProductProfit[] = productProfitability.value || [];
  return {
    labels: ['Margin %', 'Volume', 'Revenue', 'Profit/Pack', 'Effisiensi'],
    datasets: prods.map(p => ({
      label: p.name,
      data: [
        Number(p.margin) || 0,
        (Number(p.unitsSold) / 100) * 10, // Normalized
        (Number(p.revenue) / 1000000) * 10,
        (Number(p.profitPerPack) / 1000) * 2,
        Number(p.sellingPrice) > 0 ? 100 - (Number(p.hpp) / Number(p.sellingPrice) * 100) : 0
      ],
      borderColor: String(p.accentColor || '#f59e0b'),
      backgroundColor: String(p.accentColor || '#f59e0b') + '22',
      pointBackgroundColor: String(p.accentColor || '#f59e0b'),
    }))
  };
});

const radarChartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: { legend: { display: false } },
  scales: {
    r: {
      angleLines: { color: 'rgba(255,255,255,0.1)' },
      grid: { color: 'rgba(255,255,255,0.1)' },
      pointLabels: { color: 'rgba(255,255,255,0.5)', font: { size: 10 } },
      ticks: { display: false }
    }
  }
};

// ─── TAB 5: EXPORT COMPUTATIONS ──────────────
const exportingId = ref<string | null>(null);
const exportButtons = [
  { id: 'pnl', label: 'Laporan Laba Rugi (P&L)', format: 'CSV', icon: BarChart3Icon, color: 'amber', delay: '1', lastExport: 'Today' },
  { id: 'sales', label: 'Rekap Penjualan', format: 'CSV', icon: FileSpreadsheetIcon, color: 'teal', delay: '2', lastExport: 'Today' },
  { id: 'stock', label: 'Kartu Stok (Mutasi)', format: 'CSV', icon: ZapIcon, color: 'blue', delay: '3', lastExport: '-' },
  { id: 'piutang', label: 'Laporan Piutang', format: 'CSV', icon: HourglassIcon, color: 'red', delay: '4', lastExport: '-' },
  { id: 'cashflow', label: 'Laporan Arus Kas', format: 'CSV', icon: WalletIcon, color: 'teal', delay: '5', lastExport: '-' },
  { id: 'backup', label: 'Full Backup System', format: 'JSON', icon: ShieldAlertIcon, color: 'gold', delay: '6', lastExport: 'Mar 02' },
];

const handleExport = async (ex: any) => {
  exportingId.value = ex.id;
  try {
    let data: any[] = [];
    let filename = `hero-farm-${ex.id}-${new Date().toISOString().split('T')[0]!}`;
    
    if (ex.id === 'sales') data = allSales.value;
    else if (ex.id === 'stock') data = allStockLogs.value;
    else if (ex.id === 'piutang') data = piutangList.value;
    else if (ex.id === 'cashflow') data = allFinanceEntries.value;
    else if (ex.id === 'pnl') data = productProfitability.value;
    else if (ex.id === 'backup') {
      const backup = { 
        sales: allSales.value, 
        logs: allStockLogs.value, 
        finance: allFinanceEntries.value, 
        inventory: inventory.value 
      };
      const blob = new Blob([JSON.stringify(backup, null, 2)], { type: 'application/json' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `${filename}.json`;
      a.click();
      return;
    }

    if (data.length === 0) {
      alert('Tidak ada data untuk diekspor dalam periode ini.');
      return;
    }

    // Simple CSV conversion
    const headers = Object.keys(data[0]!).join(',');
    const rows = data.map(row => 
      Object.values(row).map(val => `"${val}"`).join(',')
    ).join('\n');
    const csvContent = `${headers}\n${rows}`;
    const blob = new Blob([csvContent], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `${filename}.csv`;
    a.click();
  } catch (err) {
    console.error('Export failed:', err);
  } finally {
    setTimeout(() => { exportingId.value = null; }, 1000);
  }
};

// FORMATTERS ARE DEFINED AT THE BOTTOM OF SCRIPT

const totalBankBalance = computed(() => bankAccounts.value.reduce((acc, b) => acc + (Number(b.current_balance) || 0), 0));

const cashFlowTrendData = computed(() => {
  // Simple 30-day projection or history for bank balance
  const labels = ['Week 1', 'Week 2', 'Week 3', 'Week 4'];
  return {
    labels,
    datasets: [{
      label: 'Total Saldo Bank',
      data: [totalBankBalance.value * 0.9, totalBankBalance.value * 0.95, totalBankBalance.value * 0.98, totalBankBalance.value],
      borderColor: '#10b981',
      backgroundColor: 'rgba(16, 185, 129, 0.1)',
      fill: true,
      tension: 0.4
    }]
  };
});

async function handleAddBankAccount() {
  if (!bankForm.value.account_name || !bankForm.value.account_number) {
    showToast('Harap isi semua field', 'warning');
    return;
  }
  
  loading.value = true;
  const { error } = await supabase.from('bank_accounts').insert({
    bank_name: bankForm.value.bank_name,
    account_name: bankForm.value.account_name,
    account_number: bankForm.value.account_number,
    account_type: bankForm.value.account_type,
    current_balance: bankForm.value.initial_balance
  });

  if (!error) {
    showToast('Rekening berhasil ditambahkan');
    showBankModal.value = false;
    fetchData();
  } else {
    showToast('Gagal menambahkan rekening', 'error');
  }
  loading.value = false;
}

async function handleAddScheduledReport() {
  if (!reportForm.value.recipient_email || !reportForm.value.report_name) {
    showToast('Harap isi email dan nama jadwal', 'warning');
    return;
  }

  loading.value = true;
  const { error } = await supabase.from('scheduled_reports').insert(reportForm.value);

  if (!error) {
    showToast('Jadwal laporan berhasil dibuat');
    showReportModal.value = false;
    fetchData();
  } else {
    showToast('Gagal membuat jadwal', 'error');
  }
  loading.value = false;
}

async function toggleReportActive(report: any) {
  const { error } = await supabase
    .from('scheduled_reports')
    .update({ is_active: !report.is_active })
    .eq('id', report.id);
  
  if (!error) {
    report.is_active = !report.is_active;
    showToast(`Jadwal ${report.is_active ? 'diaktifkan' : 'dinonaktifkan'}`);
  }
}

async function deleteReport(id: string) {
  confirmData.value = {
    title: 'Hapus Jadwal?',
    message: 'Jadwal laporan ini akan dihapus permanen.',
    onConfirm: async () => {
      const { error } = await supabase.from('scheduled_reports').delete().eq('id', id);
      if (!error) {
        showToast('Jadwal dihapus');
        fetchData();
      }
    }
  };
  showConfirmModal.value = true;
}

// UTILS
// FORMATTERS AT BOTTOM ALREADY DEFINED

const formatIDR = (val: number | undefined) => {
  const amount = val || 0;
  return new Intl.NumberFormat('id-ID', {
    style: 'currency',
    currency: 'IDR',
    minimumFractionDigits: 0
  }).format(amount);
};

const formatDate = (date: any) => {
  if (!date) return '-';
  const d = new Date(date);
  if (isNaN(d.getTime())) return '-';
  return d.toLocaleDateString('id-ID', {
    day: '2-digit',
    month: 'short',
    year: 'numeric'
  });
};
</script>

<style scoped>
.financial-terminal {
  display: flex;
  flex-direction: column;
  gap: 32px;
}

.terminal-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
}

.gradient-text {
  font-size: 2.8rem;
  font-weight: 900;
  background: linear-gradient(135deg, #f59e0b 0%, #fbbf24 100%);
  -webkit-background-clip: text;
  background-clip: text;
  -webkit-text-fill-color: transparent;
  color: transparent;
  margin-bottom: 4px;
}

.header-right {
  display: flex;
  align-items: center;
}

.date-filter-group {
  display: flex;
  align-items: center;
  padding: 6px;
  background: rgba(255, 255, 255, 0.04);
  border-radius: 12px;
}

.period-btn {
  padding: 8px 16px;
  border-radius: 8px;
  border: none;
  background: transparent;
  color: var(--color-text-dim);
  font-size: 0.8rem;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.2s ease;
}

.period-btn.active {
  background: rgba(245, 158, 11, 0.1);
  color: #f59e0b;
}

.date-divider {
  width: 1px;
  height: 24px;
  background: rgba(255, 255, 255, 0.1);
  margin: 0 12px;
}

.date-display {
  display: flex;
  align-items: center;
  gap: 16px;
  padding-right: 8px;
}

.range-text {
  font-size: 0.85rem;
  font-weight: 600;
  color: var(--color-text-dim);
}

.btn-apply {
  padding: 6px 16px;
  background: #f59e0b;
  color: #000;
  border: none;
  border-radius: 6px;
  font-size: 0.75rem;
  font-weight: 800;
  cursor: pointer;
  box-shadow: 0 0 15px rgba(245, 158, 11, 0.3);
}

/* TABS */
.tab-nav {
  display: flex;
  gap: 8px;
  padding: 8px;
  background: rgba(255, 255, 255, 0.02);
  border-radius: 16px;
  margin-bottom: 24px;
}

.tab-pill {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  padding: 12px;
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

.tab-pill.active {
  background: rgba(245, 158, 11, 0.05);
  border-color: rgba(245, 158, 11, 0.2);
  color: #f59e0b;
  box-shadow: inset 0 0 20px rgba(245, 158, 11, 0.05);
}

.tab-pill:hover:not(.active) {
  background: rgba(255, 255, 255, 0.04);
  color: white;
}

/* KPI GRID */
.kpi-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 32px;
  margin-bottom: 48px;
}

.kpi-card {
  padding: 32px;
  display: flex;
  flex-direction: column;
  gap: 16px;
  transition: all 0.4s cubic-bezier(0.23, 1, 0.32, 1);
  position: relative;
  overflow: hidden;
}

.kpi-card:hover {
  transform: translateY(-8px);
  background: rgba(255, 255, 255, 0.04);
  border-color: rgba(255, 255, 255, 0.15);
  box-shadow: 0 20px 40px rgba(0, 0, 0, 0.4);
}

.kpi-card::after {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: radial-gradient(circle at top right, rgba(255, 255, 255, 0.05), transparent 70%);
  pointer-events: none;
}

.kpi-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.kpi-label {
  font-size: 0.7rem;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  color: var(--color-text-dim);
}

.kpi-value {
  font-size: 2.2rem;
  font-weight: 900;
  line-height: 1;
}

.kpi-value.green { color: #10b981; }
.kpi-value.red { color: #ef4444; }
.kpi-value.amber { color: #f59e0b; }
.kpi-value.yellow { color: #fbbf24; }
.kpi-value.red-muted { color: rgba(239, 68, 68, 0.5); font-size: 1.8rem; }

.trend-pill {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 4px 8px;
  border-radius: 20px;
  font-size: 0.7rem;
  font-weight: 800;
}

.trend-pill.up { background: rgba(16, 185, 129, 0.1); color: #10b981; }
.trend-pill.down { background: rgba(239, 68, 68, 0.1); color: #ef4444; }

/* MAIN GRID */
.pnl-main-grid {
  display: grid;
  grid-template-columns: 1.5fr 1fr;
  gap: 24px;
}

.box-header {
  padding: 20px 24px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.05);
}

.box-header h3 {
  font-family: var(--font-headline);
  font-size: 1rem;
  font-weight: 800;
  color: white;
}

.chart-wrapper {
  padding: 24px;
  height: 400px;
}

.pnl-table-formal {
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 32px;
}

.pnl-sec {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.sec-title {
  font-size: 0.75rem;
  font-weight: 900;
  color: var(--color-text-dim);
  letter-spacing: 0.05em;
  margin-bottom: 8px;
}

.pnl-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 0.95rem;
  font-weight: 600;
  color: rgba(255, 255, 255, 0.8);
  padding: 8px 0;
  border-bottom: 1px solid rgba(255, 255, 255, 0.03);
  transition: all 0.2s ease;
}

.pnl-row:hover {
    color: white;
    padding-left: 8px;
}

.pnl-vals {
  display: flex;
  gap: 24px;
  min-width: 140px;
  justify-content: flex-end;
}

.pnl-perc {
  font-size: 0.8rem;
  color: var(--color-text-dim);
  width: 50px;
  text-align: right;
}

.pnl-row.total {
  margin-top: 8px;
  padding-top: 12px;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
  font-weight: 800;
  color: white;
}

.pnl-row.total.teal { color: #14b8a6; }
.pnl-row.total.red { color: #ef4444; }

.pnl-grand-total {
  border-top: 2px double rgba(255, 255, 255, 0.2);
  padding-top: 20px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.gt-row {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
}

.gt-label { font-size: 0.8rem; font-weight: 800; color: white; }
.gt-val { font-size: 1.8rem; font-weight: 900; }
.gt-val.green { color: #10b981; }

/* CASH FLOW STYLES */
.ratio-bar-bg {
  width: 100%;
  height: 4px;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 2px;
  margin-top: 8px;
  overflow: hidden;
}

.ratio-bar-fill {
  height: 100%;
  transition: width 1s ease-out;
}

.chart-box-full {
  margin-bottom: 24px;
}

.chart-wrapper-large {
  padding: 24px;
  height: 300px;
}

.teal { color: #14b8a6; }
.red { color: #ef4444; }

.box-header.teal-border { border-left: 4px solid #14b8a6; }
.box-header.red-border { border-left: 4px solid #ef4444; }

.table-container {
  padding: 0;
  max-height: 400px;
  overflow-y: auto;
}

.financial-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.85rem;
}

.financial-table th {
  text-align: left;
  padding: 16px;
  background: rgba(255, 255, 255, 0.02);
  color: var(--color-text-dim);
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  position: sticky;
  top: 0;
}

.financial-table td {
  padding: 12px 16px;
  border-top: 1px solid rgba(255, 255, 255, 0.05);
}

.financial-table tr:hover td {
  background: rgba(255, 255, 255, 0.02);
}

.financial-table .code {
  font-family: monospace;
  font-weight: 700;
  color: #f59e0b;
}

.financial-table tfoot td {
  padding: 16px;
  background: rgba(255, 255, 255, 0.04);
  font-weight: 900;
  font-size: 0.9rem;
}

/* PIUTANG STYLES */
.piutang-header-stats {
  display: flex;
  padding: 24px;
  margin-bottom: 24px;
}

.piutang-header-stats .stat-item {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 4px;
  padding: 0 24px;
}

.piutang-header-stats .label {
  font-size: 0.65rem;
  font-weight: 800;
  text-transform: uppercase;
  color: var(--color-text-dim);
}

.piutang-header-stats .val {
  font-size: 1.6rem;
  font-weight: 900;
  color: white;
}

.stat-divider {
  width: 1px;
  background: rgba(255, 255, 255, 0.1);
}

.bucket-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 16px;
  margin-bottom: 24px;
}

.bucket-card {
  padding: 20px;
  display: flex;
  align-items: center;
  gap: 16px;
}

.bucket-icon .dot {
  width: 12px;
  height: 12px;
  border-radius: 50%;
  box-shadow: 0 0 10px currentColor;
}

.dot.lunas { color: #10b981; background: #10b981; }
.dot.safe { color: #fff; background: #fff; }
.dot.warning { color: #f59e0b; background: #f59e0b; }
.dot.danger { color: #ef4444; background: #ef4444; }

.bucket-info {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.bucket-label {
  font-size: 0.7rem;
  font-weight: 800;
  color: var(--color-text-dim);
  text-transform: uppercase;
}

.bucket-vals {
  display: flex;
  align-items: baseline;
  gap: 8px;
}

.bucket-amount {
  font-size: 1.1rem;
  font-weight: 800;
  color: white;
}

.bucket-count {
  font-size: 0.8rem;
  font-weight: 600;
  color: var(--color-text-dim);
}

.tab-utang .stat-item .val.red {
  color: #ef4444;
  text-shadow: 0 0 10px rgba(239, 68, 68, 0.3);
}

.btn-action.danger {
  border-color: rgba(239, 68, 68, 0.2);
  color: #ef4444;
  background: rgba(239, 68, 68, 0.05);
}

.btn-action.danger:hover {
  background: rgba(239, 68, 68, 0.15);
  border-color: #ef4444;
}

.empty-text {
  text-align: center;
  padding: 40px !important;
  color: var(--color-text-dim);
  font-style: italic;
  font-size: 0.9rem;
}

.row-warning td { background: rgba(245, 158, 11, 0.05); }
.row-danger { border-left: 4px solid #ef4444; animation: pulseRed 2s infinite; }
.row-danger td { background: rgba(239, 68, 68, 0.05); }

@keyframes pulseRed {
  0%, 100% { border-left-color: #ef4444; }
  50% { border-left-color: rgba(239, 68, 68, 0.3); }
}

.text-right { text-align: right; }
.font-bold { font-weight: 800; }

.action-btns {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
}

.btn-action {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 6px 12px;
  border-radius: 8px;
  border: 1px solid rgba(255,255,255,0.1);
  background: rgba(255,255,255,0.05);
  color: white;
  font-size: 0.75rem;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.2s ease;
}

.btn-action:hover {
  background: rgba(255,255,255,0.1);
}

.btn-action.success:hover {
  border-color: #10b981;
  color: #10b981;
  background: rgba(16, 185, 129, 0.1);
}

/* PROFITABILITY STYLES */
.header-actions {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.header-actions h3 {
  font-family: var(--font-headline);
  font-size: 1.1rem;
  font-weight: 800;
  color: white;
}

.sort-group {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 4px;
}

.sort-group .label {
  font-size: 0.7rem;
  font-weight: 800;
  color: var(--color-text-dim);
  margin-left: 8px;
}

.sort-btn {
  padding: 6px 12px;
  border-radius: 6px;
  border: none;
  background: transparent;
  color: var(--color-text-dim);
  font-size: 0.75rem;
  font-weight: 700;
  cursor: pointer;
}

.sort-btn.active {
  background: rgba(255, 255, 255, 0.05);
  color: white;
}

.product-profit-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 20px;
  margin-bottom: 32px;
}

.profit-card {
  padding: 24px;
  position: relative;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.card-accent {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 4px;
}

.star-badge {
  position: absolute;
  top: 12px;
  right: -30px;
  background: #f59e0b;
  color: #000;
  padding: 4px 40px;
  font-size: 0.6rem;
  font-weight: 900;
  text-transform: uppercase;
  transform: rotate(45deg);
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 4px;
  box-shadow: 0 0 15px rgba(245, 158, 11, 0.5);
}

.product-name {
  font-family: var(--font-headline);
  font-size: 1.2rem;
  font-weight: 800;
  color: white;
  margin-bottom: 2px;
}

.product-variant {
  font-size: 0.75rem;
  font-weight: 700;
  color: var(--color-text-dim);
}

.price-compare {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
  background: rgba(255, 255, 255, 0.03);
  padding: 12px;
  border-radius: 12px;
}

.price-item {
  display: flex;
  flex-direction: column;
}

.price-item .lab { font-size: 0.6rem; font-weight: 800; color: var(--color-text-dim); }
.price-item .val { font-size: 0.9rem; font-weight: 700; color: white; }

.profit-box .lab { font-size: 0.6rem; font-weight: 800; color: var(--color-text-dim); }
.profit-val { font-size: 1.8rem; font-weight: 900; color: #10b981; }

.margin-progress {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.margin-header {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
}

.margin-header .lab { font-size: 0.65rem; font-weight: 800; color: var(--color-text-dim); }
.margin-perc { font-size: 0.9rem; font-weight: 900; }

.progress-bg { height: 6px; background: rgba(255, 255, 255, 0.1); border-radius: 3px; overflow: hidden; }
.progress-fill { height: 100%; transition: width 1s ease-out; }

.card-footer {
  margin-top: auto;
  padding-top: 16px;
  border-top: 1px solid rgba(255, 255, 255, 0.05);
  display: grid;
  grid-template-columns: 1fr 1fr;
}

.footer-item { display: flex; flex-direction: column; gap: 2px; }
.footer-item .lab { font-size: 0.6rem; font-weight: 800; color: var(--color-text-dim); }
.footer-item .val-sm { font-size: 0.85rem; font-weight: 700; color: rgba(255, 255, 255, 0.8); }
.footer-item .amber { color: #f59e0b; }

.radar-section {
  display: grid;
  grid-template-rows: auto 1fr;
}

.radar-container {
  display: grid;
  grid-template-columns: 2fr 1fr;
  padding: 32px;
  gap: 32px;
  align-items: center;
}

.radar-box { height: 350px; }

.radar-legend {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.legend-item {
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 0.85rem;
  font-weight: 700;
  color: var(--color-text-dim);
}

.legend-dot { width: 8px; height: 8px; border-radius: 50%; }

.text-green { color: #10b981; }

/* EXPORT STYLES */
.tab-export {
  max-width: 900px;
  margin: 0 auto;
}

.export-header {
  margin-bottom: 32px;
  text-align: center;
}

.lock-notice {
  display: inline-flex;
  align-items: center;
  gap: 12px;
  padding: 12px 24px;
  background: rgba(239, 68, 68, 0.1);
  border: 1px solid rgba(239, 68, 68, 0.2);
  border-radius: 12px;
  color: #ef4444;
  font-weight: 700;
}

.export-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
  gap: 20px;
}

.export-card {
  display: flex;
  align-items: center;
  gap: 20px;
  padding: 24px;
}

.ex-icon-box {
  width: 60px;
  height: 60px;
  border-radius: 16px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(255, 255, 255, 0.03);
}

.ex-icon-box.amber { color: #f59e0b; background: rgba(245, 158, 11, 0.1); }
.ex-icon-box.teal { color: #14b8a6; background: rgba(20, 184, 166, 0.1); }
.ex-icon-box.blue { color: #3b82f6; background: rgba(59, 130, 246, 0.1); }
.ex-icon-box.red { color: #ef4444; background: rgba(239, 68, 68, 0.1); }
.ex-icon-box.gold { color: #fbbf24; background: rgba(251, 191, 36, 0.1); border: 1px solid rgba(251, 191, 36, 0.2); }

.ex-info {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.ex-info h4 {
  font-family: var(--font-headline);
  font-size: 1rem;
  font-weight: 800;
  color: white;
}

.ex-meta {
  font-size: 0.75rem;
  color: var(--color-text-dim);
  font-weight: 600;
}

.ex-progress {
  width: 100%;
  height: 4px;
  background: rgba(255, 255, 255, 0.05);
  border-radius: 2px;
  margin-top: 8px;
  overflow: hidden;
}

.progress-bar-loading {
  width: 40%;
  height: 100%;
  background: var(--color-primary);
  animation: slideLoading 1s infinite ease-in-out;
}

@keyframes slideLoading {
  from { transform: translateX(-100%); }
  to { transform: translateX(250%); }
}

.btn-export {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 16px;
  border-radius: 10px;
  border: 1px solid rgba(255, 255, 255, 0.1);
  background: rgba(255, 255, 255, 0.05);
  color: white;
  font-size: 0.8rem;
  font-weight: 800;
  cursor: pointer;
  transition: all 0.2s ease;
}

.btn-export:hover {
  background: white;
  color: black;
  transform: translateY(-2px);
}

/* OVERRIDE STYLES */
.discount-recap-box .box-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.bh-stats {
  display: flex;
  gap: 24px;
}

.mini-stat {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
}

.ms-lab {
  font-size: 0.65rem;
  color: var(--color-text-dim);
  text-transform: uppercase;
}

.ms-val {
  font-size: 1.2rem;
  font-weight: 800;
}

.empty-text {
  padding: 40px;
  text-align: center;
  color: var(--color-text-dim);
  font-style: italic;
}

.btn-export:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

/* Animations */
.tab-fade-enter-active, .tab-fade-leave-active {
  transition: all 0.25s ease;
}

.tab-fade-enter-from { opacity: 0; transform: translateX(10px); }
.tab-fade-leave-to { opacity: 0; transform: translateX(-10px); }

.animate-fade-in { animation: fadeIn 0.6s ease-out; }
@keyframes fadeIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }

.animate-fade-up { animation: fadeUp 0.5s ease-out forwards; opacity: 0; }
@keyframes fadeUp {
  from { opacity: 0; transform: translateY(20px); }
  to { opacity: 1; transform: translateY(0); }
}

/* BANK SECTION STYLES */
.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
}

.bank-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 20px;
}

.bank-card {
  padding: 24px;
  position: relative;
  overflow: hidden;
  transition: all 0.3s ease;
  cursor: pointer;
}

.bank-card:hover {
  transform: translateY(-5px);
  border-color: rgba(245, 158, 11, 0.3);
}

.bank-card.empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: 180px;
  background: rgba(255, 255, 255, 0.02);
}

.card-glow {
  position: absolute;
  top: -50%;
  left: -50%;
  width: 200%;
  height: 200%;
  background: radial-gradient(circle, rgba(245, 158, 11, 0.05) 0%, transparent 70%);
  pointer-events: none;
}

.bc-header {
  display: flex;
  align-items: center;
  gap: 16px;
  margin-bottom: 24px;
}

.bank-icon {
  width: 48px;
  height: 48px;
  border-radius: 12px;
  background: rgba(255, 255, 255, 0.05);
  display: flex;
  align-items: center;
  justify-content: center;
  color: #f59e0b;
}

.bc-body {
  margin-bottom: 16px;
}

.acc-balance {
  margin-top: 4px;
}

/* SCHEDULE CARD STYLES */
.schedule-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
  gap: 20px;
}

.schedule-card {
  padding: 20px;
  transition: all 0.3s ease;
}

.schedule-card.inactive {
  opacity: 0.6;
  filter: grayscale(0.5);
}

.sc-header {
  display: flex;
  align-items: center;
  gap: 16px;
}

.sc-icon-box {
  width: 44px;
  height: 44px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(255, 255, 255, 0.05);
}

.sc-icon-box.pnl { color: #f59e0b; background: rgba(245, 158, 11, 0.1); }
.sc-icon-box.sales { color: #14b8a6; background: rgba(20, 184, 166, 0.1); }
.sc-icon-box.stock { color: #3b82f6; background: rgba(59, 130, 246, 0.1); }

.sc-meta { flex: 1; }
.sc-meta h4 { font-size: 0.95rem; font-weight: 800; color: white; margin-bottom: 2px; }

.sc-actions { display: flex; gap: 8px; }

.sc-info-row {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 0.8rem;
  font-weight: 600;
  color: rgba(255, 255, 255, 0.8);
}

.btn-icon {
  background: transparent;
  border: none;
  cursor: pointer;
  padding: 4px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
}

.btn-icon:hover { transform: scale(1.1); }

/* MODAL & FORM STYLES */
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.7);
  backdrop-filter: blur(10px);
  z-index: 1000;
  display: flex;
  justify-content: flex-end;
}

.slide-over-form {
  width: 450px;
  height: 100%;
  padding: 40px;
  display: flex;
  flex-direction: column;
  border-radius: 0;
  border-left: 1px solid rgba(255, 255, 255, 0.1);
}

.animate-slide-in {
  animation: slideIn 0.4s cubic-bezier(0.23, 1, 0.32, 1);
}

@keyframes slideIn {
  from { transform: translateX(100%); }
  to { transform: translateX(0); }
}

.form-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 40px;
}

.btn-close {
  background: transparent;
  border: none;
  color: white;
  font-size: 2rem;
  line-height: 1;
  cursor: pointer;
}

.form-body {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.form-group label {
  font-size: 0.7rem;
  font-weight: 800;
  color: var(--color-text-dim);
  letter-spacing: 0.1em;
}

.form-input {
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 12px;
  padding: 12px 16px;
  color: white;
  font-size: 0.95rem;
  transition: all 0.2s ease;
}

.form-input:focus {
  outline: none;
  border-color: #f59e0b;
  background: rgba(255, 255, 255, 0.1);
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

.tx-pill {
  font-size: 0.65rem;
  font-weight: 900;
  padding: 2px 8px;
  border-radius: 4px;
}

.tx-pill.masuk { background: rgba(16, 185, 129, 0.1); color: #10b981; }
.tx-pill.keluar { background: rgba(239, 68, 68, 0.1); color: #ef4444; }

.empty-schedule {
  padding: 40px;
  text-align: center;
  background: rgba(255, 255, 255, 0.02);
  border-radius: 16px;
  cursor: pointer;
}
</style>
