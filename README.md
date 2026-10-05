# Kasir UMKM 🏪 (Dart & Flutter)

Aplikasi Point of Sale (POS) / Kasir Digital yang dirancang khusus untuk pelaku UMKM (Warung Makan, Kafe, Toko Kelontong, dsb). Berjalan secara multiplatform (**Android & iOS**) dan dapat beroperasi penuh secara **offline** tanpa ketergantungan koneksi internet.

---

## ✨ Fitur Utama

### 1. 📋 Manajemen Katalog & Menu
- Tampilan grid responsif 2 kolom dengan foto, kategori, dan harga berformat Rupiah (`Rp XX.XXX`).
- Fitur pencarian realtime dan filter cepat berdasarkan kategori (*Semua, Makanan, Minuman, Camilan, Lainnya*).
- Tambah & Edit Menu lengkap dengan foto langsung dari **Kamera** atau **Galeri** (tersimpan lokal di media penyimpanan aplikasi).
- Dialog konfirmasi saat menghapus menu.

### 2. 🛒 Kasir & Checkout Dinamis
- Tambah & kurangi jumlah pesanan langsung dari kartu menu.
- Floating Cart Bar yang muncul otomatis ketika ada item dalam keranjang.
- **Pilihan Metode Pembayaran**:
  - **Tunai (Cash)**: Form input uang diterima, tombol cepat nominal (*Uang Pas, Rp 10.000 s/d Rp 200.000*), dan kalkulasi kembalian otomatis secara realtime.
  - **Non-Tunai / QRIS**: Pembayaran langsung senilai total tagihan (pelanggan cukup scan QRIS fisik toko).
- Dialog pembayaran sukses dengan opsi langsung cetak struk atau selesai.

### 3. 🧾 Profil Toko & Struk Penjualan
- Pengaturan Nama Toko/UMKM dan Alamat/Catatan Kaki yang tersimpan permanen di database lokal SQLite.
- Nama UMKM otomatis tercantum pada:
  - Header nota digital saat pembayaran selesai.
  - Header struk digital pada riwayat transaksi.
  - Header hasil cetak printer thermal Bluetooth.
- Integritas data terjamin: riwayat transaksi tersimpan permanen sebagai catatan pembukuan usaha yang akurat.

### 4. 🖨️ Integrasi Printer Thermal Bluetooth (ESC/POS 58mm)
- Pemindaian dan koneksi langsung ke printer thermal Bluetooth yang sudah di-pairing.
- Uji coba cetak (*Test Print*) untuk memastikan kesiapan printer.
- Format struk standar kertas 58mm mencakup header toko, nomor invoice, waktu, rincian item, metode pembayaran (Tunai/QRIS), total bayar, kembalian, dan ucapan terima kasih.

### 5. 📊 Laporan & Rekap Penjualan Kasir
- Tab khusus **Laporan & Rekap** di layar riwayat transaksi.
- Filter periode fleksibel: *Hari Ini*, *7 Hari Terakhir*, *Bulan Ini*, dan *Rentang Tanggal Kustom*.
- Metrik bisnis otomatis:
  - **Total Omzet Penjualan**
  - **Breakdown Omzet Tunai vs QRIS** (nilai rupiah & jumlah transaksi)
  - **Total Transaksi & Item Terjual**
  - **Rata-rata Nilai Transaksi (AOV)**
- **Ranking Menu Terlaris**: Daftar menu paling laku diurutkan dari peringkat 1 lengkap dengan jumlah porsi dan total penjualan.
- **Berbagi & Ekspor Data**:
  - **Kirim Teks WhatsApp**: Pesan ringkasan rapi berformat emoji siap kirim ke pemilik/grup toko.
  - **Ekspor Spreadsheet CSV**: File `.csv` komprehensif berisi ringkasan, rekap menu terlaris, dan rincian transaksi per invoice yang dapat dibuka di Microsoft Excel atau Google Sheets.

### 6. 🎨 Branding & Antarmuka Modern
- Logo & icon aplikasi bergaya 3D isometric khusus tema kasir UMKM.
- Mendukung launcher icon Android (adaptive icon + semua ukuran mipmap) dan iOS.
- Layar Splash Screen beranimasi halus (*fade & scale*) dengan transisi otomatis ke beranda utama kasir.
- Tema Material Design 3 dengan palet warna utama **Deep Orange**.

---

## 🛠️ Arsitektur & Teknologi

| Komponen | Spesifikasi |
| :--- | :--- |
| **Framework** | Flutter 3.24.1 (Dart 3.5.0) |
| **State Management** | Provider 6.x (`MultiProvider`) |
| **Database Lokal** | SQLite (`sqflite`, `path`) |
| **Printer Bluetooth** | `print_bluetooth_thermal` & `esc_pos_utils_plus` |
| **Media & Foto** | `image_picker` & `path_provider` |
| **Ekspor & Berbagi** | `share_plus` |
| **Ikon Launcher** | `flutter_launcher_icons` |
| **Format Angka & Tanggal** | `intl` (Locale `id_ID`) |

---

## 📁 Struktur Direktori Proyek

```
lib/
├── database/
│   └── db_helper.dart             # SQLite helper (CRUD menus & transactions, settings, migrasi)
├── models/
│   ├── cart_item.dart             # Model item keranjang belanja
│   ├── menu_item.dart             # Model katalog menu
│   ├── sales_report.dart          # Model kalkulasi statistik & laporan penjualan
│   └── transaction.dart          # Model transaksi penjualan & metode pembayaran
├── providers/
│   ├── cart_provider.dart         # State management keranjang kasir
│   ├── menu_provider.dart         # State management katalog menu
│   ├── settings_provider.dart     # State management profil & nama UMKM
│   └── transaction_provider.dart  # State management riwayat transaksi
├── screens/
│   ├── add_menu_screen.dart       # Layar tambah / ubah menu & foto kamera/galeri
│   ├── checkout_screen.dart       # Layar pembayaran (Tunai / QRIS)
│   ├── history_screen.dart        # Layar riwayat transaksi & tab laporan rekap
│   ├── home_screen.dart           # Layar katalog kasir utama & grid menu
│   ├── printer_settings_screen.dart # Layar koneksi Bluetooth printer thermal
│   └── splash_screen.dart         # Layar pembuka beranimasi
├── utils/
│   ├── currency_format.dart       # Utilitas pemformatan mata uang Rupiah
│   ├── printer_helper.dart        # Utilitas generator ESC/POS 58mm & printer Bluetooth
│   └── report_share_helper.dart   # Utilitas pesan WhatsApp & ekspor file CSV
└── main.dart                      # Entrypoint aplikasi
```

---

## 🚀 Panduan Menjalankan & Build

### 1. Menjalankan Mode Development
```bash
# Unduh paket dependensi
flutter pub get

# Jalankan di perangkat / emulator yang terhubung
flutter run
```

### 2. Menjalankan Analisis & Pengujian Kode
```bash
# Pemeriksaan analisis statis (harus 0 issues)
flutter analyze

# Eksekusi seluruh automated unit & widget test
flutter test
```

### 3. Generate App Launcher Icons
```bash
flutter pub run flutter_launcher_icons
```

### 4. Build APK Release untuk Android
```bash
flutter build apk --release
# File APK siap pakai berada di: build/app/outputs/flutter-apk/app-release.apk
```

---

## 📄 Lisensi
Dikembangkan untuk mendukung kemajuan digitalisasi Usaha Mikro, Kecil, dan Menengah (UMKM) Indonesia.
