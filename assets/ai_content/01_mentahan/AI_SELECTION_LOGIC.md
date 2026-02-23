# 🤖 AI Content Selection Logic (Auto-Picker)

File ini adalah instruksi khusus untuk AI (seperti Antigravity) agar bisa melakukan seleksi otomatis terhadap gambar di folder `01_mentahan`.

---

## 🧐 KRITERIA SELEKSI (QC Checklist)

AI harus memilih gambar yang memenuhi kriteria berikut:

### 1. Kualitas Visual (Premium Look)
- **Lighting**: Harus terlihat profesional (well-lit), tidak boleh terlalu gelap atau washed-out.
- **Warna**: Kuning telur harus oranye pekat (Hero Farm Standard).
- **Komposisi**: Subjek utama (telur/produk) harus jelas dan fokus.

### 2. Konteks Bisnis (Relevance)
- **Produk**: Menonjolkan kualitas telur bebek (cangkang biru bersih) atau kuning telur.
- **Edu**: Informatif dan memiliki teks yang mudah dibaca.
- **Life**: Membangun suasana premium farm atau dapur modern.

### 3. Red Flags (Auto-Reject Jika Ada Ini):
- ❌ Teks yang pecah/typo parah (khusus gambar buatan AI).
- ❌ Jumlah jari tangan yang aneh (jika ada orang).
- ❌ Bentuk telur yang tidak wajar (penyok/gepeng).
- ❌ Foto yang terlihat "murah" atau berantakan.

---

## 🚀 PROSEDUR SELEKSI (Step-by-Step)

Jika diperintahkan "Seleksi Folder Mentahan", AI akan melakukan:

1.  **Scanning**: AI akan melihat seluruh file di folder `01_mentahan`.
2.  **Naming & Filtering**: 
    - AI akan me-rename file terpilih menggunakan format: `HF_[KATEGORI]_[Deskripsi_Singkat].ext`.
3.  **Moving**:
    - AI akan memindahkan file terpilih ke folder pemrosesan selanjutnya (`02_seleksi/`).
    - AI akan memasukkannya ke sub-folder yang sesuai (`01_produk`, `02_edukasi`, `03_lifestyle`, atau `04_branding`).
4.  **Reporting**: AI akan memberikan list singkat alasan kenapa gambar tersebut dipilih.

---

## ⚡ INSTRUKSI PEMANGGILAN
"AI, jalankan **AI_SELECTION_LOGIC** pada folder mentahan sekarang."
