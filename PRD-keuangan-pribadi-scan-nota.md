# PRD — Aplikasi Pencatatan Pemasukan & Pengeluaran + Scan Nota

**Nama kerja:** CatatUang (nama final bisa diganti, jangan hardcode brand di logika inti)
**Versi PRD:** v1.0 — 3 November 2026
**Dibuat untuk:** bengkel, dikerjakan Gemini (Flutter)
**Platform:** Flutter — Android dulu (prioritas), iOS menyusul dari codebase yang sama
**Bahasa aplikasi:** Indonesia. Mata uang default: Rupiah (IDR). Timezone: Asia/Makassar (WITA).
**Sifat data:** Single user, pemakaian pribadi. Local-first, bisa offline penuh. Cloud/sync BUKAN MVP.

> Cara pakai dokumen ini: kerjakan berurutan dari Fase 0 → Fase 3 di §14. Kalau ada konflik antara PRD ini dan asumsi lain, PRD ini yang menang. Kalau ada keputusan yang belum dibuat user, pakai "Default bila user diam" di §15, jangan berhenti menunggu.

---

## 1. Ringkasan Produk

### 1.1 Masalah
Mencatat keuangan manual itu malas dilakukan karena: (1) harus ketik satu-satu, (2) struk belanja menumpuk tapi tidak pernah diinput, (3) ujung bulan tidak tahu uang lari ke mana, (4) aplikasi yang ada terlalu ribet, berat, atau memaksa login/cloud.

### 1.2 Solusi
Aplikasi pencatatan keuangan pribadi yang:
1. Input manual super cepat (di bawah 10 detik per transaksi).
2. **Scan nota/struk → item otomatis terinput dan terkategori masing-masing** — user tinggal cek, koreksi kalau salah, lalu simpan.
3. Langsung kelihatan: saldo per dompet, pengeluaran per kategori, anggaran bulanan, dan tren.
4. Ringan, offline, tanpa akun wajib, dengan tampilan kekinian yang enak dibuka tiap hari.

### 1.3 Janji produk (satu kalimat)
> "Belanja, foto struk, beres — semua tercatat rapi per kategori tanpa ketik ulang."

### 1.4 Bukan produk ini (out of scope permanen untuk v1)
- Bukan aplikasi kasir / POS, bukan akuntansi perusahaan (tidak ada jurnal double-entry, neraca, PPh).
- Bukan dompet digital / payment — tidak ada transfer uang, top-up, atau koneksi rekening bank otomatis di v1.
- Bukan multi-user / keluarga sharing di v1. Satu HP = satu pengguna.
- Bukan upload struk otomatis ke TikTok / sosmed / pihak ketiga.

---

## 2. Tujuan & Tolok Ukur Sukses

| Tujuan | Tolok ukur MVP (uji di HP user) |
|---|---|
| Input terasa ringan | Tambah transaksi manual ≤ 10 detik, ≤ 5 ketukan dari Home |
| Scan nota benar-benar menghemat waktu | ≥ 80% item struk Indomaret/Alfamart/warung ter-parse benar (nama + harga); total hasil scan selisih ≤ Rp1.000 dari total struk, atau user bisa koreksi dalam ≤ 30 detik |
| Kategori otomatis bisa dipercaya | ≥ 85% item umum langsung masuk kategori benar tanpa koreksi, setelah 20 struk pertama (karena belajar dari koreksi) |
| Ujung bulan terjawab | User bisa jawab dalam 30 detik: total keluar bulan ini, 3 kategori terbesar, sisa anggaran tiap kategori |
| Aplikasi stabil & ringan | Cold start ≤ 2 detik di HP mid-range, tidak crash saat scan 3 struk berturut-turut, semua data tetap ada setelah restart / update |

---

## 3. Persona & User Story

**Persona utama:** bengkel — pekerja/penjual di Samarinda, belanja harian di warung/minimarket, bayar pakai tunai + e-wallet + bank, ingin tahu ke mana larinya uang tanpa ribet. Pakai HP Android sebagai perangkat utama.

### 3.1 User story MVP (wajib semua)

**Catat & lihat**
- US-01: Sebagai user, saya bisa tambah pemasukan/pengeluaran manual (nominal, kategori, dompet, tanggal, catatan opsional) supaya tercatat walau tanpa struk.
- US-02: Sebagai user, saya bisa edit & hapus transaksi supaya salah input bisa dibetulkan.
- US-03: Sebagai user, saya bisa lihat daftar transaksi (terbaru dulu), cari berdasarkan nama/catatan, dan filter tanggal / kategori / dompet.
- US-04: Sebagai user, saya bisa lihat ringkasan hari ini, minggu ini, bulan ini: total masuk, total keluar, selisih.
- US-05: Sebagai user, saya bisa lihat saldo tiap dompet (Tunai, Bank, E-Wallet) dan total saldo.

**Scan nota (fitur pembeda)**
- US-06: Sebagai user, saya bisa foto struk dari kamera atau ambil dari galeri.
- US-07: Sebagai user, saya bisa lihat hasil scan sebelum disimpan: nama toko, tanggal, tiap item + harga + kategori tebakan, dan total — lalu edit nama, harga, kategori, hapus item, atau tambah item manual.
- US-08: Sebagai user, saya bisa simpan hasil scan jadi banyak transaksi sekaligus (satu transaksi per item, atau satu transaksi gabungan — lihat §7.6) dan foto struk tersimpan sebagai bukti.
- US-09: Sebagai user, saya bisa tahu kalau scan gagal / buram, dan tetap bisa input manual dari foto yang sama tanpa mengulang foto.

**Kategori & anggaran**
- US-10: Sebagai user, saya bisa pakai kategori bawaan (§5) dan tambah / ubah nama / ubah ikon-warna kategori sendiri.
- US-11: Sebagai user, saya bisa set anggaran bulanan per kategori (mis. Makan Rp1.500.000) dan lihat sisa + peringatan saat 80% dan 100% terpakai.
- US-12: Sebagai user, saya bisa lihat grafik pengeluaran per kategori (donat) dan tren harian/mingguan (batang).

**Keamanan & data**
- US-13: Sebagai user, saya bisa kunci aplikasi dengan PIN / sidik jari supaya orang lain yang pegang HP tidak bisa buka.
- US-14: Sebagai user, saya bisa export data ke CSV/Excel dan backup-restore file lokal supaya data tidak hilang saat ganti HP.

### 3.2 User story v1.1 (penting, setelah MVP stabil)
- US-15: Transaksi berulang otomatis (gaji tiap tanggal 25, kos/listrik tiap awal bulan) + pengingat tagihan H-3.
- US-16: Target tabungan (mis. Dana darurat Rp10jt, progress bar otomatis dari selisih masuk-keluar yang ditandai).
- US-17: Utang & piutang: catat siapa, berapa, jatuh tempo, lunas sebagian, pengingat.
- US-18: Widget Home Android: saldo + tombol cepat "Tambah" + ringkasan bulan ini.
- US-19: Insight otomatis singkat: "Makan bulan ini naik 23% vs bulan lalu", "3 pengeluaran terbesar minggu ini".

