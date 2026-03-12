<template>
  <div class="financial-terminal page-container">
    <header class="page-header">
      <div>
        <h1 class="hero-font text-gradient">Financial Terminal</h1>
        <p class="text-dim">Comprehensive Revenue & Logistics Intelligence</p>
      </div>

      <!-- Global Date Range Filter for Tabs -->
      <div class="filters">
        <div class="glass-panel filter-group period-dropdown-wrapper" tabindex="0" @blur="isDropdownOpen = false">
          <div class="period-trigger" @click="isDropdownOpen = !isDropdownOpen">
            <CalendarIcon class="icon-sm text-primary" />
            <span class="text-dim">Period:</span>
            <span class="period-value font-bold">{{ periodLabel }}</span>
            <ChevronDownIcon class="icon-xs chevron" :class="{ 'rotate': isDropdownOpen }" />
          </div>
          <Transition name="fade-slide">
             <div class="period-menu glass-panel" v-if="isDropdownOpen">
                <div class="period-option" :class="{ active: selectedPeriod === 'today' }" @click="selectPeriod('today')">Today</div>
                <div class="period-option" :class="{ active: selectedPeriod === 'this_week' }" @click="selectPeriod('this_week')">This Week</div>
                <div class="period-option" :class="{ active: selectedPeriod === 'this_month' }" @click="selectPeriod('this_month')">This Month</div>
                <div class="period-option" :class="{ active: selectedPeriod === 'this_quarter' }" @click="selectPeriod('this_quarter')">This Quarter</div>
                <div class="period-option" :class="{ active: selectedPeriod === 'custom' }" @click="selectPeriod('custom')">Custom Range</div>
             </div>
          </Transition>
        </div>
        
        <div class="glass-panel filter-group" v-if="selectedPeriod === 'custom'">
          <input type="date" v-model="customStartDate" class="date-input" />
          <span class="text-dim">-</span>
          <input type="date" v-model="customEndDate" class="date-input" />
        </div>

        <button class="btn-primary" @click="fetchFinancialData" :disabled="loading">
          <RefreshCcwIcon class="icon-sm" :class="{ 'spin': loading }" />
          <span>{{ loading ? 'SYNCING...' : 'SYNC DATA' }}</span>
        </button>
      </div>
    </header>

    <!-- TAB NAVIGATION -->
    <div class="tabs-nav glass-panel">
      <button 
        v-for="tab in tabs" 
        :key="tab.id"
        class="tab-btn"
        :class="{ active: currentTab === tab.id }"
        @click="currentTab = tab.id"
      >
        <component :is="tab.icon" class="tab-icon" />
        <span>{{ tab.label }}</span>
      </button>
    </div>

    <!-- MAIN CONTENT AREA -->
    <main class="tab-content" v-if="!loading">
      
      <!-- TAB 1: PROFIT & LOSS OVERVIEW -->
      <Transition name="fade" mode="out-in">
        <div v-if="currentTab === 'overview'" class="tab-pane">
          <div class="kpi-grid">
            <!-- Row 1: 4 Cards -->
            <div class="kpi-card glass-panel">
              <span class="kpi-label">TOTAL PENDAPATAN</span>
              <h3 class="kpi-value text-success">Rp {{ totalRevenue.toLocaleString() }}</h3>
              <ActivityIcon class="kpi-icon icon-success" />
            </div>
            <div class="kpi-card glass-panel">
              <span class="kpi-label">LABA KOTOR</span>
              <h3 class="kpi-value text-gradient">Rp {{ grossProfit.toLocaleString() }}</h3>
              <DollarSignIcon class="kpi-icon icon-primary" />
            </div>
            <div class="kpi-card glass-panel">
              <span class="kpi-label">NET POSITION</span>
              <h3 class="kpi-value" :class="netCashFlow >= 0 ? 'text-success' : 'text-danger'">
                Rp {{ netCashFlow.toLocaleString() }}
              </h3>
              <ArrowLeftRightIcon class="kpi-icon" :class="netCashFlow >= 0 ? 'text-success' : 'text-danger'" />
            </div>
            <div class="kpi-card glass-panel">
              <span class="kpi-label">UTANG SUPPLIER</span>
              <h3 class="kpi-value text-danger">Rp {{ totalUtang.toLocaleString() }}</h3>
              <ClockIcon class="kpi-icon icon-danger" />
            </div>

            <!-- Row 2: 2 Cards (Full Width or Spaced) -->
            <div class="kpi-card glass-panel kpi-wide">
              <span class="kpi-label">PIUTANG AKTIF</span>
              <h3 class="kpi-value text-warning">Rp {{ totalPiutang.toLocaleString() }}</h3>
              <HourglassIcon class="kpi-icon icon-warning" />
            </div>
            <div class="kpi-card glass-panel kpi-wide">
              <span class="kpi-label">NILAI STOK (ASSET)</span>
              <h3 class="kpi-value text-info">Rp {{ nilaiStok.toLocaleString() }}</h3>
              <PackageIcon class="kpi-icon icon-info" />
            </div>
          </div>

          <!-- Chart Area -->
          <div class="chart-container glass-panel">
            <h3 class="section-title">Revenue vs COGS vs Gross Profit</h3>
            <div class="chart-wrapper">
              <LineChart v-if="chartData.labels.length > 0" :data="chartData" :options="chartOptions" />
              <div v-else class="empty-state text-dim">No paid transactions in selected period.</div>
            </div>
          </div>

          <!-- P&L Table -->
          <div class="pnl-table-container glass-panel">
            <h3 class="section-title">Profitability by Product</h3>
            <table class="financial-table">
              <thead>
                <tr>
                  <th>Product</th>
                  <th class="text-right">Units Sold</th>
                  <th class="text-right">Revenue</th>
                  <th class="text-right">COGS (HPP)</th>
                  <th class="text-right">Gross Profit</th>
                  <th class="text-right">Margin</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="pn in productPnL" :key="pn.label">
                  <td class="product-name">
                     <span class="dot" :class="pn.label === 'Telur Hero' ? 'dot-hero' : 'dot-salted'"></span>
                     {{ pn.label }}
                  </td>
                  <td class="text-right">{{ pn.qty }} Pack</td>
                  <td class="text-right text-success font-mono font-bold">Rp {{ pn.rev.toLocaleString() }}</td>
                  <td class="text-right text-danger font-mono">Rp {{ pn.cogs.toLocaleString() }}</td>
                  <td class="text-right text-primary font-mono font-black">Rp {{ pn.gp.toLocaleString() }}</td>
                  <td class="text-right font-mono font-bold" :class="getMarginClass(pn.margin)">{{ pn.margin.toFixed(1) }}%</td>
                </tr>
                <tr v-if="productPnL.length === 0">
                  <td colspan="6" class="text-center text-dim py-6">No data available for this period.</td>
                </tr>
              </tbody>
            </table>

            <div class="laba-row">
              <div>
                <p class="laba-label">LABA KOTOR BERSIH</p>
                <p class="laba-value success">Rp {{ grossProfit.toLocaleString() }}</p>
              </div>
              <div>
                <p class="laba-label">MARGIN KESELURUHAN</p>
                <p class="laba-value margin">{{ grossMargin.toFixed(1) }}%</p>
              </div>
            </div>
          </div>
        </div>
      </Transition>

      <!-- TAB 2: CASH FLOW TRACKER -->
      <Transition name="fade" mode="out-in">
        <div v-if="currentTab === 'cashflow'" class="tab-pane">
          <!-- Cash Flow Tracker -->
          <div class="cashflow-grid">
            <!-- MONEY IN -->
            <div class="cf-glass glass-panel border-success">
              <h3 class="cf-title text-success"><TrendingUpIcon class="icon-sm" /> MONEY IN (PEMASUKAN)</h3>
              <div class="table-scroll">
                <table class="financial-table">
                  <thead>
                    <tr>
                      <th>Date</th>
                      <th>Invoice ID</th>
                      <th>Customer</th>
                      <th class="text-right">Amount</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="sale in paidSalesList" :key="sale.id">
                      <td>{{ formatDate(sale.created_at) }}</td>
                      <td class="text-dim">#{{ sale.id.toString().substring(0,6).toUpperCase() }}</td>
                      <td>{{ sale.customers?.name || 'Guest' }}</td>
                      <td class="text-right">Rp {{ Number(sale.total_price).toLocaleString() }}</td>
                    </tr>
                    <tr v-if="paidSalesList.length === 0">
                      <td colspan="4" class="text-center text-dim py-6">No income recorded.</td>
                    </tr>
                  </tbody>
                </table>
              </div>
              <div class="cf-footer text-success">
                <span>Subtotal Money In</span>
                <span>Rp {{ totalMoneyIn.toLocaleString() }}</span>
              </div>
            </div>

            <!-- MONEY OUT -->
            <div class="cf-glass glass-panel border-danger">
              <h3 class="cf-title text-danger"><ActivityIcon class="icon-sm" /> MONEY OUT (PENGELUARAN)</h3>
              <div class="table-scroll">
                <table class="financial-table">
                  <thead>
                    <tr>
                      <th>Date</th>
                      <th>Item Restocked</th>
                      <th>Supplier</th>
                      <th class="text-right">Total Cost</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="log in restockLogsList" :key="log.id">
                      <td>{{ formatDate(log.created_at) }}</td>
                      <td>{{ log.inventory?.name || 'Unknown Item' }}</td>
                      <td class="text-dim">{{ extractSupplierFromNotes(log.notes) || '-' }}</td>
                      <td class="text-right">Rp {{ (Number(log.unit_price) * Math.abs(Number(log.change))).toLocaleString() }}</td>
                    </tr>
                    <tr v-if="restockLogsList.length === 0">
                      <td colspan="4" class="text-center text-dim py-6">No expenses recorded.</td>
                    </tr>
                  </tbody>
                </table>
              </div>
              <div class="cf-footer text-danger">
                <span>Subtotal Money Out</span>
                <span>Rp {{ totalMoneyOut.toLocaleString() }}</span>
              </div>
            </div>
          </div>

          <!-- NET SUMMARY -->
          <div class="net-cashflow-card glass-panel text-center">
            <p class="text-dim mb-2 font-bold">NET CASH FLOW</p>
            <h1 class="hero-font" :class="netCashFlow >= 0 ? 'text-success' : 'text-danger'">
              {{ netCashFlow >= 0 ? '+' : '' }} Rp {{ netCashFlow.toLocaleString() }}
            </h1>
            <div class="cf-bar-container">
              <div class="cf-bar cf-in" :style="{ width: inRatio + '%' }"></div>
              <div class="cf-bar cf-out" :style="{ width: outRatio + '%' }"></div>
            </div>
          </div>
        </div>
      </Transition>

      <!-- TAB 3: RECEIVABLES TRACKER -->
      <Transition name="fade" mode="out-in">
        <div v-if="currentTab === 'receivables'" class="tab-pane">
          <div class="glass-panel pnl-table-container">
            <h3 class="section-title text-warning"><FileWarningIcon class="icon-sm" /> PENDING RECEIVABLES (PIUTANG)</h3>
            <div class="table-scroll" style="height: 500px;">
              <table class="financial-table">
                <thead>
                  <tr>
                    <th>Date</th>
                    <th>Invoice ID</th>
                    <th>Customer</th>
                    <th class="text-right">Amount</th>
                    <th class="text-center">Days Outstanding</th>
                    <th class="text-center">Action</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="rec in pendingReceivables" :key="rec.id">
                    <td>{{ formatDate(rec.created_at) }}</td>
                    <td class="text-dim">#{{ rec.id.toString().substring(0,6).toUpperCase() }}</td>
                    <td class="font-bold">{{ rec.customers?.name || 'Unknown' }}</td>
                    <td class="text-right text-warning font-bold">Rp {{ Number(rec.total_price).toLocaleString() }}</td>
                    <td class="text-center font-bold" :class="getDaysOutstanding(rec.created_at) > 7 ? 'text-danger' : 'text-dim'">
                      {{ getDaysOutstanding(rec.created_at) }} Days
                    </td>
                    <td class="text-center">
                      <button class="btn-tactical btn-small" @click="markAsPaid(rec.id)" :disabled="actionLoading === rec.id">
                        <span v-if="actionLoading === rec.id">Processing...</span>
                        <span v-else>Mark Paid</span>
                      </button>
                    </td>
                  </tr>
                  <tr v-if="pendingReceivables.length === 0">
                    <td colspan="6" class="text-center text-dim py-6">No pending receivables. Excellent!</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </Transition>

      <!-- TAB 4: PROFITABILITY MATRIX -->
      <Transition name="fade" mode="out-in">
        <div v-if="currentTab === 'profitability'" class="tab-pane">
          <div class="profitability-grid">
            <!-- Product Cards -->
            <div class="product-cards-container">
              <div v-for="pn in productPnL" :key="pn.label" class="prof-card glass-panel" :class="{'hero-border': pn.label==='Telur Hero', 'asin-border': pn.label==='Salted Egg'}">
                 <div class="prof-header">
                   <h3 class="product-title">
                     <span class="dot" :class="pn.label === 'Telur Hero' ? 'dot-hero' : 'dot-salted'"></span>
                     {{ pn.label }}
                   </h3>
                   <span class="qty-badge">{{ pn.qty }} Units Sold</span>
                 </div>
                 <div class="prof-metrics">
                   <div class="metric">
                     <span class="text-dim">Revenue</span>
                     <span class="text-success font-bold">Rp {{ pn.rev.toLocaleString() }}</span>
                   </div>
                   <div class="metric">
                     <span class="text-dim">COGS</span>
                     <span class="text-danger font-bold">Rp {{ pn.cogs.toLocaleString() }}</span>
                   </div>
                   <div class="metric">
                     <span class="text-dim">Gross Profit</span>
                     <span class="text-primary font-bold">Rp {{ pn.gp.toLocaleString() }}</span>
                   </div>
                 </div>
                 <div class="prof-margin-box">
                   <div class="margin-header">
                     <span class="text-dim font-bold">MARGIN HEALTH</span>
                     <span class="font-bold" :class="getMarginClass(pn.margin)">{{ pn.margin.toFixed(1) }}%</span>
                   </div>
                   <div class="cf-bar-container" style="margin-top: 8px;">
                     <div class="cf-bar" :class="getMarginBgClass(pn.margin)" :style="{ width: Math.min(pn.margin, 100) + '%' }"></div>
                   </div>
                 </div>
              </div>
              <div v-if="productPnL.length === 0" class="empty-state text-dim glass-panel">
                No product data available in this period.
              </div>
            </div>

            <!-- Radar Chart -->
            <div class="radar-container glass-panel">
               <h3 class="section-title text-center mb-2">Performance Comparison (Normalized)</h3>
               <p class="text-dim text-center" style="font-size: 0.75rem; margin-bottom: 24px;">Comparing Revenue, Margin, and Volume vs Top Performer</p>
               <div class="radar-wrapper">
                 <RadarChart v-if="radarChartData.labels.length > 0" :data="radarChartData" :options="radarChartOptions" />
               </div>
            </div>
          </div>
        </div>
      </Transition>

      <!-- TAB 5: REPORTS EXPORT -->
      <Transition name="fade" mode="out-in">
        <div v-if="currentTab === 'export'" class="tab-pane">
          <div class="glass-panel text-center" style="padding: 40px; border-radius: 20px;">
            <div v-if="!authStore.isAdmin" class="text-danger font-bold">
              <BanIcon class="icon" /> <br/>
              ACCESS DENIED. Administrators only.
            </div>
            <div v-else>
              <h2 class="hero-font text-gradient mb-2">Data Export Center</h2>
              <p class="text-dim" style="margin-bottom: 32px">Download your financial intelligence for external auditing and backup purposes.</p>
              
              <div class="export-grid">
                <button class="export-btn glass-panel" @click="exportPnL">
                  <BarChart3Icon class="ex-icon icon-primary" />
                  <div class="ex-text">
                    <h4>P&L Summary</h4>
                    <span class="text-dim">Profit & Loss Metrics (CSV)</span>
                  </div>
                  <DownloadCloudIcon class="ex-dl" />
                </button>

                <button class="export-btn glass-panel" @click="exportSales">
                  <ActivityIcon class="ex-icon icon-success" />
                  <div class="ex-text">
                    <h4>Sales Recap</h4>
                    <span class="text-dim">Paid Transactions (CSV)</span>
                  </div>
                  <DownloadCloudIcon class="ex-dl" />
                </button>

                <button class="export-btn glass-panel" @click="exportStock">
                  <TrendingUpIcon class="ex-icon icon-warning" />
                  <div class="ex-text">
                    <h4>Stock Movement</h4>
                    <span class="text-dim">Restock & Adjustments (CSV)</span>
                  </div>
                  <DownloadCloudIcon class="ex-dl" />
                </button>

                <button class="export-btn glass-panel" @click="exportReceivables">
                  <FileWarningIcon class="ex-icon icon-danger" />
                  <div class="ex-text">
                    <h4>Receivables</h4>
                    <span class="text-dim">Pending Piutang Data (CSV)</span>
                  </div>
                  <DownloadCloudIcon class="ex-dl" />
                </button>

                <button class="export-btn glass-panel" @click="exportBackup">
                  <TargetIcon class="ex-icon icon-dim" />
                  <div class="ex-text">
                    <h4>Full System Backup</h4>
                    <span class="text-dim">Raw Database Dump (JSON)</span>
                  </div>
                  <DownloadCloudIcon class="ex-dl" />
                </button>
              </div>
            </div>
          </div>
        </div>
      </Transition>

    </main>

    <!-- LOADING STATE -->
    <div v-else class="loading-state glass-panel">
      <div class="pulse-ring"></div>
      <p class="hero-font text-gradient">SYNTHESIZING FINANCIAL DATA...</p>
    </div>

  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed, watch } from 'vue';
