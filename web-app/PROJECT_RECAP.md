# 🥚 Hero Farm Terminal — Definitive Developer Context (v2.5)

> Last updated: 2026-03-18 | Use this as the primary reference for all Hero Farm implementations.

---

## 1. Project Stack

| Category | Technology | Version |
|----------|-----------|---------|
| Framework | Vue 3 (Composition API) | ^3.5.25 |
| Build Tool | Vite + TypeScript | Vite ^7.3.1 |
| Styling | Vanilla CSS (Elite Glassmorphism) | Custom UI System |
| Auth & DB | Supabase (PostgreSQL) | @supabase/supabase-js ^2.95.3 |
| State | Pinia | ^3.0.4 |
| Routing | Vue Router | ^4.6.4 |
| Charts | Chart.js + Vue-Chartjs | v4 / v5 |
| Animations | GSAP + CSS Keyframes | GSAP ^3.14.2 |
| Date | date-fns | ^4.1.0 |
| PDF/Print | jsPDF + AutoTable | v4 / v5 |
| Icons | Lucide Vue Next | ^0.566.0 |
| 3D Engine | Three.js + OGL | v0.182.0 (For Premium Visuals) |

---

## 2. Design System & Tokens (Elite Glassmorphism)

### Color Palette (Dark-Premium Theme)

| Token | HEX / RGB | Usage |
|-------|----------|-------|
| `bgBase` | `#06080a` | Deep black-blue page background |
| `glassMain` | `rgba(15, 23, 42, 0.75)` | Primary card & panel background |
| `goldEgg` | `#facc15` | Hero Egg accent, primary CTA, labels |
| `purpleMed` | `#8b5cf6` | Medium Egg accent, secondary labels |
| `blueSmall` | `#38bdf8` | Small Egg/Salted accent, logistics |
| `redCrit` | `#ef4444` | Critical stock alerts, danger actions |
| `greenLive` | `#10b981` | Success state, positive financial markers |
| `textPrimary`| `#f8fafc` | Main body text |
| `textMuted` | `#94a3b8` | Supporting text, labels |

### UI Style Conventions
- **Glasspanels**: `backdrop-filter: blur(20px)`, `border: 1px solid rgba(255,255,255,0.08)`.
- **Radiuses**: `rounded-2xl` for main cards, `rounded-xl` for inputs.
- **Micro-shadows**: `box-shadow: 0 8px 32px 0 rgba(0, 0, 0, 0.37)`.

---

## 3. Global Styles & Typography

### CSS Utilities (`mobile.css` & `style.css`)
- **Typography Scale**:
  - `.hero-font`: Display headings (Gold accent).
  - `.text-metric`: Large numbers (Dashboard KPIs).
  - `.text-dim`: Supporting small text.
- **Responsiveness**: 
  - Max-width: 480px (Mobile Container focus).
  - `--mobile-header-height`: 56px.
  - `--mobile-nav-height`: 64px.

---

## 4. Database Schema (PostgreSQL via Supabase)

### `inventory` (The Core Engine)
- `id` (PK): `hero_size`, `standard_size`, `salted_egg`, `packaging_common`, etc.
- `cost_per_egg`: Unit price from supplier (butir).
- `cost_price`: Total HPP per pack (10 eggs + packaging costs).
- `base_price_per_pack`: Retail price.
- `current_stock`: Total units in "Butir".

### `sales` & `sale_items`
- `total_price`, `payment_status` (`'pending'`, `'paid'`, `'piutang'`).
- `payment_method`: (`'tunai'`, `'transfer'`, `'tempo'`).
- `fulfillment_status`: (`'processing'`, `'on_delivery'`, `'completed'`).

### `stock_logs` & `financial_logs`
- **Audit Trail**: Every change in inventory must have a log entry.
- `log_type`: `'in'` (Arrival), `'out'` (Sale), `'adj'` (Correction).

### `profiles` & `team_members`
- User access control.
- `role`: `'admin'` (Full Access) or `'staff'` (POS Restricted).

### `waha_config`
- Stores WhatsApp API keys and engine configuration for `WhatsAppTerminal.vue`.

---