### 3.3 User story v2 (nice to have, jangan dikerjakan di MVP)
- US-20: Split bill (patungan) — bagi satu struk ke beberapa orang.
- US-21: Import mutasi bank/e-wallet dari file CSV (manual, user pilih file) — BUKAN koneksi bank otomatis.
- US-22: Multi-mata uang (tampil kurs manual, bukan kurs live wajib).
- US-23: Laporan PDF bulanan yang rapi untuk dibagikan / dicetak.
- US-24: Sinkronisasi antar perangkat via backup cloud opsional (Drive) — hanya kalau user minta eksplisit.

---

## 4. Scope & Prioritas

| Fitur | MVP (Fase 1) | v1.1 | v2 |
|---|---|---|---|
| Input manual, edit, hapus, cari, filter | ✅ | | |
| Dompet: Tunai, Bank, E-Wallet (+ tambah dompet) | ✅ | | |
| Kategori bawaan + kategori custom | ✅ | | |
| Scan nota: kamera/galeri, OCR, parsing, review, simpan | ✅ | | |
| Foto struk tersimpan sebagai bukti | ✅ | | |
| Anggaran bulanan per kategori + alert 80%/100% | ✅ | | |
| Laporan: donat kategori, tren batang, rekap bulanan | ✅ | | |
| PIN / biometrik, export CSV, backup lokal | ✅ | | |
| Transaksi berulang, pengingat tagihan, target tabungan, utang-piutang | | ✅ | |
| Widget, insight otomatis | | ✅ | |
| Split bill, import CSV bank, multi-mata uang, laporan PDF, sync cloud | | | ✅ |

**Aturan scope:** fitur v1.1/v2 tidak boleh menghambat MVP. Jangan buat tabel/skema yang "sekadar jaga-jaga" untuk v2 kalau tidak dipakai MVP, kecuali kolom yang memang sudah tercantum di §9.

---

## 5. Kategori — Wajib Sesuai Ini di MVP

### 5.1 Prinsip kategori
- Satu transaksi = satu kategori. Tidak ada multi-kategori di MVP (split satu struk jadi banyak transaksi per item — itu cara mencapai "per item beda kategori").
- Nama kategori singkat, sehari-hari, Indonesia. Hindari istilah akuntansi.
- Setiap kategori punya: kode tetap (tidak berubah walau nama diubah user), nama, ikon (dari set ikon §8.4), warna, jenis (masuk/keluar), dan daftar kata kunci OCR (§7.5).
- User boleh: tambah kategori, ubah nama/ikon/warna, nonaktifkan kategori (transaksi lama tetap pakai kategori itu, tidak hilang). User TIDAK boleh hapus kategori bawaan yang sudah dipakai transaksi — yang boleh hanya nonaktifkan.
- Kategori "Lainnya" wajib ada di pemasukan dan pengeluaran sebagai jaring pengaman — tapi aplikasi harus berusaha menghindarinya: kalau tebakan OCR ragu, tampilkan 3 tebakan teratas, bukan langsung "Lainnya".

### 5.2 Kategori pemasukan

| Kode | Kategori | Subkategori / contoh | Ikon saran |
|---|---|---|---|
| INC_GAJI | Gaji | Gaji pokok, THR, bonus, lembur | banknote / wallet |
| INC_USAHA | Usaha & Jualan | Untung jualan rumah, komisi, jasa, pulsa | store |
| INC_FREELANCE | Freelance & Jasa | Proyek, desain, coding, foto | laptop |
| INC_INVESTASI | Investasi | Dividen, bunga deposito, jual saham/reksadana | trending-up |
| INC_HADIAH | Hadiah & Transfer Masuk | Kiriman keluarga, THR dari orang tua, cashback | gift |
| INC_LAIN | Pemasukan Lainnya | Temuan, refund, penjualan barang bekas | plus-circle |

### 5.3 Kategori pengeluaran (ini inti produk — jangan disingkat)

| Kode | Kategori | Subkategori | Contoh item (untuk kamus OCR) | Ikon saran |
|---|---|---|---|---|
| EXP_MAKAN | Makan & Minum | Makan di luar, jajan, kopi, katering | Nasi padang, ayam geprek, kopi susu, bakso, Indomie, teh botol | utensils / coffee |
| EXP_SEMBAKO | Belanja Harian & Sembako | Bahan dapur, kebutuhan rumah harian | Beras, minyak goreng, gula, telur, mie, susu, sabun cuci, tisu | shopping-basket |
| EXP_TRANSPORT | Transportasi | BBM, ojek/taksi online, parkir, servis motor/mobil | Pertalite, Pertamax, GoRide, Grab, parkir, oli, ban | car / bike |
| EXP_TAGIHAN | Tagihan & Utilitas | Listrik, air, internet, HP, langganan | PLN, PDAM, WiFi, pulsa, paket data, Netflix, Spotify | zap / wifi |
| EXP_RUMAH | Rumah & Tempat Tinggal | Kos/kontrakan, perawatan rumah, perabot | Kos, kontrakan, cat, lampu, galon, gas LPG | home |
| EXP_KESEHATAN | Kesehatan | Obat, dokter, vitamin, BPJS | Paracetamol, vitamin C, dokter gigi, masker, BPJS | heart-pulse |
| EXP_PENDIDIKAN | Pendidikan | Kursus, buku, alat tulis, SPP | Buku, pulpen, kursus online, fotokopi | book-open |
| EXP_PAKAIAN | Pakaian & Penampilan | Baju, sepatu, potong rambut, skincare | Kaos, celana, sepatu, cukur, facial, parfum | shirt |
| EXP_HIBURAN | Hiburan & Rekreasi | Nonton, game, jalan-jalan, hobi | Bioskop, top up game, mancing, futsal, karaoke | gamepad / clapperboard |
| EXP_SOSIAL | Sosial & Donasi | Traktir, hadiah, sedekah, kondangan | Amplop kondangan, sedekah, traktir teman, kado | hand-heart / gift |
| EXP_KEUANGAN | Cicilan & Keuangan | Cicilan, bunga, admin bank, denda | Cicilan motor, KPR, admin bank, denda telat | credit-card |
| EXP_KERJA | Kerja & Bisnis | Modal, ATK usaha, iklan, ongkir jualan | Modal pulsa, banner, ongkir, bensin kerja (bedakan dari pribadi bila perlu) | briefcase |
| EXP_PELIHARAAN | Hewan Peliharaan | Pakan, dokter hewan | Pakan kucing, pasir kucing, vaksin | paw-print |
| EXP_LAIN | Pengeluaran Lainnya | Yang tidak masuk di atas | — | more-horizontal |

**Catatan untuk Gemini:** tampilkan kategori pengeluaran sebagai grid ikon warna-warni di layar Tambah (bukan dropdown teks panjang). Urutan default di grid = urutan tabel di atas, dengan "Makan & Minum" dan "Belanja Harian" paling atas karena paling sering. Simpan urutan ini sebagai data, bukan hardcode posisi di UI.

### 5.4 Dompet bawaan (MVP)
Tunai, Bank (boleh tambah nama bank di catatan dompet: BCA, Mandiri, dll — bukan dompet terpisah per bank di MVP kecuali user menambah sendiri), E-Wallet (DANA, GoPay, OVO, ShopeePay — sama, user bisa tambah dompet per e-wallet kalau mau). Setiap dompet: nama, jenis, saldo awal (default 0), ikon, warna, aktif/nonaktif. Saldo dompet = saldo awal + pemasukan − pengeluaran dompet itu, dihitung dari transaksi (jangan simpan saldo sebagai angka yang diedit manual kecuali lewat "Penyesuaian Saldo" yang tercatat sebagai transaksi khusus).


