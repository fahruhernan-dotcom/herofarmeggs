# 🥚 Hero Farm Terminal — Developer Context

> Last updated: 2026-03-18 | Use this as reference for all future technical implementations.

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

### Core UI Strategy
Aplikasi menggunakan tema **Ultra-Dark** dengan fokus pada **Glassmorphism Panels**. Layer utama menggunakan `background-blur: 20px` dengan border glow tipis (0.5px atau 1px) untuk memisahkan antar elemen tanpa bising visual.

### Color Palette & Accents
| Token | HEX / RGB | Usage |
|-------|----------|-------|
| `bgBase` | `#06080a` | Deep black-blue background |
| `glassMain` | `rgba(15, 23, 42, 0.75)` | Standard glass panel |
| `goldEgg` | `#facc15` | Hero Egg accent, primary labels |
| `bluePack` | `#3b82f6` | Packaging & logistics accent |
| `redCrit` | `#ef4444` | Critical stock alerts (with Pulsing) |
| `greenLive` | `#10b981` | Positive status, success notifications |
| `text1` | `#f8fafc` | Primary text |
| `text2` | `#94a3b8` | Muted/Secondary labels |

### CSS Variables (`mobile.css` context)
- `--mobile-header-height`: 56px
- `--mobile-nav-height`: 64px
- `--safe-area-bottom`: `env(safe-area-inset-bottom)`

### Custom Animations
- **`pulse-dot`**: Red glowing animation for critical stock.
- **`slideUp`**: Smooth entry for mobile drawers/modals.
- **`hero-glow`**: Subtle floating light effect on main cards.

---

## 3. Database Schema (PostgreSQL via Supabase)

### `inventory` (Master Data)
- `id`: (hero_size, standard_size, salted_egg, packaging_standard, etc).
- `cost_per_egg`: Unit price bought from farm.
- `cost_price`: Total HPP (10 eggs + packaging costs).
- `base_price_per_pack`: Default retail price.
- `current_stock`: Atomic unit (Butir).

### `sales` & `sale_items`
- `total_price`, `payment_status` (`'pending'` | `'paid'` | `'piutang'`).
- `fulfillment_status` (`'processing'` | `'on_delivery'` | `'completed'`).
- `payment_method`: (`'tunai'`, `'transfer'`, `'tempo'`).

### `customers` (CRM)
- `name`, `phone`, `total_spent`, `total_orders`.
- **Auto-Register**: Inserted automatically during checkout if not exists.

### `suppliers`
- `name`, `supply_type`, `price_list` (JSONB catalog sync).

### `profiles` & `team_members`
- Linked via `auth_user_id`.
- `role`: (`'admin'`, `'cashier'`, `'staff'`).
- **Admin Guard**: Only admins see Financial Terminal & Employees.

---

## 4. Key Logic & Features

### 📦 HPP Propagation Logic
Sistem paling kritikal di Hero Farm. Saat harga beli **Kemasan** berubah:
1. Sistem menghitung biaya satuan kemasan yang baru.
2. Melakukan *Atomic Update* ke tabel `inventory`.
3. Seluruh produk Telur yang menggunakan kemasan tersebut (misal Telur Hero & Standard) otomatis terupdate `cost_price`-nya.

### 💰 Stock Depletion (Unit vs Pack)
- Penjualan dilakukan per **Pack** (Isi 10).
- Eksekusi transaksi otomatis mengurangi:
    - **10 Butir Telur** dari stok varian telur terkait.
    - **1 Box/Tray**, **1 Sticker**, dan **1 Card** dari stok packaging.

### 🚛 WAHA Terminal Integration
- Integrasi WhatsApp engine via engine **WAHA** di VPS.
- Mendukung sinkronisasi Chat, QR Login, dan Auto-Reply untuk notifikasi order pelanggan.

---

## 5. Routing Architecture (`router/index.ts`)

| Route | Component | Guard |
|-------|-----------|-------|
| `/` | `Dashboard.vue` | `requiresAuth` |
| `/stock` | `Stock.vue` | `requiresAuth` |
| `/sales/new` | `NewOrder.vue` | `requiresAuth` |
| `/orders` | `Orders.vue` | `requiresAuth` |
| `/suppliers` | `Suppliers.vue` | `requiresAdmin` |
| `/employees` | `Employees.vue` | `requiresAdmin` |
| `/financial` | `FinancialTerminal.vue` | `requiresAdmin` |
| `/whatsapp` | `WhatsAppTerminal.vue` | `requiresAdmin` |
| `/profile` | `Profile.vue` | `requiresAuth` |

---

## 6. Known Rules & Gotchas (Developer Checklist)

1. **`requiresAuth` vs `requiresAdmin`**: Selalu cek `meta` di router. Menu finansial dan pengaturan karyawan WAJIB admin.
2. **React-like Reactivity**: Di Vue ini, gunakan `:key="$route.fullPath"` di `App.vue` untuk menjamin komponen refresh total saat pindah menu.
3. **Price Conversion**: Selalu gunakan `safeNum` helper saat manipulasi harga agar tidak muncul `NaN` di UI.
4. **Environment Variables**: Gunakan `import.meta.env.VITE_SUPABASE_URL`/`ANON_KEY`. Jangan pernah hardcode API keys.
5. **HPP Integrity**: Jangan mengubah stok telur tanpa merekamnya di `stock_logs`, karena logs ini adalah sumber audit satu-satunya.

---
*Created with precision for Hero Farm Fresh Eggs by **Antigravity AI***