import { supabase } from '../lib/supabase';
import { 
  BarChart3Icon, 
  ArrowLeftRightIcon, 
  FileWarningIcon, 
  TargetIcon, 
  DownloadCloudIcon,
  CalendarIcon,
  RefreshCcwIcon,
  DollarSignIcon,
  ActivityIcon,
  TrendingUpIcon,
  ClockIcon,
  BanIcon,
  ChevronDownIcon,
  HourglassIcon,
  PackageIcon
} from 'lucide-vue-next';

// Chart.js imports
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  RadarController,
  RadialLinearScale,
  Title,
  Tooltip,
  Legend
} from 'chart.js';
import { Line as LineChart, Radar as RadarChart } from 'vue-chartjs';
import { useAuthStore } from '../stores/auth';
import { normalizeGrade, getGradeLabel } from '../constants/grades';
import { withTimeout } from '../utils/safeAsync';

ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  RadarController,
  RadialLinearScale,
  Title,
  Tooltip,
  Legend
);

const authStore = useAuthStore();

const currentTab = ref('overview');
const loading = ref(false);

const selectedPeriod = ref('this_month');
const customStartDate = ref('');
const customEndDate = ref('');
const isDropdownOpen = ref(false);

const periodLabel = computed(() => {
  const map: Record<string, string> = {
    'today': 'Today',
    'this_week': 'This Week',
    'this_month': 'This Month',
    'this_quarter': 'This Quarter',
    'custom': 'Custom Range'
  };
  return map[selectedPeriod.value] || 'Select Period';
});

