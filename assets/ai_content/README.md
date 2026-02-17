# 🤖 AI Content Management System

Folder ini dirancang untuk merapikan alur kerja (workflow) pembuatan konten menggunakan AI untuk **Hero Farm**.

## 📂 Struktur Workflow

1.  **`01_mentahan/`**: 
    - Taruh semua hasil generate AI di sini (gambar, teks, atau draft).
    - Jangan diedit di dalam folder ini. Ini adalah "dumping ground" hasil asli.
2.  **`02_seleksi/`**: 
    - Pindahkan hanya gambar/konten terbaik dari folder `01_mentahan` ke sini.
    - Gunakan folder ini untuk menyeleksi mana yang akan diproses lebih lanjut.
3.  **`03_siap_upload/`**: 
    - Tempat aset yang sudah ditambahkan watermark, teks, atau sudah melalui proses editing akhir.
    - Folder ini adalah sumber utama untuk posting ke IG/TikTok/WA.

## 🛠️ Cara Seleksi & Merapikan
- Jika ada banyak kategori, buat sub-folder di dalam `02_seleksi/` dengan nama:
  - `/product/` (Foto telur/mika)
  - `/lifestyle/` (Contoh masakan/suasana farm)
  - `/edu/` (Infografis/edukasi)

## 🏷️ Pola Penamaan (Rekomendasi)
Agar pencarian lebih mudah, gunakan format:
`HF_[KATEGORI]_[TGL]_[NO].jpg`

- **HF**: Hero Farm (Kode Project)
- **KATEGORI**: 
  - `PROD` (Produk)
  - `EDU` (Edukasi)
  - `LIFE` (Lifestyle/BTS)
- **TGL**: format `DDMMYY`
- **NO**: 001, 002, dst.

*Contoh: `HF_PROD_170226_01.jpg`*

---
*Gunakan sistem ini agar aset AI Anda tidak berantakan dan mudah ditemukan saat ingin posting.*
