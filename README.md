# 🥚 Hero Farm Terminal v2.0
> **Premium Duck Egg Business Management System**

Hero Farm Terminal adalah ekosistem manajemen bisnis yang dirancang khusus untuk operasional **Hero Farm Fresh Eggs**. Aplikasi ini mengintegrasikan seluruh lini bisnis mulai dari manajemen inventaris, terminal keuangan, hingga analitik penjualan secara real-time.

---

## 🛠️ Technology Stack
Aplikasi ini dibangun dengan teknologi modern untuk memberikan performa tinggi dan user experience yang premium:

- **Frontend**: [Vue 3](https://vuejs.org/) (Composition API) + [Vite](https://vitejs.dev/)
- **Backend-as-a-Service**: [Supabase](https://supabase.com/) (PostgreSQL + Auth + Storage)
- **Visuals & Animations**: [GSAP](https://greensock.com/gsap/), [Three.js](https://threejs.org/), & [OGL](https://github.com/oframe/ogl)
- **State Management**: [Pinia](https://pinia.vuejs.org/)
- **Charts & Analytics**: [Chart.js](https://www.chartjs.org/)
- **Icons**: [Lucide Vue Next](https://lucide.dev/)
- **Styling**: Vanilla CSS with Modern Flex/Grid & Glassmorphism Design

---

## ✨ Fitur Utama
Sistem ini terdiri dari modul-modul modular yang saling terintegrasi:

1.  📊 **Intelligent Dashboard**: Visualisasi data real-time untuk performa bisnis, tren stok, dan revenue harian.
2.  📟 **Financial Terminal**: Modul pembukuan canggih yang mencatat kas masuk/keluar, biaya operasional, dan perhitungan profit otomatis.
3.  📦 **Inventory & Stock Take**: Manajemen stok telur segar dengan fitur *Stock Take* untuk verifikasi fisik vs sistem secara berkala.
4.  💰 **Sales Management**: Pencatatan transaksi penjualan secara instan dengan integrasi data pelanggan.
5.  🤝 **Customer & Supplier CRM**: Database lengkap pembeli loyal dan penyuplai pakan/kebutuhan farm.
6.  📋 **Order Management**: Pelacakan status pesanan dari masuk hingga terkirim.
7.  👥 **Employee Directory**: Pengelolaan data karyawan dan akses operasional.

---

## 📂 Struktur Repositori
Repositori ini difokuskan pada pengembangan aplikasi web, sementara aset bisnis sensitif dikelola secara lokal.

- **`web-app/`**: Source code utama aplikasi (Vue.js).
- **`web-app/src/assets/`**: Aset UI seperti logo dan gaya visual.
- **`docker-compose.yml`**: Konfigurasi deployment untuk VPS.
- **`docs/` & `assets/` (Local Only)**: Dokumentasi strategi bisnis, legalitas, dan konten pemasaran. *(Diabaikan dari Git untuk keamanan)*.

---

## 🚀 Panduan Deployment (Docker)
Aplikasi ini dioptimalkan untuk berjalan di atas Container Docker.

### 1. Persiapan Lingkungan
Salin file `.env` ke folder `web-app/` dan masukkan kredensial Supabase Anda.

### 2. Jalankan dengan Docker Compose
Gunakan perintah berikut di root folder:
```bash
docker compose up -d --build
```
Aplikasi akan tersedia di port `8081` (atau port yang dikonfigurasi pada `docker-compose.yml`).

---

## 👨‍💻 Pengembangan Lokal
Untuk menjalankan project di lingkungan pengembangan:

```bash
cd web-app
npm install
npm run dev
```

---
*Developed with Passion for Hero Farm by **Antigravity AI***
