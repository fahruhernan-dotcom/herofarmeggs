# 🥚 Hero Farm Terminal: Definitive Technical Documentation

## 1. Arsitektur & Teknologi (Full Stack)
Sistem ini dibangun sebagai "Operational Terminal" dengan fokus pada kecepatan, desain premium, dan integritas data stok.
- **Frontend Framework**: Vue 3 (Composition API)
- **State Management**: Pinia (untuk autentikasi)
- **Database & Auth**: Supabase (PostgreSQL)
- **Styling Strategy**: "Elite Glassmorphism" - Desain gelap berbasis glass-panel dengan border-glow transparan.
- **Micro-Animations**: Menggunakan Lucide Icons dan CSS Keyframes (Pulse, Slide, Pop) untuk memberikan feedback taktil.

---

## 2. Struktur Database (Schema Details)
Sistem menggunakan PostgreSQL di Supabase dengan relasi sebagai berikut:

- **`inventory`**: Master data stok.
  - `id`: (hero_size, standard_size, salted_egg, packaging_standard, dll).
  - `cost_per_egg`: Harga beli satuan butir telur.
  - `cost_price`: Total HPP per-pack (10 butir + packaging).
  - `base_price_per_pack`: Harga jual eceran.
- **`sales`**: Data transaksi utama.
  - `total_price`, `payment_status` (pending/paid), `fulfillment_status` (processing/on_delivery/completed).
- **`sale_items`**: Detail item dalam satu invoice.
- **`stock_logs`**: Audit trail untuk masuk/keluar stok, termasuk `unit_price` saat kulakan.
- **`customers`**: Data CRM, menyimpan `total_spent` dan `total_orders`.
- **`suppliers`**: Database vendor dengan kolom `price_list` (JSONB) untuk menyimpan katalog produk.

---

## 3. Logika Bisnis & Fitur Per-Menu (Deep Dive)

### 📊 Dashboard (Operational Insight)
- **Monitoring Real-time**: Refresh otomatis setiap 10 detik.
- **Logic Status Stok**:
  - `Healthy`: Stok > 25 butir.
  - `Low`: Stok 21-25 butir.
  - `Critical`: Stok ≤ 20 butir (memicu animasi pulsing merah).
- **Chart Penjualan**: Bar chart dinamis 7 hari terakhir yang menghitung volume order secara otomatis.
- **Danger Zone**: Fitur Reset System yang hanya dapat diakses Admin, menghapus seluruh transaksi namun menjaga struktur master data.

### 📦 Inventory & Logistics Logic (HPP Mastery)
Ini adalah otak dari sistem keuangan Hero Farm.
- **HPP Per-Pack Formula**:
  `Total HPP = (Cost Per Egg * 10) + Cost Packaging + Cost Sticker + Cost Card`
- **Logic "Propagation"**: Saat harga beli Kemasan (Packaging) diupdate melalui modal Restock, sistem secara otomatis:
  1. Menghitung biaya satuan baru kemasan.
  2. Melakukan *Atomic Update* ke seluruh produk telur yang menggunakan kemasan tersebut.
  3. Menghitung ulang `cost_price` (HPP) global untuk setiap produk telur.
- **Restock Calculator**: Fitur untuk menghitung "Effective HPP" yang membagi Total (Harga + Ongkir) dengan jumlah barang yang tidak rusak (Total - Damaged).

### 💰 Revenue Terminal (POS & Invoicing)
- **Multi-Item Cart**: Mendukung pembelian beberapa jenis telur dalam satu invoice.
- **Price Override**: Clerk bisa mengubah harga jual langsung di dalam keranjang belanja untuk promo/diskon manual.
- **Stock Depletion Logic**:
  Saat transaksi dikonfirmasi (Confirm & Print):
  1. **Egg Stock**: `-10 butir` per pack.
  2. **Supply Stock**: `-1` Box, `-1` Sticker, `-1` Card secara otomatis per pack telur yang dijual.
- **Auto-CRM**: Jika nama pembeli belum terdaftar, sistem akan otomatis melakukan `INSERT` ke tabel `customers` tanpa mengganggu alur transaksi.
- **Invoice Engine**: Menghasilkan invoice digital dengan ID unik format `EP-YYYYMMDDXXX` yang dioptimalkan untuk PDF/Print.

### 🚛 Supply Chain (Vendor Management)
- **Catalog-Input Sync**: Setiap supplier memiliki katalog harga. Saat user mengisi "Stock Arrival" di menu Stock, sistem memberikan saran harga berdasarkan katalog supplier yang dipilih untuk meminimalkan *typo* input keuangan.
- **Category Accents**: Desain kartu supplier berubah warna (Gold/Blue/Purple) berdasarkan tipe suplai mereka.

### 👥 Customer & CRM Tracking
- **LTV Calculation**: Setiap transaksi "Paid" akan mengupdate kolom `total_spent` di tabel customer untuk melihat loyalitas pelanggan.
- **Rankings**: Muncul di Dashboard untuk memotivasi tim sales memprioritaskan "Top Customers".

---

## 4. Keamanan & Role-Based Access
- **Admin**: Akses penuh ke HPP, Edit Harga Master, Reset System, dan Manajemen Karyawan.
- **Cashier/Staff**: Hanya dapat menginput penjualan dan melihat stok tanpa bisa mengubah parameter HPP (Harga Beli).

---

## 5. Sinkronisasi Github & Deployment
Setiap perubahan substansial harus dipush ke Github.
- **Key Success Fix**: Penambahan `:key="$route.fullPath"` di `App.vue` menjamin tidak ada data basi (cache) saat navigasi antar menu, menyelesaikan isu "Hard Refresh" yang sebelumnya dikeluhkan.

*Dokumentasi ini dibuat untuk memastikan kelangsungan operasional Hero Farm yang presisi dan profesional.*
