import 'transaction.dart';

class TopSellingItem {
  final String name;
  final int quantity;
  final double totalSales;
  final String? category;

  TopSellingItem({
    required this.name,
    required this.quantity,
    required this.totalSales,
    this.category,
  });
}

class SalesReport {
  final DateTime startDate;
  final DateTime endDate;
  final double totalRevenue;
  final int totalTransactions;
  final int totalItemsSold;
  final double averageOrderValue;
  final double cashRevenue;
  final int cashTransactions;
  final double qrisRevenue;
  final int qrisTransactions;
  final List<TopSellingItem> topSellingItems;
  final List<TransactionModel> transactions;

  SalesReport({
    required this.startDate,
    required this.endDate,
    required this.totalRevenue,
    required this.totalTransactions,
    required this.totalItemsSold,
    required this.averageOrderValue,
    this.cashRevenue = 0.0,
    this.cashTransactions = 0,
    this.qrisRevenue = 0.0,
    this.qrisTransactions = 0,
    required this.topSellingItems,
    required this.transactions,
  });

  /// Menghitung statistik penjualan dari kumpulan transaksi berdasarkan rentang tanggal
  factory SalesReport.fromTransactions(
    List<TransactionModel> allTransactions,
    DateTime start,
    DateTime end,
  ) {
    // Normalisasi start ke 00:00:00 dan end ke 23:59:59
    final normStart = DateTime(start.year, start.month, start.day, 0, 0, 0);
    final normEnd = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);

    final filtered = allTransactions.where((t) {
      return !t.dateTime.isBefore(normStart) && !t.dateTime.isAfter(normEnd);
    }).toList();

    double revenue = 0.0;
    int itemsCount = 0;
    double cashRev = 0.0;
    int cashCount = 0;
    double qrisRev = 0.0;
    int qrisCount = 0;
    final Map<String, TopSellingItem> itemStats = {};

    for (var trx in filtered) {
      revenue += trx.totalAmount;
      if (trx.paymentMethod == 'QRIS') {
        qrisRev += trx.totalAmount;
        qrisCount++;
      } else {
        cashRev += trx.totalAmount;
        cashCount++;
      }

      for (var cartItem in trx.items) {
        itemsCount += cartItem.quantity;
        final name = cartItem.item.name;
        if (itemStats.containsKey(name)) {
          final existing = itemStats[name]!;
          itemStats[name] = TopSellingItem(
            name: name,
            quantity: existing.quantity + cartItem.quantity,
            totalSales: existing.totalSales + cartItem.subtotal,
            category: cartItem.item.category ?? existing.category,
          );
        } else {
          itemStats[name] = TopSellingItem(
            name: name,
            quantity: cartItem.quantity,
            totalSales: cartItem.subtotal,
            category: cartItem.item.category,
          );
        }
      }
    }

    final topList = itemStats.values.toList()
      ..sort((a, b) => b.quantity.compareTo(a.quantity));

    final aov = filtered.isEmpty ? 0.0 : revenue / filtered.length;

    return SalesReport(
      startDate: normStart,
      endDate: normEnd,
      totalRevenue: revenue,
      totalTransactions: filtered.length,
      totalItemsSold: itemsCount,
      averageOrderValue: aov,
      cashRevenue: cashRev,
      cashTransactions: cashCount,
      qrisRevenue: qrisRev,
      qrisTransactions: qrisCount,
      topSellingItems: topList,
      transactions: filtered,
    );
  }
}