---

## 6. Fitur Inti — Spesifikasi Detail

### 6.1 Tambah transaksi manual (harus tercepat)
- Jalur: Home → FAB "+" → pilih Masuk/Keluar (toggle atas, default = Keluar karena paling sering) → ketik nominal via numpad custom besar (lihat §8.5) → pilih kategori (grid ikon) → pilih dompet (chip) → tanggal (default hari ini, bisa diubah) → catatan opsional → Simpan.
- Nominal: input angka saja, format otomatis jadi `Rp 1.250.000` saat tampil. Tidak ada desimal sen di MVP. Maksimal nominal: Rp 999.999.999.999 (validasi, bukan crash). Nominal 0 atau kosong = tombol Simpan nonaktif + pesan "Masukkan nominal dulu".
- Tanggal: tidak boleh tanggal masa depan lebih dari hari ini (kalau dipilih, tampilkan peringatan dan kembalikan ke hari ini). Waktu (jam) opsional, default jam saat simpan.
- Setelah simpan: kembali ke Home, tampilkan snackbar "Tersimpan — Makan Rp50.000" + tombol "Urungkan" selama 4 detik.
- Edit: dari daftar transaksi → ketuk item → layar detail → Ubah → semua field bisa diubah, saldo dompet ikut terkoreksi otomatis. Hapus: konfirmasi "Hapus transaksi ini?" (bukan hapus diam-diam), saldo ikut terkoreksi.

### 6.2 Daftar, cari, filter
- Urutan default: tanggal terbaru dulu, lalu jam terbaru.
- Pencarian: cocokkan nama kategori, catatan, nama toko (untuk transaksi dari struk), dan nominal (ketik "50000" menemukan Rp50.000).
- Filter: rentang tanggal (Hari ini / Minggu ini / Bulan ini / Pilih tanggal), jenis (Masuk/Keluar/Semua), kategori (multi-pilih), dompet. Filter yang aktif selalu terlihat sebagai chip di atas daftar + tombol "Hapus filter".
- Grup per hari: header tanggal ("Hari ini", "Kemarin", "Senin, 3 Nov 2026") + subtotal keluar/masuk hari itu.
- Swipe kanan pada item = edit, swipe kiri = hapus (dengan konfirmasi). Jangan hanya andalkan long-press yang tidak ketahuan user.

### 6.3 Dompet
- Tambah dompet: nama, jenis (Tunai/Bank/E-Wallet/Lainnya), saldo awal, ikon, warna.
- Transfer antar dompet (MVP, sederhana): pilih dompet asal → dompet tujuan → nominal → tercatat sebagai 2 transaksi berpasangan (keluar dari asal + masuk ke tujuan) dengan penanda "Transfer" supaya tidak dihitung sebagai pemasukan/pengeluaran di laporan. Ini penting supaya laporan tidak menggembung.
- Dompet nonaktif: tidak muncul di pilihan tambah transaksi, tapi riwayatnya tetap ada.

### 6.4 Anggaran bulanan
- Set per kategori per bulan: nominal anggaran. Boleh 0 = tidak dibatasi.
- Hitung terpakai = total pengeluaran kategori itu di bulan berjalan (transaksi dari struk ikut dihitung per item).
- Tampilan: progress bar per kategori + sisa (Rp dan %). Status: aman (<80%), waspada (80–99%, warna amber + notifikasi sekali saat melewati 80%), habis (≥100%, warna merah + notifikasi sekali).
- Notifikasi lokal saja (tidak perlu server). Jangan spam: satu kategori satu notifikasi per ambang per bulan.
- Anggaran bulan depan: salin otomatis dari bulan lalu sebagai draf yang bisa diubah (jangan kunci user untuk input ulang tiap bulan).

### 6.5 Laporan
- Ringkasan: total masuk, total keluar, selisih, untuk periode yang dipilih.
- Donat kategori: 5 kategori terbesar + "Lainnya" (gabungan sisanya). Ketuk segmen → filter daftar ke kategori itu.
- Tren batang: pengeluaran per hari (7 hari) atau per minggu (4 minggu) atau per bulan (12 bulan), tergantung periode.
- Perbandingan: bulan ini vs bulan lalu per kategori (naik/turun % + nominal). Ini yang bikin laporan terasa berguna, bukan sekadar grafik cantik.
- Semua angka bisa diklik untuk melihat transaksi pembentuknya. Grafik yang tidak bisa ditelusur ke transaksi = gagal.

### 6.6 Fitur tambahan yang biasanya dibutuhkan — jawaban atas pertanyaan user
Ini daftar yang ditanyakan user ("kira-kira ada tambahan lagi nggak?"). Semuanya sudah dipetakan ke MVP/v1.1/v2 di §4 supaya tidak menumpuk di MVP:

| Tambahan | Kenapa dibutuhkan | Masuk |
|---|---|---|
| Multi-dompet + transfer antar dompet | Uang user tersebar di tunai/bank/e-wallet; tanpa ini saldo selalu salah | MVP |
| Anggaran per kategori + alert | Tanpa batas, laporan cuma jadi pajangan | MVP |
| Foto struk sebagai bukti + lihat lagi | Buat klaim, garansi, atau cek ulang harga | MVP |
| PIN / biometrik | Data uang itu sensitif walau HP pribadi | MVP |
| Export CSV/Excel + backup-restore lokal | Ganti HP / takut data hilang adalah alasan utama orang malas mulai | MVP |
| Transaksi berulang + pengingat tagihan | Gaji, kos, listrik, internet itu tetap tiap bulan — capek input ulang | v1.1 |
| Target tabungan | Orang tidak cuma mau tahu keluar, tapi mau menyisihkan | v1.1 |
| Utang & piutang | Hampir semua orang punya "si A pinjam 200rb" yang lupa | v1.1 |
| Widget & tombol cepat | Kalau buka aplikasi saja malas, pencatatan berhenti di minggu ke-2 | v1.1 |
| Insight otomatis | "Makan naik 23%" lebih berguna daripada angka mentah | v1.1 |
| Split bill / patungan | Struk makan bareng sering dibagi — tanpa ini satu orang menanggung semua di laporan | v2 |
| Import CSV mutasi bank | Buat yang malas scan, tapi tetap manual & aman (user pilih file sendiri) | v2 |
| Laporan PDF bulanan | Buat yang butuh bukti rapi (usaha kecil, laporan ke pasangan/orang tua) | v2 |
| Multi-mata uang, sync cloud | Hanya kalau user benar-benar butuh; jangan dipaksakan di awal | v2 |

---

## 7. Scan Nota / Struk — Fitur Pembeda (Paling Detail)

