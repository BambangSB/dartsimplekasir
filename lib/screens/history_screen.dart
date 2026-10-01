import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/settings_provider.dart';
import '../providers/transaction_provider.dart';
import '../utils/currency_format.dart';
import '../utils/printer_helper.dart';
import 'printer_settings_screen.dart';

class HistoryScreen extends StatefulWidget {
  final Function(TransactionModel)? onPrintReceipt;

  const HistoryScreen({super.key, this.onPrintReceipt});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TransactionProvider>(context, listen: false).fetchTransactions();
    });
  }

  void _showTransactionDetail(TransactionModel transaction) {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Struk Digital
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  settingsProvider.storeName.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.1),
                  textAlign: TextAlign.center,
                ),
              ),
              if (settingsProvider.storeAddress.isNotEmpty) ...[
                const SizedBox(height: 2),
                Center(
                  child: Text(
                    settingsProvider.storeAddress,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'STRUK / NOTA PENJUALAN',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  transaction.invoiceNumber,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ),
              Center(
                child: Text(
                  DateFormat('dd MMM yyyy, HH:mm:ss').format(transaction.dateTime),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(thickness: 1.5),

              // Daftar Item yang dibeli
              ...transaction.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.item.name,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            Text(
                              '${item.quantity} x ${CurrencyFormat.toRupiah(item.item.price)}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        CurrencyFormat.toRupiah(item.subtotal),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }),

              const Divider(thickness: 1.5),
              const SizedBox(height: 8),

              // Rincian Pembayaran
              _buildReceiptRow('Total Tagihan', CurrencyFormat.toRupiah(transaction.totalAmount), isBold: true),
              _buildReceiptRow('Uang Diterima', CurrencyFormat.toRupiah(transaction.cashReceived)),
              _buildReceiptRow('Kembalian', CurrencyFormat.toRupiah(transaction.changeAmount)),

              const SizedBox(height: 24),

              // Tombol Cetak Struk
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.print),
                label: const Text(
                  'Cetak Struk ke Printer Thermal',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                onPressed: () async {
                  if (widget.onPrintReceipt != null) {
                    Navigator.of(ctx).pop();
                    widget.onPrintReceipt!(transaction);
                    return;
                  }

                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.of(ctx).pop();

                  final printerHelper = PrinterHelper();
                  final isConnected = await printerHelper.isConnected();

                  if (isConnected) {
                    await printerHelper.printTransaction(
                      transaction,
                      storeName: settingsProvider.storeName,
                      storeAddress: settingsProvider.storeAddress,
                    );
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Struk berhasil dicetak!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    navigator.push(
                      MaterialPageRoute(builder: (_) => const PrinterSettingsScreen()),
                    );
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Silakan hubungkan printer thermal terlebih dahulu'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
              ),

              const SizedBox(height: 8),

              // Tombol Tutup
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Tutup Nota'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 15 : 14,
              color: isBold ? Colors.black87 : Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: isBold ? 16 : 14,
              color: isBold ? Colors.deepOrange : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final transactions = transactionProvider.transactions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan',
            onPressed: () => transactionProvider.fetchTransactions(),
          ),
        ],
      ),
      body: transactionProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : transactions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 70, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'Belum ada riwayat transaksi',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Transaksi yang selesai akan tercatat di sini',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: transactions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final trx = transactions[index];
                    final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(trx.dateTime);

                    return Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange.shade50,
                          child: const Icon(Icons.receipt, color: Colors.deepOrange),
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              trx.invoiceNumber,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              CurrencyFormat.toRupiah(trx.totalAmount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(dateStr, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              Text(
                                '${trx.items.length} Barang',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: () => _showTransactionDetail(trx),
                      ),
                    );
                  },
                ),
    );
  }
}