## 5. App Entry & Initialization (`main.ts`)

```typescript
// Initializing Auth before mounting to prevent flicker
const authStore = useAuthStore()
authStore.initialize().then(() => {
    app.mount('#app')
})
```
- **Directives**: `v-titlecase` (Indonesian-aware capitalization).
- **Error Handling**: Global `errorHandler` captures and silent-logs component crashes.

---

## 6. Routing Architecture (`router/index.ts`)

| Route | Component | Guard | Description |
|-------|-----------|-------|-------------|
| `/` | `Dashboard.vue` | Auth | Main operational metrics |
| `/stock` | `Stock.vue` | Auth | Inventory & HPP Management |
| `/sales/new` | `NewOrder.vue` | Auth | POS / Cashier Interface |
| `/orders` | `Orders.vue` | Auth | Order history & Fulfillment |
| `/suppliers` | `Suppliers.vue` | Admin | Vendor Database |
| `/employees` | `Employees.vue` | Admin | HR & Role Management |
| `/financial` | `FinancialTerminal.vue` | Admin | P&L and Cash Flow Audit |
| `/whatsapp` | `WhatsAppTerminal.vue` | Admin | WhatsApp Communication Core |
| `/activity-log`| `ActivityLog.vue` | Admin | Full Audit Trail |

---

## 7. Layout System (`MainLayout.vue`)

Responsif Berbasis Breakpoint:
- **Desktop (>769px)**: Sidebar kiri permanen (Glassmorphism Sidebar).
- **Mobile (<768px)**: Bottom Navigation + Floating Action Buttons.
- **Data Freshness**: Menggunakan `:key="$route.fullPath"` di RouterView agar data reaktif saat navigasi.

---

## 8. Navigation Components

### `GlassSidebar` (Desktop)
- Logo Hero Farm (Gold) di posisi atas.
- Menu dipisah sesuai kategori Operasional, Revenue, dan Management.

### `BottomNav` (Mobile)
- 4 Tab utama: Dashboard, Inventory, Sales, Profile.
- Visual: Indikator aktif berwarna emas (Gold).

---

## 9. User Roles & Permissions Logic

State dikelola di `auth.ts`:
- **`isAdmin`**: Mengembalikan bolean berdasarkan `profiles.role === 'admin'`.
- **Route Guard**: Mengecek `to.meta.requiresAdmin`. Jika user biasa mencoba masuk `/financial`, dialihkan ke Dashboard.

---

## 10. File Structure Tree

```
src/
├── app/
│   ├── App.vue
│   ├── main.ts
│   └── router/                     ← Navigation & Guards
├── assets/
│   ├── mobile.css                  ← Responsive overrides
│   └── style.css                   ← Global design tokens
├── components/
│   ├── ui/                         ← Reusable atomic components
│   │   ├── StatsCard.vue
│   │   └── GlassPanel.vue
│   ├── inventory/                  ← Inventory specific modules
│   └── sales/                      ← POS sub-components
├── composables/                    ← Shared composition logic
├── lib/
│   └── supabase.ts                 ← DB Client & Hooks
├── stores/
│   ├── auth.ts                     ← Supabase Session & Roles
│   └── appStore.ts                 ← Global UI state
├── utils/
│   ├── calculations.ts             ← HPP & Margin formulas
│   ├── formatters.ts               ← Currency, Date, Stock formatters
│   └── generateInvoice.ts          ← jsPDF rendering logic
└── views/                          ← Page components (Dashboard, Stock, etc.)
```

---

## 11. Key Utilities (`utils/formatters.ts`)

| Function | Output Example |
|----------|----------------|
| `formatCurrency(n)` | `Rp 150.000` |
| `formatCompactCurrency(n)` | `Rp 150rb` |
| `toTitleCase(str)` | `Ibu Sari` (Auto-Indonesian) |
| `formatStock(n)` | `5.200` |
| `formatRelativeDate(d)` | `2 jam lalu` |

---

## 12. Pinia Reference Reference

1. **`useAuthStore`**: Mengelola user session, `id_karyawan`, dan hak akses admin.
2. **`useAppStore`**: Mengelola status loading global dan toggle sidebar.
3. **`useNotificationStore`**: Antrian pesan toast error/success.

