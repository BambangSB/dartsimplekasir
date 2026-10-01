import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/cart_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/transaction_provider.dart';
import '../utils/currency_format.dart';
import '../utils/printer_helper.dart';
import 'printer_settings_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final VoidCallback? onPrintReceipt;

  const CheckoutScreen({super.key, this.onPrintReceipt});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _cashController = TextEditingController();
  double _cashReceived = 0.0;
  bool _isProcessing = false;

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  void _setCash(double amount) {
    setState(() {
      _cashReceived = amount;
      _cashController.text = amount.toStringAsFixed(0);
    });
  }

  Future<void> _processPayment(CartProvider cartProvider) async {
    final totalAmount = cartProvider.totalAmount;

    if (_cashReceived < totalAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Uang tunai kurang dari total tagihan!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final now = DateTime.now();
      final invoiceNum = 'TRX-${DateFormat('yyyyMMdd-HHmmss').format(now)}';
      final changeAmount = _cashReceived - totalAmount;

      final transaction = TransactionModel(
        invoiceNumber: invoiceNum,
        dateTime: now,
        totalAmount: totalAmount,
        cashReceived: _cashReceived,
        changeAmount: changeAmount,
        items: cartProvider.cartItemList,
      );

      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      await transactionProvider.addTransaction(transaction);

      // Bersihkan keranjang
      cartProvider.clearCart();

      if (!mounted) return;

      // Tampilkan dialog pembayaran sukses
      _showSuccessDialog(transaction);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memproses transaksi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSuccessDialog(TransactionModel transaction) {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 56),
            const SizedBox(height: 8),
            Text(
              settingsProvider.storeName.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              'Pembayaran Berhasil!',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.green),
            ),
            const SizedBox(height: 4),
            Text(
              transaction.invoiceNumber,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(),
            _buildDialogRow('Total Tagihan', CurrencyFormat.toRupiah(transaction.totalAmount)),
            _buildDialogRow('Uang Diterima', CurrencyFormat.toRupiah(transaction.cashReceived)),
            _buildDialogRow(
              'Kembalian',
              CurrencyFormat.toRupiah(transaction.changeAmount),
              isHighlight: true,
            ),
            const Divider(),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.print, color: Colors.deepOrange),
                  label: const Text('Cetak Struk', style: TextStyle(color: Colors.deepOrange)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.deepOrange),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    if (widget.onPrintReceipt != null) {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).pop();
                      widget.onPrintReceipt!();
                      return;
                    }

                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.of(ctx).pop();
                    navigator.pop();

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
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Selesai'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDialogRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isHighlight ? Colors.green.shade700 : Colors.black87,
              fontSize: isHighlight ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final totalAmount = cartProvider.totalAmount;
    final changeAmount = (_cashReceived - totalAmount) > 0 ? (_cashReceived - totalAmount) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran & Checkout'),
      ),
      body: cartProvider.totalItemCount == 0
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 70, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('Keranjang belanja kosong', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Colors.deepOrange),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Kembali ke Menu'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Daftar Pesanan
                  Text(
                    'Ringkasan Pesanan (${cartProvider.totalItemCount} Item)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 0,
                    color: Colors.grey.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cartProvider.cartItemList.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, idx) {
                        final item = cartProvider.cartItemList[idx];
                        return ListTile(
                          title: Text(item.item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            '${item.quantity} x ${CurrencyFormat.toRupiah(item.item.price)}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          trailing: Text(
                            CurrencyFormat.toRupiah(item.subtotal),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Total Tagihan Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.deepOrange.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Tagihan',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          CurrencyFormat.toRupiah(totalAmount),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Input Uang Tunai
                  const Text(
                    'Uang Tunai Diterima',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _cashController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      hintText: '0',
                      prefixIcon: const Icon(Icons.money, color: Colors.deepOrange),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: _cashReceived > 0
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _cashReceived = 0.0;
                                  _cashController.clear();
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (val) {
                      setState(() {
                        _cashReceived = double.tryParse(val.trim()) ?? 0.0;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Tombol Cepat Nominal Uang
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        label: const Text('Uang Pas'),
                        backgroundColor: Colors.orange.shade50,
                        side: BorderSide(color: Colors.deepOrange.shade200),
                        onPressed: () => _setCash(totalAmount),
                      ),
                      if (totalAmount <= 10000)
                        ActionChip(
                          label: const Text('Rp 10.000'),
                          onPressed: () => _setCash(10000),
                        ),
                      if (totalAmount <= 20000)
                        ActionChip(
                          label: const Text('Rp 20.000'),
                          onPressed: () => _setCash(20000),
                        ),
                      if (totalAmount <= 50000)
                        ActionChip(
                          label: const Text('Rp 50.000'),
                          onPressed: () => _setCash(50000),
                        ),
                      if (totalAmount <= 100000)
                        ActionChip(
                          label: const Text('Rp 100.000'),
                          onPressed: () => _setCash(100000),
                        ),
                      if (totalAmount <= 200000)
                        ActionChip(
                          label: const Text('Rp 200.000'),
                          onPressed: () => _setCash(200000),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Kembalian
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Kembalian', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        Text(
                          CurrencyFormat.toRupiah(changeAmount),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _cashReceived >= totalAmount ? Colors.green.shade700 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Tombol Selesaikan Transaksi
                  FilledButton.icon(
                    onPressed: _isProcessing || _cashReceived < totalAmount
                        ? null
                        : () => _processPayment(cartProvider),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(
                      _isProcessing ? 'Memproses...' : 'Selesaikan Pembayaran',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