function selectPeriod(period: string) {
  selectedPeriod.value = period;
  isDropdownOpen.value = false;
}

const tabs = [
  { id: 'overview', label: 'P&L Overview', icon: BarChart3Icon },
  { id: 'cashflow', label: 'Cash Flow', icon: ArrowLeftRightIcon },
  { id: 'receivables', label: 'Receivables', icon: FileWarningIcon },
  { id: 'profitability', label: 'Profitability Matrix', icon: TargetIcon },
  { id: 'export', label: 'Data Export', icon: DownloadCloudIcon }
];

// Data state
const allSales = ref<any[]>([]);
const restockLogs = ref<any[]>([]);
const pendingReceivables = ref<any[]>([]);
const utangSupplierList = ref<any[]>([]);
const inventoryMap = ref<Record<string, any>>({});
const summaryRev = ref<number | null>(null);
const summaryCogs = ref<number | null>(null);
const summaryPiutang = ref<number | null>(null);
const summaryUtang = ref<number | null>(null);
const summaryStockVal = ref<number | null>(null);

const formatToDateString = (date: Date) => {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
};

function getDateRange() {
  const now = new Date();
  let start = new Date();
  let end = new Date();

  if (selectedPeriod.value === 'today') {
    start.setHours(0,0,0,0);
  } else if (selectedPeriod.value === 'this_week') {
    const day = now.getDay();
    const diff = now.getDate() - day + (day === 0 ? -6 : 1);
    start.setDate(diff);
    start.setHours(0,0,0,0);
  } else if (selectedPeriod.value === 'this_month') {
    start = new Date(now.getFullYear(), now.getMonth(), 1);
  } else if (selectedPeriod.value === 'this_quarter') {
    const quarter = Math.floor(now.getMonth() / 3);
    start = new Date(now.getFullYear(), quarter * 3, 1);
  } else if (selectedPeriod.value === 'custom') {
    if (customStartDate.value) start = new Date(customStartDate.value);
    if (customEndDate.value) {
      end = new Date(customEndDate.value);
    }
  }

  return { 
    startDate: formatToDateString(start), 
    endDate: formatToDateString(end) 
  };
}

