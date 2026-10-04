import 'package:flutter_test/flutter_test.dart';
import 'package:simple_kasir/models/cart_item.dart';
import 'package:simple_kasir/models/menu_item.dart';
import 'package:simple_kasir/models/sales_report.dart';
import 'package:simple_kasir/models/transaction.dart';

void main() {
  group('SalesReport Calculation Tests', () {
    final transactions = [
      TransactionModel(
        invoiceNumber: 'TRX-001',
        dateTime: DateTime(2026, 10, 5, 9, 30),
        totalAmount: 25000,
        cashReceived: 50000,
        changeAmount: 25000,
        items: [
          CartItem(item: MenuItem(name: 'Kopi Hitam', price: 5000), quantity: 3),
          CartItem(item: MenuItem(name: 'Nasi Goreng', price: 10000), quantity: 1),
        ],
      ),
      TransactionModel(
        invoiceNumber: 'TRX-002',
        dateTime: DateTime(2026, 10, 5, 14, 15),
        totalAmount: 30000,
        cashReceived: 30000,
        changeAmount: 0,
        items: [
          CartItem(item: MenuItem(name: 'Kopi Hitam', price: 5000), quantity: 2),
          CartItem(item: MenuItem(name: 'Mie Goreng', price: 10000), quantity: 2),
        ],
      ),
      // Transaksi hari kemarin (di luar filter hari ini)
      TransactionModel(
        invoiceNumber: 'TRX-003',
        dateTime: DateTime(2026, 10, 4, 10, 0),
        totalAmount: 15000,
        cashReceived: 20000,
        changeAmount: 5000,
        items: [
          CartItem(item: MenuItem(name: 'Es Teh Manis', price: 5000), quantity: 3),
        ],
      ),
    ];

    test('Computes daily sales report correctly', () {
      final start = DateTime(2026, 10, 5);
      final end = DateTime(2026, 10, 5);
      final report = SalesReport.fromTransactions(transactions, start, end);

      expect(report.totalTransactions, 2);
      expect(report.totalRevenue, 55000);
      expect(report.totalItemsSold, 8); // (3+1) + (2+2)
      expect(report.averageOrderValue, 27500);

      // Kopi Hitam should be rank 1 (3 + 2 = 5 porsi)
      expect(report.topSellingItems.first.name, 'Kopi Hitam');
      expect(report.topSellingItems.first.quantity, 5);
      expect(report.topSellingItems.first.totalSales, 25000);
    });

    test('Computes multi-day sales report correctly', () {
      final start = DateTime(2026, 10, 4);
      final end = DateTime(2026, 10, 5);
      final report = SalesReport.fromTransactions(transactions, start, end);

      expect(report.totalTransactions, 3);
      expect(report.totalRevenue, 70000); // 25000 + 30000 + 15000
      expect(report.totalItemsSold, 11);
    });
  });
}