### 7.1 Alur pengguna (wajib persis urutan ini)
1. Home → tombol "Scan Struk" (atau FAB → Scan).
2. Kamera terbuka dengan **bingkai panduan**: kotak persegi panjang vertikal + teks "Posisikan struk di dalam bingkai, pastikan harga terbaca". Ada tombol: jepret, galeri, flash on/off.
3. Setelah foto dipilih: layar pangkas (crop) sederhana — user bisa putar 90°, potong tepi meja/latar. Tombol "Pindai".
4. Loading jujur: "Membaca struk…" + progress (bukan spinner diam). Maksimal 10 detik untuk struk normal; kalau lebih, tetap jalan tapi tampilkan "Masih dibaca, struk panjang…".
5. **Layar Review (wajib, tidak boleh langsung simpan):** tampilkan foto struk di atas (bisa diperbesar), lalu di bawahnya:
   - Nama toko (tebakan, bisa diubah, ketik bebas)
   - Tanggal struk (tebakan, date picker)
   - Daftar item: tiap baris = nama item (bisa diubah), qty (default 1), harga satuan, subtotal, kategori (chip warna + ikon, bisa diubah)
   - Baris diskon / pajak / biaya tambahan kalau terdeteksi (lihat §7.4)
   - Total terdeteksi vs total hitungan item — kalau selisih, tampilkan peringatan kuning (lihat §7.4)
   - Dompet (chip, default = dompet terakhir dipakai)
   - Tombol: "+ Tambah item", "Simpan semua", "Simpan sebagai 1 transaksi gabungan" (lihat §7.6)
6. Setelah simpan: kembali ke daftar, snackbar "Struk tersimpan — 12 item, total Rp187.500" + tombol "Lihat".
7. Foto struk asli tersimpan lokal dan bisa dibuka dari detail transaksi mana pun yang berasal dari struk itu.

### 7.2 Mesin OCR (Flutter)
- Rekomendasi utama: **Google ML Kit Text Recognition (on-device, gratis, offline)** via package `google_mlkit_text_recognition`. Alasan: tidak perlu internet, tidak kirim foto struk user ke server, cukup akurat untuk struk thermal Latin.
- Jangan pakai OCR cloud berbayar di MVP (butuh API key, biaya, privasi). Kalau ML Kit gagal total, fallback: tampilkan foto + form input manual kosong (jangan tampilkan error mentah).
- Preprocessing sebelum OCR (wajib diimplementasi, ini yang membedakan hasil bagus vs jelek):
  - Luruskan / putar sesuai orientasi foto.
  - Naikkan kontras & ubah ke grayscale untuk struk thermal yang pudar.
  - Potong sesuai crop user, bukan seluruh foto meja.
- Simpan hasil OCR mentah (teks per baris + bounding box bila tersedia) di tabel Receipt untuk debugging — user tidak melihat ini, tapi developer bisa pakai saat user lapor "struk ini salah baca".

### 7.3 Parsing struk — aturan yang harus diimplementasi
Struk Indonesia itu berantakan. Parser harus tahan terhadap variasi ini:

**a. Baris item — pola yang dikenali:**
- `NAMA BARANG  12.500` / `NAMA BARANG  12,500` / `NAMA BARANG Rp12.500`
- `NAMA BARANG  2 X 12.500  25.000` (qty × harga = subtotal)
- `NAMA BARANG  2x12500` (tanpa spasi)
- Item multi-baris: nama di baris 1, harga di baris 2 (khusus struk warung/restoran) — gabungkan jika baris berikutnya hanya berisi angka.
- Abaikan baris yang BUKAN item: header toko, alamat, nomor struk, kasir, "TERIMA KASIH", "SELAMAT DATANG", barcode angka panjang.

**b. Total, diskon, pajak:**
- Cari baris dengan kata: `TOTAL`, `JUMLAH`, `GRAND TOTAL`, `TOTAL BAYAR`, `SUBTOTAL`, `SUB TOTAL`, `TUNAI`, `CASH`, `KEMBALI`/`CHANGE`.
- `TOTAL` = patokan. `SUBTOTAL` = total sebelum diskon/pajak. Diskon: baris `DISKON`, `DISC`, `POTONGAN`, `VOUCHER` (nilai negatif / pengurang). Pajak: `PPN`, `TAX`, `PB1` (restoran 10%), `SERVICE`.
- Validasi: `jumlah subtotal item ≈ TOTAL + diskon − pajak` (toleransi Rp1.000 untuk pembulatan / salah baca satu digit). Kalau selisih > Rp1.000, tampilkan banner kuning di Review: "Total struk RpX, hitungan item RpY — cek lagi baris yang kuning" dan sorot item dengan harga paling tidak yakin.

**c. Tanggal:**
- Format yang dikenali: `03/11/2026`, `03-11-2026`, `03 Nov 2026`, `03 November 2026`, `2026/11/03`, plus jam `20:09`.
- Kalau ada banyak tanggal, pilih yang dekat dengan kata struk / paling atas. Kalau tidak ketemu, default = hari ini + label "Tanggal tidak terbaca, dicek ya" (bukan diam-diam pakai hari ini).

**d. Nama toko:**
- Ambil 1–2 baris paling atas yang huruf besar semua / nama brand yang dikenal: INDOMARET, ALFAMART, ALFAMIDI, SUPERINDO, WARUNG, RM …, APOTEK …, SPBU …, dll. Kalau tidak yakin, isi kosong dan minta user isi (placeholder "Nama toko (opsional)").

### 7.4 Confidence & koreksi (supaya user percaya)
- Setiap item hasil parse punya skor keyakinan internal: tinggi (pola qty×harga lengkap), sedang (hanya nama+harga), rendah (angka meragukan / nama terpotong).
- Item rendah ditandai titik kuning di Review + user wajib cek sebelum simpan (tombol Simpan tetap aktif, tapi banner mengingatkan).
- Jangan pernah hapus item diam-diam karena "tidak yakin". Tampilkan, biarkan user yang hapus.
- Duplikat: kalau foto struk yang sama discan 2× (hash foto sama / toko+tanggal+total sama persis dalam 10 menit), tampilkan konfirmasi: "Struk ini kayaknya sudah pernah disimpan. Tetap simpan?" — jangan simpan ganda diam-diam.

### 7.5 Kamus kategori otomatis (wajib ada, bisa diperluas)
Pencocokan berurutan (berhenti di yang pertama cocok):
1. **Koreksi user sebelumnya** (paling kuat): kalau user pernah mengubah "INDOMIE GORENG" dari Sembako ke Makan, selanjutnya "INDOMIE" ikut koreksi itu.
2. **Kamus kata kunci** (cocokkan substring, huruf kecil semua):
   - Sembako: beras, minyak goreng, gula, telur, tepung, mie, indomie, susu, kecap, saus, garam, sabun cuci, deterjen, tisu, sampo, pasta gigi, pembalut
   - Makan & Minum: nasi, ayam geprek, bakso, soto, kopi, teh botol, jus, roti, snack, coklat, es krim, katering, rice bowl
   - Transportasi: pertalite, pertamax, solar, dexlite, oli, ban, parkir, goride, grab, gocar, tol
   - Tagihan: pln, token listrik, pdam, wifi, indihome, pulsa, paket data, netflix, spotify, langganan
   - Kesehatan: paracetamol, obat, vitamin, masker, antiseptik, salep, bpjs
   - Pakaian: kaos, celana, kemeja, sepatu, sandal, jaket, hijab
   - Hiburan: bioskop, tiket, top up, diamond, game, voucher game
   - Rumah: galon, gas lpg, lampu, cat, ember, sapu
   - Pendidikan: buku, pulpen, pensil, fotokopi, print, kursus
   - Sosial: kado, amplop, parcel
3. **Default merchant:** SPBU → Transportasi; Apotek → Kesehatan; Indomaret/Alfamart tanpa kata kunci jelas → Belanja Harian (bukan Lainnya).
4. **Fallback:** 3 tebakan kategori teratas untuk dipilih user, atau "Lainnya" kalau benar-benar tidak ada petunjuk.
- Kamus ini disimpan sebagai data (file JSON / tabel) yang bisa diubah tanpa ubah kode parser. User yang mengoreksi kategori di Review otomatis menambah entri belajar lokal (poin 1 di atas).