async function fetchFinancialData() {
  loading.value = true;
  try {
    const { startDate, endDate } = getDateRange();
    const endDateTime = endDate + 'T23:59:59';

    // 0. Fetch all inventory items for lookup
    const { data: invData } = await withTimeout(
      supabase.from('inventory').select('id, label, grade, hpp_per_pack, current_stock'),
      8000, 'fin-inventory'
    );
    
    const invMap: Record<string, any> = {};
    (invData || []).forEach((item: any) => { invMap[item.id] = item; });
    inventoryMap.value = invMap;

    // 1. Fetch Sales with nested sale_items (Using string dates for timezone fix)
    const { data: salesData, error: salesError } = await withTimeout(
      supabase.from('sales')
        .select('*, customers(name), sale_items(*)')
        .gte('created_at', startDate)
        .lte('created_at', endDateTime),
      12000, 'fin-sales'
    );
    
    if (salesError) console.error('Sales query failed:', salesError);
    allSales.value = salesData || [];

    // 2. Fetch stock arrival logs
    const { data: stockLogsData } = await withTimeout(
      supabase.from('stock_logs')
        .select('*')
        .eq('log_type', 'arrival')
        .gte('created_at', startDate)
        .lte('created_at', endDateTime),
      8000, 'fin-stock-logs'
    );
    
    restockLogs.value = stockLogsData || [];

    // 3. Fetch Pending Receivables (Piutang table)
    const { data: piutangData } = await withTimeout(
      supabase.from('piutang')
        .select('*, customers(name)')
        .gt('remaining', 0)
        .order('created_at', { ascending: true }),
      8000, 'fin-piutang'
    );
    
    pendingReceivables.value = piutangData || [];

    // 5. Fetch P&L Summary from RPC
    // Note: If you get 400 Error, ensure p_start_date/p_end_date parameter names match.
    const { data: pnlSummary, error: pnlError } = await withTimeout(
      supabase.rpc('get_pnl_summary', {
        start_date: startDate,
        end_date: endDate
      }),
      12000, 'fin-rpc'
    );

    if (pnlError) {
      console.warn('P&L RPC failed, using local fallback:', pnlError);
      // Fallback: reset summary values to let computed properties handle it
      summaryRev.value = null;
      summaryCogs.value = null;
    } else if (pnlSummary && pnlSummary.length > 0) {
      const p = pnlSummary[0];
      summaryRev.value = Number(p.total_revenue);
      summaryCogs.value = Number(p.total_cogs);
      summaryPiutang.value = Number(p.total_piutang_active);
      summaryUtang.value = Number(p.total_utang_active);
      summaryStockVal.value = Number(p.inventory_asset_value);
    }
    // We'll keep our local allSales fetch for the chart and tables, but the summary RPC provides the "Ground Truth" for KPIs.
    
  } catch (error) {
    console.error('Data sync failed:', error);
  } finally {
    loading.value = false;
  }
}

