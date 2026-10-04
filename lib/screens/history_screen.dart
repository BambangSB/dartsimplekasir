import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/sales_report.dart';
import '../models/transaction.dart';
import '../providers/settings_provider.dart';
import '../providers/transaction_provider.dart';
import '../utils/currency_format.dart';
import '../utils/printer_helper.dart';
import '../utils/report_share_helper.dart';
import 'printer_settings_screen.dart';

class HistoryScreen extends StatefulWidget {
  final Function(TransactionModel)? onPrintReceipt;

  const HistoryScreen({super.key, this.onPrintReceipt});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _selectedPeriodIndex = 0; // 0: Hari Ini, 1: 7 Hari Terakhir, 2: Bulan Ini, 3: Kustom
  DateTimeRange? _customDateRange;

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
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final transactions = transactionProvider.transactions;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Riwayat & Laporan'),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.receipt_long), text: 'Daftar Transaksi'),
              Tab(icon: Icon(Icons.analytics_outlined), text: 'Laporan & Rekap'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Segarkan',
              onPressed: () => transactionProvider.fetchTransactions(),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // Tab 1: Daftar Riwayat Transaksi Struk
            _buildTransactionListTab(transactionProvider, transactions),

            // Tab 2: Laporan & Statistik Penjualan
            _buildSalesReportTab(transactionProvider, settingsProvider, transactions),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionListTab(
    TransactionProvider transactionProvider,
    List<TransactionModel> transactions,
  ) {
    if (transactionProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (transactions.isEmpty) {
      return Center(
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
      );
    }

    return ListView.separated(
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
    );
  }

  Widget _buildSalesReportTab(
    TransactionProvider transactionProvider,
    SettingsProvider settingsProvider,
    List<TransactionModel> transactions,
  ) {
    if (transactionProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    switch (_selectedPeriodIndex) {
      case 0: // Hari Ini
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 1: // 7 Hari Terakhir
        final sevenDaysAgo = now.subtract(const Duration(days: 6));
        startDate = DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 2: // Bulan Ini
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case 3: // Kustom
        if (_customDateRange != null) {
          startDate = DateTime(_customDateRange!.start.year, _customDateRange!.start.month, _customDateRange!.start.day);
          endDate = DateTime(_customDateRange!.end.year, _customDateRange!.end.month, _customDateRange!.end.day, 23, 59, 59);
        } else {
          startDate = DateTime(now.year, now.month, now.day);
          endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        }
        break;
      default:
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    }

    final report = SalesReport.fromTransactions(transactions, startDate, endDate);
    final dateFmt = DateFormat('dd MMM yyyy');
    final periodeLabel = (startDate.year == endDate.year && startDate.month == endDate.month && startDate.day == endDate.day)
        ? dateFmt.format(startDate)
        : '${dateFmt.format(startDate)} - ${dateFmt.format(endDate)}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(0, 'Hari Ini'),
                const SizedBox(width: 8),
                _buildFilterChip(1, '7 Hari Terakhir'),
                const SizedBox(width: 8),
                _buildFilterChip(2, 'Bulan Ini'),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.date_range, size: 16, color: Colors.deepOrange),
                  label: Text(
                    _selectedPeriodIndex == 3 && _customDateRange != null
                        ? '${DateFormat('dd/MM').format(_customDateRange!.start)} - ${DateFormat('dd/MM').format(_customDateRange!.end)}'
                        : 'Pilih Tanggal',
                    style: TextStyle(
                      color: _selectedPeriodIndex == 3 ? Colors.deepOrange : Colors.black87,
                      fontWeight: _selectedPeriodIndex == 3 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  backgroundColor: _selectedPeriodIndex == 3 ? Colors.orange.shade50 : null,
                  side: BorderSide(
                    color: _selectedPeriodIndex == 3 ? Colors.deepOrange : Colors.grey.shade300,
                  ),
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      initialDateRange: _customDateRange ??
                          DateTimeRange(
                            start: now.subtract(const Duration(days: 7)),
                            end: now,
                          ),
                    );
                    if (picked != null) {
                      setState(() {
                        _customDateRange = picked;
                        _selectedPeriodIndex = 3;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Label Periode
          Card(
            elevation: 0,
            color: Colors.orange.shade50.withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.orange.shade100),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.deepOrange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Periode: $periodeLabel',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.deepOrange),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Tombol Aksi Berbagi ke WhatsApp & Ekspor File
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.chat, size: 18),
                  label: const Text(
                    'Kirim Teks WA',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  onPressed: () => ReportShareHelper.shareTextToWhatsApp(
                    report,
                    settingsProvider.storeName,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.deepOrange,
                    side: const BorderSide(color: Colors.deepOrange),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.table_chart_outlined, size: 18),
                  label: const Text(
                    'Ekspor File CSV',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  onPressed: () => ReportShareHelper.shareCSVFile(
                    report,
                    settingsProvider.storeName,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Card Utama: Total Omzet
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Colors.deepOrange,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Omzet Penjualan',
                        style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      Icon(Icons.monetization_on_outlined, color: Colors.white, size: 24),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyFormat.toRupiah(report.totalRevenue),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Metrik Ringkasan Lainnya (Row)
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.receipt_long,
                  title: 'Transaksi',
                  value: '${report.totalTransactions} Trx',
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Item Terjual',
                  value: '${report.totalItemsSold} Porsi',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.pie_chart_outline,
                  title: 'Rata-rata/Trx',
                  value: CurrencyFormat.toRupiah(report.averageOrderValue),
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Daftar Menu Terlaris (Top Selling Items)
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.deepOrange, size: 22),
              const SizedBox(width: 8),
              const Text(
                'Menu Terlaris (Top Selling)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${report.topSellingItems.length} Menu',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (report.topSellingItems.isEmpty)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 30.0, horizontal: 16.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'Belum ada transaksi pada periode ini',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: report.topSellingItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final item = report.topSellingItems[idx];
                return _buildTopSellingCard(idx + 1, item);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(int index, String label) {
    final isSelected = _selectedPeriodIndex == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Colors.deepOrange,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (val) {
        if (val) {
          setState(() {
            _selectedPeriodIndex = index;
          });
        }
      },
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSellingCard(int rank, TopSellingItem item) {
    Color badgeColor = Colors.grey.shade200;
    Color badgeTextColor = Colors.black87;

    if (rank == 1) {
      badgeColor = const Color(0xFFFFD700); // Gold
      badgeTextColor = Colors.black87;
    } else if (rank == 2) {
      badgeColor = const Color(0xFFC0C0C0); // Silver
      badgeTextColor = Colors.black87;
    } else if (rank == 3) {
      badgeColor = const Color(0xFFCD7F32); // Bronze
      badgeTextColor = Colors.white;
    }

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: badgeColor,
              child: Text(
                '$rank',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: badgeTextColor),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  if (item.category != null)
                    Text(
                      item.category!,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${item.quantity} terjual',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.deepOrange),
                ),
                Text(
                  CurrencyFormat.toRupiah(item.totalSales),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