### 7.6 Cara simpan hasil scan (pilih di Review, default = per item)
- **Default — per item:** tiap item jadi satu transaksi pengeluaran dengan kategori masing-masing, tanggal & toko sama, dompet sama, dan tertaut ke satu Receipt yang sama. Ini yang membuat "item otomatis terinput ke kategori masing-masing" benar-benar terjadi.
- **Alternatif — gabungan:** satu transaksi dengan total struk, kategori = kategori item termahal (atau yang dipilih user), catatan = "Struk [Nama Toko] — 12 item". Foto tetap tertaut.
- Diskon total: kurangi dari item terbesar (dan beri catatan "termasuk diskon RpX"), atau buat baris "Diskon" negatif — pilih satu cara dan konsisten, dokumentasikan di kode.
- Pembatalan: kalau user batal di Review, tidak ada transaksi yang tersimpan, foto tidak wajib disimpan (tanya? tidak — langsung buang, jangan menumpuk sampah).

### 7.7 Kasus struk yang harus diuji (QA wajib)
Struk Indomaret panjang (20+ item), struk Alfamart, struk warung tulis tangan? (tidak — tulis tangan TIDAK didukung MVP, sampaikan jujur di UI: "Struk tulis tangan belum bisa dibaca, input manual ya"), struk restoran dengan PB1+service, struk SPBU (1 item besar), struk fotokopi (banyak item kecil), foto miring 20°, foto gelap, struk pudar/thermal lama, struk terlipat (bagian harga terpotong). Untuk tiap kasus: hasil Review harus tetap bisa dikoreksi & disimpan, tidak crash, tidak kehilangan foto.

---

## 8. Desain UI/UX — Yang Asik, Kekinian, Enak Dipakai Tiap Hari

### 8.1 Referensi yang dicari & apa yang dicuri dari masing-masing
Gemini wajib membuka & meniru pola (bukan menjiplak aset) dari referensi ini sebelum coding UI:

| Referensi | Yang dicuri polanya |
|---|---|
| **Money Lover / Wallet by BudgetBakers** | Grid kategori ikon warna-warni, donat kategori, ringkasan bulan yang langsung kebaca |
| **Spendee** | Dompet horizontal swipe, grafik halus, warna pastel yang tidak norak |
| **DANA / GoPay (home)** | Saldo besar di atas, aksi cepat (Tambah / Scan / Transfer) dalam satu jangkauan jempol |
| **Revolut** | Kartu dompet, tipografi angka besar & tebal, dark mode yang benar-benar gelap (bukan abu-abu) |
| **Bank Jago / Jenius** | Bahasa santai, empty state yang membantu (bukan layar kosong), ilustrasi simpel |
| **Material 3 Expressive (Google, 2025)** | Tombol membulat besar, shape bervariasi, animasi spring halus — ini basis design system Flutter |
| **Apple HIG / iOS 26 Liquid Glass (sebagai inspirasi, bukan jiplakan)** | Lapisan kaca tipis untuk bottom bar & kartu di atas konten, hirarki yang lega |

**Yang TIDAK boleh ditiru:** tampilan spreadsheet (tabel rapat, teks kecil semua), warna pelangi penuh di satu layar, emoji sebagai ikon utama, banner iklan, dan onboarding 5 halaman yang tidak bisa di-skip.

### 8.2 Prinsip desain (5 saja, pegang terus)
1. **Satu layar, satu tugas.** Home = lihat & tambah. Review scan = cek & simpan. Jangan campur laporan ke Home sampai penuh.
2. **Angka adalah bintang.** Nominal selalu paling besar & paling tebal di layar. Jangan kalahkan angka dengan dekorasi.
3. **Jempol dulu.** Semua aksi utama (Tambah, Scan, Simpan) bisa dijangkau jempol tanpa pindah genggaman. Tombol Simpan selalu di bawah, lebar penuh, tinggi ≥ 52dp.
4. **Warna punya arti, bukan hiasan.** Hijau = masuk, merah/oranye lembut = keluar, amber = waspada anggaran, abu-abu = netral. Jangan pakai hijau untuk tombol hapus, merah untuk tombol simpan.
5. **Kosong itu harus membantu.** Tidak ada layar kosong polos: selalu ada ilustrasi kecil + kalimat + tombol aksi ("Belum ada transaksi bulan ini — Tambah pertama yuk").

### 8.3 Tata letak per layar (wireframe teks — implementasi wajib mengikuti ini)

**Home (layar utama):**
- Atas: sapaan kecil ("Selamat malam, boy" — nama bisa diubah di Pengaturan) + ikon lonceng anggaran (badge kalau ada yang ≥80%) + avatar/inisial.
- Kartu saldo total: gradient lembut (lihat §8.6), label "Total Saldo", angka besar, di bawahnya 3 chip kecil: Masuk bulan ini (hijau), Keluar bulan ini (merah lembut), Sisa (netral). Ketuk kartu → halaman Dompet.
- Strip dompet: kartu horizontal bisa di-swipe (Tunai / Bank / E-Wallet + saldo masing-masing).
- Aksi cepat (4 tombol bulat + label): Tambah, Scan Struk, Transfer, Laporan.
- Bagian "Bulan ini": donat mini kategori + 3 kategori terbesar (nama, %, nominal) + "Lihat semua".
- Bagian "Terakhir": 5 transaksi terbaru (ikon kategori warna, nama/catatan, tanggal, nominal kanan dengan +/−). Ketuk → detail.
- Bottom nav: Home, Transaksi, [FAB + tengah, menonjol], Anggaran, Laporan. FAB tengah = Tambah (lebih besar, warna primer). Jangan pakai bottom nav 6 item.

**Tambah Transaksi:**
- Toggle Masuk/Keluar di atas (pill, hijau/merah lembut).
- Numpad custom (§8.5) + preview nominal besar di atas numpad.
- Grid kategori 4 kolom, ikon bulat warna pastel + label 2 baris maks. Kategori terpilih = lingkaran penuh warna + centang kecil.
- Chip dompet horizontal + date picker chip ("Hari ini" / tanggal).
- Kolom catatan opsional (satu baris, placeholder "Catatan (opsional)").
- Tombol Simpan lebar penuh di bawah, selalu terlihat (tidak tertutup keyboard karena pakai numpad custom, bukan keyboard sistem).

**Scan & Review:**
- Kamera: bingkai panduan + hint + tombol galeri/flash/jepret besar di bawah.
- Review: foto struk bisa di-zoom (thumbnail atas, ketuk → fullscreen), daftar item sebagai kartu (bukan tabel rapat): tiap kartu = ikon kategori kecil + nama item (bisa ketuk untuk edit) + qty stepper (− / +) + harga kanan. Total di bawah dengan perbandingan total struk vs hitungan (peringatan kuning kalau selisih).
- Tombol Simpan di bawah, sticky, tidak hilang saat scroll daftar item panjang.

**Transaksi / Laporan / Anggaran / Pengaturan:**
- Transaksi: search bar atas + chip filter + grup per hari (§6.2).
- Laporan: periode switcher (Minggu/Bulan/Tahun) → angka ringkasan → donat → batang tren → daftar kategori.
- Anggaran: daftar progress bar per kategori + tombol edit anggaran per baris.
- Pengaturan: profil, dompet, kategori, PIN/biometrik, backup/export, tema (Terang/Gelap/Otomatis), tentang + versi.