---

## 13. HPP Propagation Deep Dive

Logika paling krusial untuk menjaga integritas margin keuntungan.
- **Trigger**: Perubahan harga beli di menu "Restock" untuk item pendukung (Tray/Box/Sticker/Card).
- **Proses**:
  1. Hitung `Unit Cost` baru item pendukung.
  2. Map produk telur yang menggunakan item tersebut.
  3. Lakukan **Atomic Update** ke `inventory.cost_price`.
- **Hasil**: HPP per pack telur selalu *up-to-date* meskipun harga plastik/box naik mendadak.

---

## 14. Stock Interaction Logic (Unit-to-Pack)

- **Input**: Telur dibeli dari peternak dalam unit **Butir** (misal 100 butir).
- **Penjualan**: Dilakukan dalam unit **Pack** (isi 10).
- **Deduction Multiplier**:
  - Konfirmasi Penjualan 1 Pack → Stok Telur `-10`.
  - Otomatis mengurangi Stok Kemasan `-1`, Sticker `-1`, Card `-1`.

---

## 15. POS Intelligence & Invoicing

- **Price Override**: User dapat mengubah harga jual secara manual di keranjang untuk diskon volume.
- **Auto-CRM**: Sistem melakukan `upsert` ke tabel `customers` tanpa reload halaman saat transaksi dikonfirmasi.
- **Invoice Format**: `EP-[YYYYMMDD]-001`. Menggunakan basis waktu server untuk integritas urutan transaksi.

---

## 16. useAuth & Profile System

```typescript
// auth.ts logic sample
export const useAuthStore = defineStore('auth', () => {
    const user = ref(null)
    const isAdmin = computed(() => profile.role === 'admin')
})
```
- Profil user disinkronkan antara `auth.users` dan tabel `profiles` publik untuk efisiensi kueri.

---

## 17. Custom UI Components (Premium Kit)

1. **`StatsCard.vue`**: Menampilkan metrik dengan tren warna (Hijau/Merah).
2. **`GlassPanel.vue`**: Wrapper container dengan efek blur transparan standar.
3. **`EmptyState.vue`**: Ilustrasi estetik saat data kosong.
4. **`GlobalToast.vue`**: Notifikasi melayang dengan gaya cinematic.

---

## 18. CSS Animations & Motion

- **`pulse-dot`**: Digunakan di Dashboard untuk stok kritis (≤ 20 butir).
- **`shimmer`**: Efek loading pada SkeletonLoader.
- **`popIn`**: Entry animation untuk modal transaksi.

---

## 19. Internal Documentation Index

- **`DOCUMENTATION_FULL.md`**: Versi naratif operasional bisnis.
- **`vps-deploy/README.md`**: Panduan teknis infrastruktur Docker.
- **`migrations/`**: Daftar perubahan skema database per tanggal.

---

## 20. Known Rules & Gotchas for Developers

1. **Data Freshness**: Gunakan `router.key` jika data di view tidak refresh saat berpindah menu.
2. **Atomic Logic**: DILARANG mengubah `cost_per_egg` secara manual tanpa melalui sistem Restock (agar audit logs tetap valid).
3. **Floating Point**: Selalu gunakan `Math.round()` atau `decimal.js` untuk hitungan Rupiah agar tidak ada selisih 1 perak.
4. **API Key Security**: Cek `.gitignore` sebelum push. Pastikan `.env` tidak pernah terunggah.

---

## 21. Implemented Modules Status

| Module | Status | Notes |
|--------|--------|-------|
| Dashboard | ✅ | Real-time monitoring |
| Inventory / HPP | ✅ | Propagasi harga otomatis |
| POS / New Order | ✅ | Multi-item & Auto-CRM |
| Financial Terminal | ✅ | Laba/Rugi & Penjualan |
| WhatsApp Bridge | ✅ | QR Login & Bot logic |
| HR & Employees | ✅ | Role management |
| CRM Database | ✅ | Customer LTV Tracking |
| Tactical Drivers | ✅ | Logistik & Pengantaran |

---
*Developed with Passion & Precision by **Antigravity AI***