// ========================
// KPIs for TAB 1
// ========================

// 1. Total Revenue (Paid)
const totalRevenue = computed(() => {
  if (summaryRev.value !== null) return summaryRev.value;
  const sum = allSales.value
    .filter(s => s.payment_status === 'paid' && !s.voided_at)
    .reduce((sum, s) => sum + Number(s.total_price || s.total_revenue || 0), 0);
  return sum;
});

const totalCOGS = computed(() => {
  if (summaryCogs.value !== null) return summaryCogs.value;
  return allSales.value
    .filter(s => s.payment_status === 'paid' && !s.voided_at)
    .reduce((sum, s) => {
      const items = s.sale_items || [];
      return sum + items.reduce((iSum: number, i: any) => {
        // PRIORITIZE: 1. hpp_per_pack (captured at sale) 2. item.unit_cost 3. current inventory map
        const cost = i.hpp_per_pack || i.unit_cost || (inventoryMap.value[normalizeGrade(i.egg_type || i.inventory_id)]?.hpp_per_pack) || 0;
        return iSum + (Number(cost) * (i.packs_sold || i.quantity || 0));
      }, 0);
    }, 0);
});

const totalUtang = computed(() => utangSupplierList.value.reduce((s, u) => s + Number(u.remaining || 0), 0));
const totalPiutang = computed(() => pendingReceivables.value.reduce((s, p) => s + Number(p.remaining || p.total_price || 0), 0));

const nilaiStok = computed(() => {
  return ['hero', 'salted_egg'].reduce((sum, id) => {
    const item = inventoryMap.value[id];
    if (!item) return sum;
    return sum + (Number(item.current_stock || 0) * Number(item.hpp_per_egg || (item.hpp_per_pack / 10) || 0));
  }, 0);
});

// 3. Gross Profit
const grossProfit = computed(() => totalRevenue.value - totalCOGS.value);

// 4. Gross Margin %
const grossMargin = computed(() => {
  if (totalRevenue.value === 0) return 0;
  return (grossProfit.value / totalRevenue.value) * 100;
});

// Chart Data
const chartData = computed(() => {
  const dailyData: Record<string, { rev: number, cogs: number, gp: number }> = {};
  
  allSales.value.filter(s => s.payment_status === 'paid').forEach(s => {
    const dateStr = s.created_at.substring(0, 10);
    if (!dailyData[dateStr]) dailyData[dateStr] = { rev: 0, cogs: 0, gp: 0 };
    
    const rev = Number(s.total_price || s.total_revenue || 0);
    dailyData[dateStr].rev += rev;
    
    const items = s.sale_items || [];
    const itemsCost = items.reduce((curSum: number, i: any) => {
      const cost = i.hpp_per_pack || i.unit_cost || (inventoryMap.value[i.egg_type]?.hpp_per_pack) || 0;
      return curSum + (Number(cost) * (i.packs_sold || i.quantity || 0));
    }, 0);
    
    dailyData[dateStr].cogs += itemsCost;
    dailyData[dateStr].gp += (Number(s.total_price) - itemsCost);
  });

  const sortedDates = Object.keys(dailyData).sort();
  
  return {
    labels: sortedDates,
    datasets: [
      {
        label: 'Gross Profit',
        backgroundColor: '#f59e0b',
        borderColor: '#f59e0b',
        data: sortedDates.map(d => dailyData[d]!.gp),
        tension: 0.4
      },
      {
        label: 'Revenue',
        backgroundColor: '#10b981',
        borderColor: '#10b981',
        data: sortedDates.map(d => dailyData[d]!.rev),
        tension: 0.4
      },
      {
        label: 'COGS',
        backgroundColor: '#ef4444',
        borderColor: '#ef4444',
        data: sortedDates.map(d => dailyData[d]!.cogs),
        tension: 0.4
      }
    ]
  };
});

const chartOptions: any = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: { labels: { color: '#94a3b8', font: { family: 'Inter', weight: 600 } } },
    tooltip: { mode: 'index', intersect: false }
  },
  scales: {
    x: { ticks: { color: '#94a3b8' }, grid: { color: 'rgba(255,255,255,0.05)' } },
    y: { ticks: { color: '#94a3b8' }, grid: { color: 'rgba(255,255,255,0.05)' } }
  }
};

// P&L Products
const productPnL = computed(() => {
  const products: Record<string, { label: string, rev: number, cogs: number, qty: number }> = {
    hero: { label: getGradeLabel('hero'), rev: 0, cogs: 0, qty: 0 },
    salted_egg: { label: getGradeLabel('salted_egg'), rev: 0, cogs: 0, qty: 0 }
  };
  
  allSales.value.filter(s => s.payment_status === 'paid').forEach(s => {
    const items = s.sale_items || [];
    items.forEach((i: any) => {
      const type = normalizeGrade(i.egg_type || i.inventory_id);
      if (products[type]) {
        const prod = products[type]!;
        prod.qty += (i.packs_sold || i.quantity || 0);
        prod.rev += Number(i.revenue || i.subtotal || (i.unit_price * i.quantity));
        const itemCost = i.hpp_per_pack || i.unit_cost || (inventoryMap.value[type]?.hpp_per_pack) || 0;
        prod.cogs += (Number(itemCost) * (i.packs_sold || i.quantity || 0));
      }
    });
  });
  
  return Object.values(products).filter(p => p.qty > 0).map(p => {
    const gp = p.rev - p.cogs;
    const margin = p.rev > 0 ? (gp / p.rev) * 100 : 0;
    return { ...p, gp, margin };
  });
});

