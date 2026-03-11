# 🥚 Hero Farm Terminal v2.5
> **Advanced Business Ecosystem & Tactical Communication Portal**

Hero Farm Terminal adalah ekosistem manajemen bisnis premium yang dirancang khusus untuk operasional **Hero Farm Fresh Eggs**. Aplikasi ini mengintegrasikan seluruh lini bisnis mulai dari manajemen inventaris, terminal keuangan, hingga sistem komunikasi langsung dengan pelanggan.

---

## 🛠️ Technology Stack
Aplikasi ini dibangun dengan arsitektur modern untuk skalabilitas dan keamanan tinggi:

- **Frontend**: [Vue 3](https://vuejs.org/) (Composition API / TypeScript) + [Vite](https://vitejs.dev/)
- **Backend**: [Supabase](https://supabase.com/) (PostgreSQL RPC, Realtime Subscriptions, Edge Functions)
- **WhatsApp Engine**: [WAHA](https://waha.devlike.pro/) (WhatsApp HTTP API Core)
- **Infrastructure**: Docker & Docker Compose on Linux VPS
- **Visuals**: Modern Glassmorphism UI, [Lucide Icons](https://lucide.dev/), & CSS Motion Graphics
- **State Management**: [Pinia](https://pinia.vuejs.org/)

---

## ✨ Fitur Unggulan

### 1. 🛡️ WhatsApp Tactical Terminal
Sistem komunikasi real-time yang terintegrasi langsung ke engine WAHA di VPS.
- **Direct API Link**: Komunikasi langsung tanpa perantara untuk kecepatan maksimal.
- **QR Scan Auth**: Sistem otentikasi perangkat tertaut langsung dari dashboard.
- **Auto-Sync Chats**: Sinkronisasi otomatis daftar chat dan pesan terakhir.
- **CORS Secure**: Dilengkapi dengan konfigurasi keamanan Cross-Origin terenkripsi.

### 2. 💹 Advanced Financial Terminal
Modul pembukuan strategis dengan kalkulasi profit otomatis.
- **Real-time P&L**: Perhitungan Laba Rugi otomatis via PostgreSQL RPC.
- **Expense Tracking**: Pencatatan biaya operasional dan modal secara mendetail.
- **Cash Flow Analysis**: Visualisasi kas masuk/keluar harian.

### 3. 📦 Smart Inventory System
Manajemen stok telur bebek segar dengan akurasi tinggi.
- **Direct Purchase Flow**: Input pembelian stok yang langsung memicu pembaruan kas.
- **Stock Take Monitoring**: Verifikasi fisik telur rutin untuk mencegah deviasi data.
- **Automated Reorder Alerts**: Notifikasi saat stok kritis.

### 4. 📋 Order & Sales CRM
- **Instant Order Entry**: Pencatatan pesanan kilat dengan database pelanggan otomatis.
- **Performance Analytics**: Audit performa penjualan per produk dan per periode.

---

## 🚀 Panduan Deployment (VPS)

### 1. Struktur Folder Deployment
- **`vps-deploy/`**: Berisi `docker-compose.yml` dan `Dockerfile` untuk production.
- **`update.sh`**: Script otomatisasi untuk menarik kode terbaru, build, dan restart container.

### 2. Konfigurasi WAHA (CORS)
Untuk pengoperasian WhatsApp Terminal dari localhost/domain berbeda, pastikan environment WAHA di VPS memiliki:
```env
WHATSAPP_CORS_ORIGIN=*
WHATSAPP_CORS_METHODS=GET,POST,PUT,DELETE,OPTIONS
WHATSAPP_CORS_CREDENTIALS=true
```

### 3. Update Otomatis
Jalankan perintah berikut di folder root VPS Anda:
```bash
./update.sh
```

---

## 📂 Struktur Repositori
- **`web-app/`**: Source code utama Vue 3.
- **`web-app/migrations/`**: Kumpulan SQL migrations untuk skema Supabase.
- **`vps-deploy/`**: Konfigurasi orchestration Docker.

---

## 👨‍💻 Pengembangan Lokal
```bash
cd web-app
npm install
npm run dev
```

---
*Developed with Passion for Hero Farm by **Antigravity AI***
