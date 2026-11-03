# BELANJAKU — Aplikasi Pencatatan Keuangan Pribadi & Scan Struk

> **"Belanja, foto struk, beres — semua tercatat rapi per kategori tanpa ketik ulang."**

BELANJAKU adalah aplikasi pencatatan keuangan pribadi dan pemindaian nota otomatis berbasis **Flutter (Local-First)** yang dirancang untuk kecepatan input, privasi penuh, dan penggunaan offline tanpa ketergantungan server atau cloud di MVP.

---

## 🚀 Fitur Unggulan Sesuai PRD v1.0

### 1. Input Transaksi Super Cepat (< 10 Detik)
- **Custom Numpad:** Tombol angka besar, haptic feedback, dan tombol cepat `00`.
- **Grid Kategori Berwarna:** Menampilkan kategori pengeluaran dan pemasukan dengan ikon outline Lucide dan warna pastel modern.
- **Dompet Pembayaran:** Dukungan multi-dompet (Tunai, Bank, E-Wallet) dan saldo yang dihitung secara real-time via query agregasi SQL.
- **Urungkan (Undo):** Snackbar konfirmasi dengan tombol urungkan selama 4 detik.

### 2. Scan Nota & Struk Otomatis (Fitur Pembeda)
- **Kamera dengan Bingkai Panduan:** Kotak panduan vertikal untuk memposisikan struk dengan tepat.
- **On-Device OCR:** Menggunakan Google ML Kit Text Recognition on-device (offline, tanpa mengirim foto ke internet).
- **Preprocessing Citra:** Grayscale, penyesuaian kontras untuk struk thermal lama/pudar, dan optimasi kompresi.
- **Parser Cerdas Struk Indonesia:**
  - Mendeteksi nama toko/merchant (Indomaret, Alfamart, SPBU, Rumah Makan, Apotek, dsb).
  - Mengurai pola item `Qty x Harga = Subtotal` maupun item multi-baris.
  - Mendeteksi diskon, potongan voucher, dan pajak restoran (PB1 10% / PPN).
  - Peringatan banner kuning jika ada selisih antara hitungan item vs total tercetak pada struk.
- **Koreksi & Pembelajaran Mandiri (User Learning):** Koreksi kategori yang dilakukan pengguna otomatis disimpan secara lokal sehingga pemindaian berikutnya semakin akurat.
- **Layar Review Interaktif:** Foto struk dapat dicek langsung, nama item/harga/kategori dapat disesuaikan, dan struk dapat disimpan per-item atau 1 transaksi gabungan.

### 3. Anggaran Bulanan & Peringatan Otomatis
- Batas anggaran bulanan per kategori.
- Progress bar visual dengan 3 tingkatan status:
  - **Aman** (< 80%)
  - **Waspada** (80% – 99%, indikator amber & lonceng notifikasi)
  - **Habis** (≥ 100%, indikator merah)
- Fitur salin anggaran dari bulan sebelumnya dengan 1 ketukan.

### 4. Laporan Visual & Tren Keuangan
- **Grafik Donut Interaktif:** 5 kategori pengeluaran terbesar + gabungan "Lainnya".
- **Grafik Batang Tren Harian:** Memantau tren pengeluaran harian selama 7 hari.
- **Perbandingan Antar-Bulan:** Analisis kenaikan/penurunan nominal dan persentase bulan ini vs bulan lalu.

### 5. Transfer Antar-Dompet
- Memindahkan saldo antar-dompet (misal: Bank ke E-Wallet) tanpa menggembungkan laporan pemasukan atau pengeluaran.

### 6. Keamanan & Backup Data
- **Keamanan PIN & Biometrik:** Hash PIN dengan salt menggunakan algoritma SHA-256 dan Secure Storage.
- **Export CSV:** Format standar yang kompatibel dengan Excel dan Google Sheets (`Tanggal`, `Jenis`, `Kategori`, `Dompet`, `Nominal`, `Catatan`, `Toko`).
- **Backup & Restore ZIP:** Mencadangkan seluruh basis data lokal beserta file foto struk ke dalam 1 file ZIP yang dapat dipulihkan kapan saja.

---

## 🛠️ Arsitektur & Struktur Folder

```
lib/
├── core/
│   ├── constants/       # AppConstants, DefaultCategories, DefaultWallets
│   ├── database/        # AppDatabase (SQLite dengan indeks & agregasi)
│   ├── router/          # AppRouter (go_router)
│   ├── theme/           # AppTheme, AppColors (Material 3 Expressive, Light/Dark)
│   └── utils/           # CurrencyFormatter, DateFormatter, IconHelper
├── features/
│   ├── budgets/         # Anggaran bulanan, model, repository, providers, UI
│   ├── categories/      # Kategori bawaan & custom, repository, providers
│   ├── home/            # Home dashboard, saldo total, aksi cepat, bottom nav
│   ├── reports/         # Donut chart, grafik batang tren, analisis perbandingan
│   ├── scan/            # Kamera, OCR Service, Image Preprocessor, Receipt Parser, Review UI
│   ├── security/        # Layanan keamanan PIN & autentikasi biometrik
│   ├── settings/        # Pengaturan profil, dompet, export CSV, backup/restore ZIP
│   ├── transactions/    # Tambah transaksi, custom numpad, daftar riwayat & filter
│   └── wallets/         # Manajemen dompet & transfer antar-dompet
└── main.dart            # Entry point aplikasi BELANJAKU
```

---

## 🧪 Pengujian Otomatis (Unit & Widget Tests)

Aplikasi dilengkapi unit test komprehensif untuk memastikan konsistensi saldo, akurasi parsing nota, dan kecepatan performa:
- **Pengujian Format:** Verifikasi format Rupiah (`Rp 1.250.000`, `−Rp 50.000`) dan penanggalan lokal.
- **Pengujian Saldo & 1.000 Transaksi:** Memastikan saldo dompet tidak drift setelah 1.000 transaksi acak dan transfer tidak merusak ringkasan laporan.
- **Pengujian Parsing Nota (Lampiran A PRD):** Menguji struk Indomaret (diskon), SPBU Pertamina, Rumah Makan Padang (PB1 tax), dan override koreksi kategori pengguna.

Jalankan pengujian dengan perintah:
```bash
flutter test
```

Untuk memeriksa kualitas kode:
```bash
flutter analyze
```

---

## 📦 Menjalankan & Membangun Aplikasi

### Menjalankan di Perangkat Android / Emulator
```bash
flutter run
```

### Membangun APK Release
```bash
flutter build apk --release
```
File APK siap instal akan tersedia di:
`build/app/outputs/flutter-apk/app-release.apk`