function getMarginClass(margin: number) {
  if (margin < 15) return 'text-danger';
  if (margin < 30) return 'text-warning';
  return 'text-success';
}

function getMarginBgClass(margin: number) {
  if (margin < 15) return 'cf-out'; // red bg
  if (margin < 30) return 'bg-warning'; // yellow bg
  return 'cf-in'; // green bg
}

// Radar Chart Data & Options
const radarChartData = computed(() => {
  if (productPnL.value.length === 0) return { labels: [], datasets: [] };

  const maxRev = Math.max(...productPnL.value.map(p => p.rev)) || 1;
  const maxQty = Math.max(...productPnL.value.map(p => p.qty)) || 1;
  const maxMargin = Math.max(...productPnL.value.map(p => p.margin)) || 1;

  const getDataset = (p: any, colorStr: string, bgColorStr: string) => {
    return {
      label: p.label,
      data: [
         (p.rev / maxRev) * 100,
         (p.margin / maxMargin) * 100,
         (p.qty / maxQty) * 100
      ],
      backgroundColor: bgColorStr,
      borderColor: colorStr,
      pointBackgroundColor: colorStr,
      pointBorderColor: '#fff',
      pointHoverBackgroundColor: '#fff',
      pointHoverBorderColor: colorStr
    };
  };

  const datasets = productPnL.value.map(p => {
    if (p.label === 'Telur Hero') return getDataset(p, '#f59e0b', 'rgba(245, 158, 11, 0.2)');
    if (p.label === 'Salted Egg') return getDataset(p, '#38bdf8', 'rgba(56, 189, 248, 0.2)');
    return getDataset(p, '#6366f1', 'rgba(99, 102, 241, 0.2)');
  });

  return {
    labels: ['Revenue', 'Profitability (Margin)', 'Sales Volume'],
    datasets
  };
});

const radarChartOptions: any = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: { labels: { color: '#94a3b8', font: { family: 'Inter', weight: 600 } } }
  },
  scales: {
    r: {
      angleLines: { color: 'rgba(255,255,255,0.1)' },
      grid: { color: 'rgba(255,255,255,0.1)' },
      pointLabels: { color: '#f8fafc', font: { family: 'Inter', weight: 800, size: 12 } },
      ticks: { display: false, max: 100, min: 0 }
    }
  }
};