### 8.4 Ikon & font (keputusan final, jangan diganti sembarangan)

**Font:**
- **Utama: Plus Jakarta Sans** (Google Fonts, gratis, buatan Indonesia, sangat cocok untuk teks Indonesia & angka Rupiah). Pakai untuk semua teks UI.
- **Angka headline / saldo:** Plus Jakarta Sans Bold/ExtraBold, atau Sora Bold khusus untuk angka besar kalau ingin terasa lebih "fintech". Pilih satu dan konsisten — jangan campur 3 font angka.
- **Ukuran acuan:** Saldo total 32–36sp Bold; nominal transaksi 15–16sp SemiBold; judul section 16sp Bold; body 14sp; label kecil 12sp. Dukung font sistem membesar (accessibility) tanpa layout pecah.
- **Format Rupiah (wajib):** `Rp 1.250.000` — "Rp" + spasi + titik ribuan, tanpa ",00". Nominal negatif: `−Rp 50.000` (tanda minus di depan Rp). Jangan tampilkan "Rp. 50.000,-" atau "50000".

**Ikon:**
- **Set utama: Lucide** (via package `lucide_icons` atau aset SVG Lucide) — gaya outline konsisten, rounded, modern. Alternatif yang diterima: Material Symbols Rounded. **Jangan campur** Lucide + Material + emoji dalam satu layar.
- **Ikon kategori:** satu set ikon + satu warna pastel per kategori (lihat §5.3 untuk saran ikon, §8.6 untuk warna). Ikon di lingkaran warna muda (mis. hijau muda untuk Makan), bukan ikon warna penuh di atas putih yang menyilaukan.
- **Ikon aksi:** + (tambah), scan-line / camera (scan), arrow-left-right (transfer), chart-pie (laporan), wallet, search, bell, settings, trash-2, pencil, eye/eye-off, lock, download/upload, chevron-down. Semua outline, stroke 2px, ukuran 20–24dp.
- **Jangan pakai emoji sebagai ikon kategori/aksi di UI produksi.** Emoji hanya boleh di teks catatan buatan user, bukan di desain sistem.

### 8.5 Numpad & interaksi mikro (detail yang bikin terasa "asik")
- Numpad custom: tombol 1–9, 0, 00, hapus (backspace), dan tombol "Cek" (= Simpan cepat kalau kategori+dompet sudah dipilih). Tombol besar (≥ 64dp tinggi), feedback haptic ringan saat tekan.
- Animasi: transisi layar 200–300ms ease-out, bukan default kasar; progress anggaran animasi dari 0 ke nilai; donat muncul dengan animasi sapuan; snackbar dengan aksi Urungkan.
- Haptic: ringan saat simpan berhasil, sedang saat anggaran melewati 100% (sekali saja).
- Loading: skeleton (garis abu-abu berdenyut) untuk daftar & grafik, bukan spinner di tengah layar kosong. Untuk scan, pakai progress teks (§7.1 langkah 4).
- Dark mode: bukan sekadar invert — latar #121212 / #0F1115, kartu #1E1E1E, teks putih 87%, warna kategori tetap pastel tapi lebih redup. Uji kedua tema di semua layar sebelum rilis.

### 8.6 Token desain (untuk ThemeData Flutter)
| Token | Light | Dark |
|---|---|---|
| Latar | #F6F7F9 | #0F1115 |
| Kartu / Surface | #FFFFFF | #1C1E22 |
| Primer (tombol, FAB, link) | #059669 (Emerald 600) — tepercaya, "uang" | #34D399 (Emerald 400) |
| Primer gradient kartu saldo | #059669 → #0D9488 (teal) | #059669 → #0F766E |
| Pemasukan | #16A34A (hijau) | #4ADE80 |
| Pengeluaran | #E11D48? — **jangan terlalu keras; pakai #F43F5E yang dilembutkan di chip, atau #EA580C oranye untuk keluar supaya tidak terasa "marah"** — keputusan final: Pengeluaran = #F97316 (oranye) di ringkasan, #E11D48 hanya untuk hapus/peringatan keras | Sesuaikan terang 1 tingkat |
| Peringatan anggaran | #F59E0B (amber) | #FBBF24 |
| Teks utama / sekunder | #111827 / #6B7280 | #F9FAFB / #9CA3AF |
| Radius | Kartu 20dp, tombol 16dp, chip 999 (pill), bottom sheet 28dp atas | Sama |
| Warna kategori (pastel, latar ikon) | Makan #FEF3C7, Sembako #DCFCE7, Transport #DBEAFE, Tagihan #EDE9FE, Rumah #FCE7F3, Kesehatan #FEE2E2, Pendidikan #CCFBF1, Hiburan #FEF9C3, Sosial #FFEDD5, Keuangan #E0E7FF, Kerja #D1FAE5, Lainnya #F3F4F6 | Versi gelap: warna sama tapi opacity 20% di atas kartu gelap |

**Catatan:** token di atas adalah titik awal. Gemini boleh mengusulkan 1 alternatif palet (mis. navy+gold) TAPI harus tunjukkan screenshot Home + Tambah + Review di kedua tema sebelum ganti — jangan ganti diam-diam.


---

## 9. Model Data (Flutter Local-First)

> Implementasi boleh pakai Drift (SQLite) atau Isar/Hive, tapi skema & relasi di bawah wajib dipenuhi. Semua nominal = integer Rupiah (bukan double). Semua tanggal simpan sebagai ISO lokal + zona Asia/Makassar. Soft-delete TIDAK dipakai di MVP kecuali untuk Receipt (foto) — hapus transaksi = hapus beneran setelah konfirmasi, dan saldo dihitung ulang dari transaksi yang tersisa.

### 9.1 Entitas

**Wallet (Dompet)**
- id (String/UUID), name, type (cash/bank/ewallet/other), initialBalance (int, default 0), icon (String kode ikon), color (String hex), isActive (bool), createdAt, updatedAt
- Saldo tampil = initialBalance + SUM(transactions where walletId & type=income) − SUM(expense) + transfer masuk − transfer keluar. Hitung via query, jangan simpan kolom balance yang bisa drift.

**Category (Kategori)**
- id, code (String tetap dari §5, mis. EXP_MAKAN), name, type (income/expense), icon, color, isActive, isBuiltIn (bool), sortOrder (int), keywords (List<String> untuk OCR, JSON)
- Kategori custom: code = `CUS_<timestamp>` — tidak boleh bentrok dengan kode bawaan.

**Transaction (Transaksi)**
- id, type (income/expense/transfer_out/transfer_in), amount (int > 0), categoryId (nullable untuk transfer), walletId, date (Date, jam opsional), note (String, opsional), merchant (String, opsional — dari struk), receiptId (nullable), transferPairId (nullable — untuk pasangan transfer), createdAt, updatedAt
- Contoh JSON: `{"type":"expense","amount":50000,"categoryId":"EXP_MAKAN","walletId":"w_tunai","date":"2026-11-03","note":"Nasi padang","merchant":"RM Sederhana"}`

