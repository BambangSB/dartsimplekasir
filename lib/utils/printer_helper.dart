import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import '../models/transaction.dart';
import 'currency_format.dart';

class PrinterHelper {
  static final PrinterHelper _instance = PrinterHelper._internal();
  factory PrinterHelper() => _instance;
  PrinterHelper._internal();

  String? _connectedMac;
  String? get connectedMac => _connectedMac;

  /// Cek apakah Bluetooth aktif
  Future<bool> isBluetoothEnabled() async {
    return await PrintBluetoothThermal.bluetoothEnabled;
  }

  /// Cek status koneksi printer saat ini
  Future<bool> isConnected() async {
    return await PrintBluetoothThermal.connectionStatus;
  }

  /// Mendapatkan daftar perangkat Bluetooth yang telah di-pairing
  Future<List<BluetoothInfo>> getPairedDevices() async {
    return await PrintBluetoothThermal.pairedBluetooths;
  }

  /// Menghubungkan ke printer menggunakan MAC Address
  Future<bool> connect(String macAddress) async {
    final bool result = await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
    if (result) {
      _connectedMac = macAddress;
    }
    return result;
  }

  /// Memutuskan koneksi printer
  Future<bool> disconnect() async {
    final bool result = await PrintBluetoothThermal.disconnect;
    _connectedMac = null;
    return result;
  }

  /// Membuat format bytes struk belanja ESC/POS (standar 58mm kertas thermal)
  Future<List<int>> generateReceiptBytes(
    TransactionModel transaction, {
    String storeName = 'KASIRKU UMKM',
    String storeAddress = 'Semoga Usaha Anda Lancar & Berkah',
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    // Header Toko
    bytes += generator.text(
      storeName,
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
        bold: true,
      ),
    );
    bytes += generator.text(
      storeAddress,
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.hr(ch: '=');

    // Informasi Transaksi
    bytes += generator.row([
      PosColumn(text: 'No. TRX', width: 4),
      PosColumn(text: transaction.invoiceNumber, width: 8, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Waktu', width: 4),
      PosColumn(
        text: DateFormat('dd/MM/yy HH:mm').format(transaction.dateTime),
        width: 8,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);
    bytes += generator.hr(ch: '-');

    // Daftar Barang
    for (var cartItem in transaction.items) {
      bytes += generator.text(
        cartItem.item.name,
        styles: const PosStyles(bold: true),
      );
      bytes += generator.row([
        PosColumn(
          text: '${cartItem.quantity} x ${CurrencyFormat.toRupiah(cartItem.item.price)}',
          width: 7,
        ),
        PosColumn(
          text: CurrencyFormat.toRupiah(cartItem.subtotal),
          width: 5,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }
    bytes += generator.hr(ch: '-');

    // Ringkasan Pembayaran
    bytes += generator.row([
      PosColumn(text: 'Metode', width: 6),
      PosColumn(
        text: transaction.paymentMethod == 'QRIS' ? 'QRIS' : 'Tunai',
        width: 6,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Total', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(
        text: CurrencyFormat.toRupiah(transaction.totalAmount),
        width: 6,
        styles: const PosStyles(align: PosAlign.right, bold: true),
      ),
    ]);
    if (transaction.paymentMethod == 'Tunai') {
      bytes += generator.row([
        PosColumn(text: 'Tunai', width: 6),
        PosColumn(
          text: CurrencyFormat.toRupiah(transaction.cashReceived),
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
      bytes += generator.row([
        PosColumn(text: 'Kembali', width: 6),
        PosColumn(
          text: CurrencyFormat.toRupiah(transaction.changeAmount),
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    } else {
      bytes += generator.row([
        PosColumn(text: 'Bayar (QRIS)', width: 6),
        PosColumn(
          text: CurrencyFormat.toRupiah(transaction.totalAmount),
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
      bytes += generator.row([
        PosColumn(text: 'Status', width: 6),
        PosColumn(
          text: 'LUNAS',
          width: 6,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]);
    }
    bytes += generator.hr(ch: '=');

    // Footer Struk
    bytes += generator.text(
      'Terima Kasih Telah Berbelanja',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      'Barang yang sudah dibeli\ntidak dapat ditukar/dikembalikan',
      styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontB),
    );
    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }

  /// Mencetak transaksi langsung ke printer yang terhubung
  Future<bool> printTransaction(
    TransactionModel transaction, {
    String? storeName,
    String? storeAddress,
  }) async {
    final bool connected = await isConnected();
    if (!connected) return false;

    final bytes = await generateReceiptBytes(
      transaction,
      storeName: storeName ?? 'KASIRKU UMKM',
      storeAddress: storeAddress ?? 'Semoga Usaha Anda Lancar & Berkah',
    );
    final result = await PrintBluetoothThermal.writeBytes(bytes);
    return result;
  }
}