// ========================
// KPIs for TAB 2 (Cash Flow)
// ========================
const paidSalesList = computed(() => [...allSales.value].filter(s => s.payment_status === 'paid').sort((a,b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime()));
const restockLogsList = computed(() => [...restockLogs.value].sort((a,b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime()));

const totalMoneyIn = computed(() => totalRevenue.value);
const totalMoneyOut = computed(() => {
  return restockLogsList.value.reduce((sum, log) => {
    // unit_price = cost per unit, change = quantity added
    // For items without unit_price, try to extract cost from notes
    const unitCost = Number(log.unit_price) || 0;
    const qty = Math.abs(Number(log.change));
    return sum + (unitCost * qty);
  }, 0);
});
const netCashFlow = computed(() => totalMoneyIn.value - totalMoneyOut.value);

const totalFlow = computed(() => totalMoneyIn.value + totalMoneyOut.value);
const inRatio = computed(() => totalFlow.value === 0 ? 50 : (totalMoneyIn.value / totalFlow.value) * 100);
const outRatio = computed(() => totalFlow.value === 0 ? 50 : (totalMoneyOut.value / totalFlow.value) * 100);

function formatDate(dateStr: string) {
  return new Date(dateStr).toLocaleDateString('id-ID', {
    day: '2-digit', month: 'short', year: 'numeric'
  });
}

function extractSupplierFromNotes(notes: string | null | undefined) {
  if (!notes) return '';
  // Stock.vue uses format: "[SupplierName] notes..." or "Purchase: ... | Supplier: Name"
  const bracketMatch = notes.match(/^\[([^\]]+)\]/);
  if (bracketMatch) return bracketMatch[1] || '';
  // Match until end of string OR until the next pipe separator
  const pipeMatch = notes.match(/Supplier:\s*([^|]+)/i);
  if (pipeMatch) return pipeMatch[1]?.trim() || '';
  return '';
}

// ========================
// KPIs for TAB 3 (Receivables)
// ========================
const actionLoading = ref<number | null>(null);

function getDaysOutstanding(createdAt: string) {
  const diffTime = Math.abs(new Date().getTime() - new Date(createdAt).getTime());
  return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
}

async function markAsPaid(saleId: number) {
  if (!confirm('Mark this invoice as PAID? This will update revenue metrics.')) return;
  
  actionLoading.value = saleId;
  try {
    const { error } = await withTimeout(
      supabase
        .from('sales')
        .update({ payment_status: 'paid' })
        .eq('id', saleId),
      8000, 'mark-paid'
    );
      
    if (error) throw error;
    
    // Refresh entirely to recalculate everything
    await fetchFinancialData();
  } catch (err: any) {
    alert('Failed to mark as paid: ' + err.message);
  } finally {
    actionLoading.value = null;
  }
}

// ========================
// KPIs for TAB 5 (Exports)
// ========================

function downloadBlob(content: string, filename: string, mimeType: string) {
  const blob = new Blob([content], { type: mimeType });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}

function exportPnL() {
  let csv = 'Product,Units Sold,Revenue,COGS (HPP),Gross Profit,Margin %\n';
  productPnL.value.forEach(p => {
    csv += `${p.label},${p.qty},${p.rev},${p.cogs},${p.gp},${p.margin.toFixed(2)}\n`;
  });
  csv += `\nTOTAL REVENUE,${totalRevenue.value}\n`;
  csv += `TOTAL COGS,${totalCOGS.value}\n`;
  csv += `GROSS PROFIT,${grossProfit.value}\n`;
  csv += `GROSS MARGIN,${grossMargin.value.toFixed(2)}%\n`;
  downloadBlob(csv, `PnL_Summary_${selectedPeriod.value}.csv`, 'text/csv');
}

function exportSales() {
  let csv = 'Date,Invoice ID,Customer,Total Price,Items Sold\n';
  allSales.value.filter(s => s.payment_status === 'paid').forEach(s => {
    const d = s.created_at;
    const itemsStr = (s.sale_items || []).map((i: any) => `${i.quantity}x ${i.egg_type}`).join('; ');
    csv += `"${d}","${s.id}","${s.customers?.name || 'Guest'}",${s.total_price},"${itemsStr}"\n`;
  });
  downloadBlob(csv, `Sales_Recap_${selectedPeriod.value}.csv`, 'text/csv');
}

function exportStock() {
  let csv = 'Date,Item,Log Type,Change,Unit Price,Total Cost,Supplier,Notes\n';
  restockLogsList.value.forEach(l => {
    const unitCost = Number(l.unit_price) || 0;
    const total = unitCost * Math.abs(Number(l.change));
    const supplier = extractSupplierFromNotes(l.notes) || '-';
    const cleanNotes = (l.notes || '').replace(/"/g, '""');
    csv += `"${l.created_at}","${l.inventory?.name || ''}","${l.log_type}",${l.change},${unitCost},${total},"${supplier}","${cleanNotes}"\n`;
  });
  downloadBlob(csv, `Stock_Movement_${selectedPeriod.value}.csv`, 'text/csv');
}

function exportReceivables() {
  let csv = 'Date,Invoice ID,Customer,Amount,Days Outstanding\n';
  pendingReceivables.value.forEach(r => {
    csv += `"${r.created_at}","${r.id}","${r.customers?.name || 'Unknown'}",${r.total_price},${getDaysOutstanding(r.created_at)}\n`;
  });
  downloadBlob(csv, `Receivables_Pending_${selectedPeriod.value}.csv`, 'text/csv');
}

async function exportBackup() {
  try {
    const backupData: any = {};
    const tables = ['inventory', 'customers', 'suppliers', 'sales', 'sale_items', 'stock_logs', 'price_overrides'];
    
    for (const table of tables) {
      const { data } = await withTimeout(supabase.from(table).select('*'), 15000, `backup-${table}`);
      backupData[table] = data || [];
    }
    
    const jsonStr = JSON.stringify(backupData, null, 2);
    downloadBlob(jsonStr, `HeroFarm_Backup_${new Date().toISOString().substring(0,10)}.json`, 'application/json');
  } catch (e: any) {
    alert('Backup Failed: ' + e.message);
  }
}

watch(selectedPeriod, (newVal) => {
  if (newVal !== 'custom') {
    fetchFinancialData();
  }
});

onMounted(() => {
  fetchFinancialData();
});
</script>

<style scoped>
.financial-terminal {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
}

.filters {
  display: flex;
  gap: 16px;
  align-items: center;
  position: relative;
  z-index: 50;
}

.filter-group {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 20px;
  border-radius: 12px;
  background: rgba(255, 255, 255, 0.02);
  border: 1px solid rgba(255, 255, 255, 0.05);
}

.period-dropdown-wrapper {
  position: relative;
  cursor: pointer;
  outline: none;
  min-width: 200px;
}

.period-trigger {
  display: flex;
  align-items: center;
  gap: 10px;
  width: 100%;
}

.period-value {
  flex: 1;
}

.chevron {
  transition: transform 0.3s ease;
  opacity: 0.6;
}

.chevron.rotate {
  transform: rotate(180deg);
}

.period-menu {
  position: absolute;
  top: calc(100% + 8px);
  left: 0;
  width: 100%;
  padding: 8px !important;
  border-radius: 12px;
  display: flex;
  flex-direction: column;
  gap: 4px;
  z-index: 100;
  box-shadow: 0 10px 40px rgba(0,0,0,0.5);
}

.period-option {
  padding: 10px 16px;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.2s ease;
  font-weight: 600;
}

.period-option:hover {
  background: rgba(255,255,255,0.05);
}

.period-option.active {
  background: rgba(245, 158, 11, 0.15);
  color: var(--color-primary);
}

.date-input {
  background: transparent;
  border: none;
  color: white;
  font-family: inherit;
  font-size: 0.9rem;
  font-weight: 600;
  outline: none;
  cursor: pointer;
}

.fade-slide-enter-active,
.fade-slide-leave-active {
  transition: all 0.3s ease;
}
.fade-slide-enter-from,
.fade-slide-leave-to {
  opacity: 0;
  transform: translateY(-10px);
}

.tabs-nav {
  display: flex;
  gap: 8px;
  padding: 8px;
  border-radius: 16px;
  overflow-x: auto;
  scrollbar-width: none;
}
.tabs-nav::-webkit-scrollbar { display: none; }

.tab-btn {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px 20px;
  border-radius: 12px;
  background: transparent;
  color: var(--color-text-dim);
  font-weight: 700;
  font-size: 0.85rem;
  letter-spacing: 0.05em;
  transition: all 0.3s ease;
  white-space: nowrap;
}

.tab-btn:hover {
  background: rgba(255, 255, 255, 0.05);
  color: white;
}

.tab-btn.active {
  background: rgba(245, 158, 11, 0.15); /* Amber Accent */
  color: #f59e0b;
  border: 1px solid rgba(245, 158, 11, 0.3);
  box-shadow: 0 4px 12px rgba(245, 158, 11, 0.1);
}

.tab-pane {
  min-height: 500px;
}

.temp-placeholder {
  min-height: 400px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 12px;
  color: var(--color-text-dim);
  text-align: center;
  border-radius: 20px;
}

.loading-state {
  min-height: 500px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 20px;
  border-radius: 20px;
}

.pulse-ring {
  width: 60px;
  height: 60px;
  border: 3px solid rgba(245, 158, 11, 0.2);
  border-top-color: #f59e0b;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin { 100% { transform: rotate(360deg); } }

/* FIN TERMINAL CARDS */
.kpi-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
  margin-bottom: 24px;
}

.kpi-wide {
  grid-column: span 2;
}

@media (max-width: 1024px) {
  .kpi-grid { grid-template-columns: 1fr 1fr; }
  .kpi-wide { grid-column: auto; }
}

.kpi-card {
  padding: 20px;
  border-radius: 16px;
  position: relative;
  overflow: hidden;
  animation: fadeIn 0.4s ease-out forwards;
}

.kpi-label {
  font-size: 0.65rem;
  font-weight: 800;
  letter-spacing: 0.1em;
  color: var(--color-text-dim);
  text-transform: uppercase;
  display: block;
  margin-bottom: 8px;
}

.kpi-value {
  font-size: 1.6rem;
  font-weight: 900;
  margin: 0;
}

.kpi-icon {
  position: absolute;
  top: 20px;
  right: 20px;
  opacity: 0.15;
  width: 48px;
  height: 48px;
  transform: rotate(-10deg);
}

/* CHART CONTAINER */
.chart-container {
  padding: 24px;
  border-radius: 20px;
  margin-bottom: 24px;
}

.chart-wrapper {
  height: 350px;
  margin-top: 16px;
}

.empty-state {
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.9rem;
  font-weight: 600;
}

/* PNL TABLE */
.pnl-table-container {
  padding: 24px;
  border-radius: 20px;
}

.financial-table {
  width: 100%;
  border-collapse: collapse;
  margin-top: 16px;
}

.financial-table th {
  text-align: left;
  padding: 12px;
  font-size: 0.7rem;
  font-weight: 800;
  color: var(--color-text-dim);
  text-transform: uppercase;
  letter-spacing: 0.05em;
  border-bottom: 1px solid rgba(255,255,255,0.05);
}

.financial-table td {
  padding: 16px 12px;
  border-bottom: 1px solid rgba(255,255,255,0.02);
  font-size: 0.9rem;
  font-weight: 600;
}

/* Utils */
.text-right { text-align: right; }
.text-center { text-align: center; }
.text-success { color: #10b981; }
.text-danger { color: #ef4444; }
.text-warning { color: #f59e0b; }
.text-primary { color: var(--color-primary); }
.font-bold { font-weight: 800; }
.py-6 { padding-top: 24px; padding-bottom: 24px; }

.product-name {
  display: flex;
  align-items: center;
  gap: 8px;
  font-weight: 700;
}
.dot { width: 8px; height: 8px; border-radius: 50%; display: inline-block; }
.dot-hero { background: #f59e0b; box-shadow: 0 0 8px #f59e0b; }
.dot-standard { background: #10b981; box-shadow: 0 0 8px #10b981; }
.dot-salted { background: #6366f1; box-shadow: 0 0 8px #6366f1; }

.btn-small {
  padding: 6px 12px;
  font-size: 0.75rem;
}

/* EXPORTS (TAB 5) */
.export-grid {
  display: flex;
  flex-direction: column;
  gap: 16px;
  max-width: 600px;
  margin: 0 auto;
}

.export-btn {
  display: flex;
  align-items: center;
  gap: 20px;
  padding: 20px 24px;
  border-radius: 16px;
  background: rgba(255,255,255,0.03);
  border: 1px solid rgba(255,255,255,0.08);
  color: white;
  cursor: pointer;
  transition: all 0.3s ease;
  text-align: left;
}

.export-btn:hover {
  background: rgba(255,255,255,0.08);
  border-color: rgba(255,255,255,0.2);
  transform: translateY(-2px);
}

.ex-icon {
  width: 40px;
  height: 40px;
}

.ex-text {
  flex: 1;
}

.ex-text h4 { margin: 0 0 4px 0; font-size: 1.1rem; font-weight: 800; }
.ex-dl { opacity: 0.5; transition: opacity 0.3s ease; }
.export-btn:hover .ex-dl { opacity: 1; color: var(--color-primary); }

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(10px); }
  to { opacity: 1; transform: translateY(0); }
}

/* CASH FLOW STYLES */
.cashflow-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 24px;
  margin-bottom: 24px;
}

.cf-glass {
  padding: 0;
  border-radius: 20px;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.cf-glass.border-success { border: 1px solid rgba(16, 185, 129, 0.2); }
.cf-glass.border-danger { border: 1px solid rgba(239, 68, 68, 0.2); }

.cf-title {
  padding: 16px 20px;
  margin: 0;
  font-size: 0.8rem;
  font-weight: 800;
  letter-spacing: 0.1em;
  border-bottom: 1px solid rgba(255,255,255,0.05);
  display: flex;
  align-items: center;
  gap: 8px;
}

.table-scroll {
  height: 350px;
  overflow-y: auto;
  padding: 0 8px;
}

.cf-footer {
  padding: 20px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-weight: 900;
  font-size: 1.1rem;
  background: rgba(0, 0, 0, 0.2);
  border-top: 1px solid rgba(255,255,255,0.05);
}

.net-cashflow-card {
  padding: 30px;
  border-radius: 20px;
  margin-bottom: 24px;
}

.mb-2 { margin-bottom: 8px; }

.text-info { color: #38bdf8; }
.icon-info { color: #38bdf8; }

/* LABA SUMMARY */
.laba-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 24px 0 0 0;
  border-top: 1px solid rgba(255,255,255,0.06);
  margin-top: 24px;
}

.laba-label {
  font-size: 0.7rem;
  font-weight: 800;
  letter-spacing: 0.1em;
  color: var(--color-text-dim);
  text-transform: uppercase;
  margin-bottom: 4px;
}

.laba-value {
  font-size: 2.2rem;
  font-weight: 900;
  font-family: 'Outfit', sans-serif;
  margin: 0;
}

.laba-value.success {
  color: #10b981;
}

.laba-value.margin {
  color: #f59e0b;
}

.cf-bar-container {
  display: flex;
  height: 8px;
  border-radius: 4px;
  overflow: hidden;
  margin-top: 24px;
  background: rgba(255,255,255,0.05);
}

.cf-in { background: #10b981; }
.cf-out { background: #ef4444; }
</style>
