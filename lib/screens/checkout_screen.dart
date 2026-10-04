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
  String _paymentMethod = 'Tunai'; // 'Tunai' atau 'QRIS'
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

    if (_paymentMethod == 'Tunai' && _cashReceived < totalAmount) {
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
      final cash = _paymentMethod == 'QRIS' ? totalAmount : _cashReceived;
      final changeAmount = _paymentMethod == 'QRIS' ? 0.0 : (_cashReceived - totalAmount);

      final transaction = TransactionModel(
        invoiceNumber: invoiceNum,
        dateTime: now,
        totalAmount: totalAmount,
        cashReceived: cash,
        changeAmount: changeAmount,
        paymentMethod: _paymentMethod,
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

  void _showQrisDialog(double amount, String storeName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: const Text(
                'QRIS STANDAR PEMBAYARAN',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              storeName.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.qr_code_2_rounded,
                    size: 180,
                    color: Colors.grey.shade900,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyFormat.toRupiah(amount),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Silakan minta pelanggan scan kode QR ini menggunakan BCA, Mandiri, BRI, GoPay, OVO, DANA, atau aplikasi e-wallet lainnya.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Tutup QR Code'),
            ),
          ),
        ],
      ),
    );
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
            _buildDialogRow('Metode', transaction.paymentMethod == 'QRIS' ? 'QRIS / Non-Tunai' : 'Tunai'),
            _buildDialogRow('Total Tagihan', CurrencyFormat.toRupiah(transaction.totalAmount)),
            if (transaction.paymentMethod == 'Tunai') ...[
              _buildDialogRow('Uang Diterima', CurrencyFormat.toRupiah(transaction.cashReceived)),
              _buildDialogRow(
                'Kembalian',
                CurrencyFormat.toRupiah(transaction.changeAmount),
                isHighlight: true,
              ),
            ] else ...[
              _buildDialogRow('Status', 'LUNAS (QRIS)', isHighlight: true),
            ],
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

                  // Pilihan Metode Pembayaran
                  const Text(
                    'Pilih Metode Pembayaran',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _paymentMethod = 'Tunai';
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            decoration: BoxDecoration(
                              color: _paymentMethod == 'Tunai' ? Colors.deepOrange.shade50 : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _paymentMethod == 'Tunai' ? Colors.deepOrange : Colors.grey.shade300,
                                width: _paymentMethod == 'Tunai' ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.payments_rounded,
                                  color: _paymentMethod == 'Tunai' ? Colors.deepOrange : Colors.grey.shade600,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Tunai',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: _paymentMethod == 'Tunai' ? Colors.deepOrange : Colors.grey.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _paymentMethod = 'QRIS';
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            decoration: BoxDecoration(
                              color: _paymentMethod == 'QRIS' ? Colors.deepOrange.shade50 : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _paymentMethod == 'QRIS' ? Colors.deepOrange : Colors.grey.shade300,
                                width: _paymentMethod == 'QRIS' ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.qr_code_2_rounded,
                                  color: _paymentMethod == 'QRIS' ? Colors.deepOrange : Colors.grey.shade600,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Non-Tunai / QRIS',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: _paymentMethod == 'QRIS' ? Colors.deepOrange : Colors.grey.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (_paymentMethod == 'Tunai') ...[
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
                  ] else ...[
                    // Tampilan Non-Tunai / QRIS
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.deepOrange.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepOrange.withOpacity(0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.deepOrange.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.qr_code_scanner, color: Colors.deepOrange, size: 28),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Pembayaran QRIS / Non-Tunai',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Nominal Pas: ${CurrencyFormat.toRupiah(totalAmount)}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.deepOrange.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Divider(),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                final storeName = Provider.of<SettingsProvider>(context, listen: false).storeName;
                                _showQrisDialog(totalAmount, storeName);
                              },
                              icon: const Icon(Icons.qr_code_2, color: Colors.deepOrange),
                              label: const Text(
                                'Tampilkan Kode QRIS Toko',
                                style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.deepOrange),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber.shade200),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.info_outline, color: Colors.amber.shade900, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Pastikan notifikasi dana masuk telah diterima di m-banking / e-wallet toko Anda sebelum menyelesaikan transaksi.',
                                    style: TextStyle(fontSize: 12, color: Colors.amber.shade900, height: 1.3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),

                  // Tombol Selesaikan Transaksi
                  FilledButton.icon(
                    onPressed: _isProcessing || (_paymentMethod == 'Tunai' && _cashReceived < totalAmount)
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
                      _isProcessing
                          ? 'Memproses...'
                          : _paymentMethod == 'QRIS'
                              ? 'Selesaikan Transaksi (QRIS)'
                              : 'Selesaikan Pembayaran',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