**Receipt (Struk)**
- id, imagePath (lokal), merchant (String), receiptDate (Date, nullable), detectedTotal (int, nullable), calculatedTotal (int), rawOcrText (String, untuk debug), createdAt
- Relasi: satu Receipt → banyak Transaction (via receiptId). Hapus Receipt = tanya apakah transaksi ikut dihapus atau hanya foto yang dilepas (default: foto saja yang dihapus, transaksi tetap dengan catatan "foto dihapus").

**ReceiptItem (Item struk, sebelum/sesudah simpan)**
- Dipakai di layar Review (state sementara) dan boleh disimpan sebagai tabel audit: id, receiptId, name, qty (int), unitPrice (int), subtotal (int), categoryId (tebakan final), confidence (high/medium/low)
- Setelah simpan, ReceiptItem tetap tersimpan supaya user bisa audit "item ini asalnya dari struk mana".

**Budget (Anggaran)**
- id, categoryId, yearMonth (String "2026-11"), amount (int), createdAt, updatedAt. Unik per (categoryId, yearMonth).

**AppSettings**
- userName (String, default "boy" — bisa diubah), pinHash (String, nullable — JANGAN simpan PIN mentah), biometricEnabled (bool), theme (light/dark/system), defaultWalletId, lastBackupAt

**v1.1 (jangan dibuat di MVP, dicatat saja supaya skema tidak perlu bongkar total):** RecurringTransaction, Debt, SavingsGoal — cukup beri catatan di kode bahwa Transaction.note & categoryId sudah cukup untuk migrasi nanti.

### 9.2 Aturan migrasi & backup
- Versi skema dimulai dari 1. Setiap perubahan skema wajib ada migrasi (jangan hapus database user saat update).
- Backup lokal = export 1 file (SQLite dump / JSON + folder foto struk di-zip) ke folder yang dipilih user (Downloads / Documents). Restore = pilih file backup → validasi → timpa dengan konfirmasi 2× ("Data lama akan diganti. Lanjutkan?").
- Export CSV: kolom = Tanggal, Jenis, Kategori, Dompet, Nominal, Catatan, Toko. Format tanggal `YYYY-MM-DD`, nominal angka polos (tanpa "Rp" / titik) supaya bisa dibuka di Excel/Sheets.

---

## 10. Aturan Bisnis & Validasi (Checklist untuk Gemini)

1. Nominal harus > 0, integer, maks 999.999.999.999. Pesan error Indonesia, sopan, spesifik (bukan "Error!").
2. Kategori & dompet yang dipilih harus aktif. Kalau dompet dinonaktifkan, transaksi lama tetap tampil.
3. Tanggal transaksi tidak boleh > hari ini. Tanggal struk boleh ≤ hari ini (struk kemarin tetap boleh diinput hari ini).
4. Transfer tidak masuk hitungan pemasukan/pengeluaran di laporan & anggaran.
5. Hapus dompet yang masih punya transaksi = ditolak + pesan "Dompet ini masih punya X transaksi. Pindahkan / hapus transaksinya dulu" — jangan hapus diam-diam berikut transaksinya.
6. Hapus kategori custom yang dipakai = ubah transaksi itu ke "Lainnya" + konfirmasi jumlah transaksi yang terdampak.
7. Satu struk = satu Receipt. Scan ulang foto yang sama → peringatan duplikat (§7.4).
8. Foto struk disimpan di direktori aplikasi (bukan galeri publik) supaya tidak nyampur dengan foto pribadi — tapi sediakan tombol "Simpan ke galeri" di detail struk kalau user mau.
9. Aplikasi harus jalan penuh tanpa internet. OCR ML Kit on-device, grafik lokal, notifikasi lokal. Kalau tidak ada internet, tidak ada banner error yang mengganggu.
10. Semua teks UI Indonesia. Jangan ada teks Inggris tersisa di layar user (kecuali nama brand/package). Pesan error teknis (exception) tidak boleh tampil mentah ke user — ubah jadi kalimat Indonesia + tombol "Coba lagi".

---

## 11. Teknologi — Flutter (Keputusan User)

**Stack wajib / rekomendasi kuat:**
- **Flutter (stable terbaru) + Dart.** Android sebagai target utama uji. Struktur folder per fitur: `lib/features/transactions/`, `lib/features/scan/`, `lib/features/budgets/`, `lib/features/reports/`, `lib/features/wallets/`, `lib/core/theme/`, `lib/core/data/`.
- **State management:** Riverpod (disarankan) atau Bloc — pilih satu, konsisten di semua fitur. Jangan campur setState liar + Riverpod + Bloc dalam satu fitur.
- **Navigasi:** go_router.
- **Database lokal:** Drift (SQLite) disarankan karena query saldo/laporan butuh agregasi; alternatif Isar/Hive boleh asal agregasi & migrasi terpenuhi. Buktikan dengan test: saldo dompet setelah 1.000 transaksi tetap benar.
- **OCR & kamera:** `google_mlkit_text_recognition`, `camera` / `image_picker`, `image` (untuk grayscale/kontras preprocessing).
- **UI:** Material 3, `google_fonts` (Plus Jakarta Sans), `lucide_icons` (atau aset SVG Lucide), `fl_chart` (donat & batang) — atau chart custom yang ringan, asal interaktif (ketuk → filter).
- **Keamanan lokal:** `flutter_secure_storage` untuk PIN hash & kunci, `local_auth` untuk biometrik.
- **Notifikasi lokal:** `flutter_local_notifications` (untuk alert anggaran & pengingat v1.1).
- **Backup/export:** `csv` / `excel`, `archive` (zip foto), `share_plus` / `file_picker` untuk pilih folder backup.
- **Jangan pakai di MVP:** Firebase Auth/Firestore, iklan AdMob, analytics pihak ketiga, atau backend sendiri. Alasan: privasi + biaya + ketergantungan internet. Kalau nanti butuh sync, itu keputusan terpisah (v2).

**Kualitas kode untuk Gemini:**
- Pisahkan: UI (widget) ↔ logika (provider/controller) ↔ parsing OCR (`receipt_parser.dart` murni, bisa unit test tanpa kamera) ↔ data (repository). Parser OCR WAJIB unit testable: beri 10 contoh teks struk mentah di test, assert item/total/kategori.
- Format: `dart format`, `flutter analyze` bersih (0 error, warning dijelaskan kalau ada).
- Jangan hardcode warna/font/ukuran di tiap widget — semua lewat ThemeData + token §8.6.

---

## 12. Keamanan, Privasi & Kinerja

- PIN: simpan hash saja (bukan PIN mentah), kunci dengan `flutter_secure_storage`. Biometrik = pembuka kunci, bukan pengganti PIN (tetap ada fallback PIN).
- Foto struk: lokal saja, tidak di-upload ke server mana pun di MVP. Tulis ini di halaman Tentang supaya user tenang.
- Izin aplikasi yang diminta: Kamera, Galeri/Foto, Notifikasi (untuk anggaran). Minta izin tepat saat dibutuhkan (saat tekan Scan, bukan saat pertama buka) + jelaskan kenapa dalam satu kalimat.
- Kinerja: daftar transaksi pakai lazy list (jangan render 1.000 item sekaligus), foto struk dikompres (maks sisi panjang 1600px, JPEG 85%) sebelum disimpan supaya tidak membengkak, query laporan pakai agregasi SQL bukan loop di Dart untuk 12 bulan.
- Aksesibilitas: kontras teks ≥ 4.5:1, ukuran tombol ≥ 48dp, dukung TalkBack label untuk tombol ikon (tombol ikon tanpa label = gagal).

