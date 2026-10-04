import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/sales_report.dart';
import 'currency_format.dart';

class ReportShareHelper {
  /// Format pesan teks ringkasan untuk WhatsApp
  static String formatWhatsAppText(SalesReport report, String storeName) {
    final dateFmt = DateFormat('dd MMM yyyy');
    final isSameDay = report.startDate.year == report.endDate.year &&
        report.startDate.month == report.endDate.month &&
        report.startDate.day == report.endDate.day;

    final periodeStr = isSameDay
        ? dateFmt.format(report.startDate)
        : '${dateFmt.format(report.startDate)} - ${dateFmt.format(report.endDate)}';

    final buffer = StringBuffer();
    buffer.writeln('📊 *LAPORAN PENJUALAN KASIR*');
    buffer.writeln('🏪 *${storeName.toUpperCase()}*');
    buffer.writeln('📅 Periode: $periodeStr');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('💰 *Total Omzet*: ${CurrencyFormat.toRupiah(report.totalRevenue)}');
    buffer.writeln('💵 *Tunai*: ${CurrencyFormat.toRupiah(report.cashRevenue)} (${report.cashTransactions} Trx)');
    buffer.writeln('📱 *QRIS / Non-Tunai*: ${CurrencyFormat.toRupiah(report.qrisRevenue)} (${report.qrisTransactions} Trx)');
    buffer.writeln('🧾 *Total Transaksi*: ${report.totalTransactions} Transaksi');
    buffer.writeln('📦 *Item Terjual*: ${report.totalItemsSold} Porsi/Item');
    buffer.writeln('📈 *Rata-rata/Trx*: ${CurrencyFormat.toRupiah(report.averageOrderValue)}');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');

    if (report.topSellingItems.isNotEmpty) {
      buffer.writeln('\n🏆 *MENU TERLARIS*:');
      final topLimit = report.topSellingItems.length > 5 ? 5 : report.topSellingItems.length;
      for (int i = 0; i < topLimit; i++) {
        final item = report.topSellingItems[i];
        buffer.writeln('${i + 1}. *${item.name}*: ${item.quantity} terjual (${CurrencyFormat.toRupiah(item.totalSales)})');
      }
    } else {
      buffer.writeln('\n_Belum ada penjualan pada periode ini_');
    }

    buffer.writeln('\n_Dicatat otomatis via Kasir UMKM_');
    return buffer.toString();
  }

  /// Bagikan teks ringkasan langsung ke WhatsApp
  static Future<void> shareTextToWhatsApp(SalesReport report, String storeName) async {
    final text = formatWhatsAppText(report, storeName);
    await Share.share(
      text,
      subject: 'Laporan Penjualan $storeName',
    );
  }

  /// Buat file CSV dan bagikan via WhatsApp / share sheet
  static Future<void> shareCSVFile(SalesReport report, String storeName) async {
    final dateFmt = DateFormat('dd/MM/yyyy');
    final isSameDay = report.startDate.year == report.endDate.year &&
        report.startDate.month == report.endDate.month &&
        report.startDate.day == report.endDate.day;

    final periodeStr = isSameDay
        ? dateFmt.format(report.startDate)
        : '${dateFmt.format(report.startDate)} - ${dateFmt.format(report.endDate)}';

    final buffer = StringBuffer();
    // Header Laporan
    buffer.writeln('LAPORAN PENJUALAN KASIR');
    buffer.writeln('Nama Toko,"$storeName"');
    buffer.writeln('Periode,"$periodeStr"');
    buffer.writeln('Waktu Export,"${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}"');
    buffer.writeln('');

    // Ringkasan
    buffer.writeln('RINGKASAN');
    buffer.writeln('Total Omzet,${report.totalRevenue}');
    buffer.writeln('Total Omzet Tunai,${report.cashRevenue}');
    buffer.writeln('Transaksi Tunai,${report.cashTransactions}');
    buffer.writeln('Total Omzet QRIS,${report.qrisRevenue}');
    buffer.writeln('Transaksi QRIS,${report.qrisTransactions}');
    buffer.writeln('Total Transaksi,${report.totalTransactions}');
    buffer.writeln('Total Item Terjual,${report.totalItemsSold}');
    buffer.writeln('Rata-rata Transaksi,${report.averageOrderValue.round()}');
    buffer.writeln('');

    // Rincian Menu Terlaris
    buffer.writeln('REKAP PER MENU');
    buffer.writeln('No,Nama Menu,Kategori,Jumlah Terjual,Total Penjualan');
    for (int i = 0; i < report.topSellingItems.length; i++) {
      final item = report.topSellingItems[i];
      buffer.writeln('${i + 1},"${item.name}","${item.category ?? '-'}",${item.quantity},${item.totalSales}');
    }
    buffer.writeln('');

    // Rincian Transaksi
    buffer.writeln('RINCIAN TRANSAKSI');
    buffer.writeln('No,Nomor Invoice,Waktu,Metode Pembayaran,Jumlah Item,Total Tagihan,Uang Diterima,Kembalian');
    for (int i = 0; i < report.transactions.length; i++) {
      final trx = report.transactions[i];
      final timeStr = DateFormat('dd/MM/yyyy HH:mm:ss').format(trx.dateTime);
      buffer.writeln('${i + 1},"${trx.invoiceNumber}","$timeStr","${trx.paymentMethod}",${trx.items.length},${trx.totalAmount},${trx.cashReceived},${trx.changeAmount}');
    }

    final tempDir = await getTemporaryDirectory();
    final fileName = 'Laporan_Penjualan_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(buffer.toString());

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      text: 'Laporan Penjualan $storeName ($periodeStr)',
      subject: 'Laporan Penjualan $storeName',
    );
  }
}
