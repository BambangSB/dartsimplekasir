# Simple Kasir UMKM (Dart & Flutter)

Aplikasi Point of Sale (POS) / Kasir Sederhana yang dirancang khusus untuk pelaku UMKM. Berjalan secara multiplatform (Android & iOS) dan dapat beroperasi penuh secara **offline**.

## ✨ Fitur Utama

- **Manajemen Menu**: Tambah, edit, dan lihat katalog menu makanan & minuman dengan foto (kamera/galeri) serta harga Rupiah.
- **Transaksi Kasir (POS)**: Keranjang belanja dinamis, kalkulasi kembalian otomatis dengan pilihan nominal uang cepat.
- **Riwayat Transaksi**: Rekap seluruh transaksi penjualan berurutan dari yang terbaru (permanen & aman untuk pembukuan).
- **Profil Toko / Nama UMKM di Struk**: Nama toko dan alamat/catatan kaki dapat diatur dan otomatis tampil pada:
  - Header nota/struk digital saat pembayaran sukses & riwayat transaksi.
  - Header cetakan struk printer thermal Bluetooth.
- **Cetak Struk Thermal Bluetooth**: Integrasi printer thermal mini ESC/POS 58mm untuk cetak struk belanja fisik langsung dari smartphone/tablet kasir.

## 🛠️ Teknologi & Arsitektur

- **Framework**: Flutter (Dart)
- **State Management**: Provider (`MultiProvider`)
- **Database Lokal**: SQLite (`sqflite`)
- **Printer Bluetooth**: `print_bluetooth_thermal` & `esc_pos_utils_plus`
- **Tema Desain**: Material 3 dengan nuansa warna utama *Orange* (`Colors.deepOrange`)
- **Format Uang**: `intl` (Rupiah Indonesia `id_ID`)

## 🚀 Menjalankan Aplikasi

```bash
# Mengunduh dependensi
flutter pub get

# Menjalankan di perangkat / emulator
flutter run

# Build APK Release
flutter build apk --release
```