---

## 13. Kriteria Penerimaan & Checklist QA (Gemini Wajib Centang Sebelum Serah)

### 13.1 Acceptance per fitur (uji manual di HP)
- [ ] Tambah manual: 10 detik, saldo dompet berubah benar, muncul di daftar & laporan.
- [ ] Edit & hapus: saldo terkoreksi, tidak ada transaksi hantu.
- [ ] Scan Indomaret 15 item: ≥ 80% item benar, total selisih ≤ Rp1.000 atau banner selisih muncul.
- [ ] Scan SPBU 1 item: kategori otomatis Transportasi, total benar.
- [ ] Review scan: ubah nama/harga/kategori/hapus item/tambah item → hasil simpan sesuai editan, bukan hasil OCR mentah.
- [ ] Duplikat: scan foto sama 2× → peringatan muncul.
- [ ] Anggaran: set Rp1.000.000, input Rp850.000 → status waspada + notifikasi sekali; input Rp1.050.000 → status habis.
- [ ] Laporan: donat + batang bisa diklik → daftar transaksi pembentuknya benar.
- [ ] Transfer: laporan tidak menggembung, saldo kedua dompet benar.
- [ ] PIN/biometrik: kunci saat dibuka ulang, salah PIN 5× → jeda (bukan kunci permanen tanpa jalan keluar — sediakan reset via backup? dokumentasikan).
- [ ] Export CSV: dibuka di Sheets, kolom & angka benar.
- [ ] Backup-restore: restore di install ulang (atau HP lain) → semua transaksi + foto kembali.
- [ ] Offline penuh: matikan internet & data → semua fitur MVP jalan (kecuali yang memang butuh internet — tidak ada di MVP).
- [ ] Tema terang + gelap: semua layar dibaca nyaman, tidak ada teks putih di atas putih / hitam di atas hitam.
- [ ] Rotasi layar & font besar: layout tidak pecah, tombol Simpan tetap terlihat.

### 13.2 Yang membuat PRD ini dianggap GAGAL (jangan sampai terjadi)
- Scan langsung simpan tanpa Review.
- Kategori semua jadi "Lainnya".
- Saldo dompet tidak cocok dengan jumlah transaksi.
- Foto struk hilang setelah transaksi disimpan.
- Aplikasi minta login/cloud untuk bisa dipakai.
- Teks error Inggris mentah tampil ke user.

---

## 14. Rencana Rilis Bertahap (untuk Gemini)

- **Fase 0 — Fondasi (1–2 hari kerja):** Proyek Flutter, ThemeData + token §8.6, navigasi, database + model §9, kategori & dompet bawaan, Home + daftar kosong yang membantu.
- **Fase 1 — MVP Inti:** Tambah/edit/hapus manual, numpad, filter/cari, anggaran dasar, laporan donat+batang, PIN, export CSV, backup lokal. Uji §13.1 (kecuali scan).
- **Fase 2 — Scan Nota:** Kamera + crop, ML Kit + preprocessing, parser §7.3, kamus §7.5, Review, simpan per item/gabungan, foto bukti, duplikat. Uji 7 kasus struk §7.7.
- **Fase 3 — Poles & Serah:** Dark mode penuh, animasi & haptic, widget? (tidak — widget itu v1.1), empty state, onboarding singkat 1 layar (bisa di-skip), perbaikan dari uji HP user, `flutter analyze` bersih, README cara build APK + cara test scan.
- **Setelah Fase 3:** baru v1.1 (berulang, target tabungan, utang-piutang, widget, insight). Jangan selipkan v1.1 ke tengah MVP.

---

## 15. Pertanyaan Terbuka & Default Bila User Diam

| Pertanyaan | Default yang dipakai Gemini bila user belum jawab |
|---|---|
| Nama aplikasi final? | Pakai nama kerja "CatatUang" di UI, gampang diganti lewat satu konstanta |
| Single user atau keluarga? | Single user (MVP) |
| Cloud sync? | Tidak — lokal saja |
| Target tabungan & utang di MVP? | Tidak — v1.1 |
| Warna primer final? | Emerald #059669 (§8.6), alternatif diajukan dengan screenshot |
| iOS kapan? | Setelah Android stabil di HP user |
| Harga / monetisasi? | Gratis, pribadi, tanpa iklan di v1 |

**Keputusan yang tetap butuh jawaban user sebelum rilis (tanyakan di akhir Fase 1, bukan di awal):** nama final aplikasi, apakah widget v1.1 mau didahulukan, dan apakah backup cloud (Drive) mau masuk v1.1 atau tetap v2.

---

## Lampiran A — Contoh Struk untuk Unit Test Parser

```
INDOMARET
Jl. Test No. 1, Samarinda
03/11/2026 20:09
----------------------------
INDOMIE GORENG 2 X 3.500  7.000
BERAS 5KG  62.000
MINYAK GORENG 2L  34.500
KOPI SUSU  10.000
----------------------------
SUBTOTAL  113.500
DISKON  -5.000
TOTAL  108.500
TUNAI  110.000
KEMBALI  1.500
TERIMA KASIH
```
Hasil yang diharapkan parser: 4 item, kategori = Sembako, Sembako, Sembako, Makan & Minum; total terdeteksi 108.500; selisih hitungan vs total = 0 setelah diskon diperhitungkan.

## Lampiran B — Referensi Desain untuk Dibuka Gemini Sebelum Coding UI
- Material 3 Expressive — m3.material.io
- Money Lover, Wallet by BudgetBakers, Spendee (Play Store — lihat Home, Tambah, Laporan)
- DANA / GoPay Home (pola saldo + aksi cepat)
- Plus Jakarta Sans — Google Fonts
- Lucide Icons — lucide.dev

---

*Akhir PRD v1.0. Perubahan setelah ini ditulis sebagai v1.1 dengan catatan apa yang berubah, bukan mengedit diam-diam bagian yang sudah disetujui.*

---

## Addendum — 3 November 2026, 21:25 WITA (keputusan user, bukan perubahan MVP)

- **Backend sync (nanti, tetap v2 — BUKAN MVP): diputuskan pakai Supabase, di project yang SUDAH ADA, bukan project baru dan bukan Firebase.**
- **Project yang dipakai nanti: SIWARUNG — ref `uzwdzmazpgwbpzifqytl`** (dashboard: https://supabase.com/dashboard/project/uzwdzmazpgwbpzifqytl).
- Alasan: kuota free tier Supabase user sudah terpakai 2 project aktif, user tidak mau bikin email/project baru lagi.
- **MVP tidak berubah:** tetap single-user, local-first, offline penuh, tanpa login cloud. Sync baru dikerjakan di fase v2, dengan pola yang sudah disebut di pembahasan: SQLite lokal tetap sebagai cache offline + antrean sync, tabel sync ditambah di project SIWARUNG yang sama (bukan project baru), dengan user_id, soft-delete, updatedAt, dan aturan konflik terakhir-diubah-menang.
- **Yang TIDAK boleh dilakukan Gemini dari addendum ini:** jangan mulai coding sync sekarang, jangan minta atau menyimpan anon key / service key Supabase di repo atau di chat, dan jangan ganti MVP jadi wajib login cloud. Kunci/secret Supabase, kalau nanti dibutuhkan, diisi lewat jalur aman (env / secure storage), bukan chat.
