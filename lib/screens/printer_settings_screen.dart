import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:provider/provider.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';
import '../models/transaction.dart';
import '../providers/settings_provider.dart';
import '../utils/printer_helper.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  final PrinterHelper _printerHelper = PrinterHelper();
  bool _isBluetoothEnabled = false;
  bool _isConnected = false;
  bool _isLoading = false;
  List<BluetoothInfo> _devices = [];
  String? _connectedMac;

  @override
  void initState() {
    super.initState();
    _checkStatusAndLoadDevices();
  }

  Future<void> _checkStatusAndLoadDevices() async {
    setState(() => _isLoading = true);
    try {
      final bool btEnabled = await _printerHelper.isBluetoothEnabled();
      final bool connected = await _printerHelper.isConnected();
      List<BluetoothInfo> devices = [];

      if (btEnabled) {
        devices = await _printerHelper.getPairedDevices();
      }

      setState(() {
        _isBluetoothEnabled = btEnabled;
        _isConnected = connected;
        _devices = devices;
        _connectedMac = _printerHelper.connectedMac;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _connectToPrinter(String macAddress) async {
    setState(() => _isLoading = true);
    try {
      final success = await _printerHelper.connect(macAddress);
      if (mounted) {
        if (success) {
          setState(() {
            _isConnected = true;
            _connectedMac = macAddress;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Berhasil terhubung ke printer!'), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal terhubung ke printer'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _disconnectPrinter() async {
    setState(() => _isLoading = true);
    try {
      await _printerHelper.disconnect();
      if (mounted) {
        setState(() {
          _isConnected = false;
          _connectedMac = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Printer terputus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _printTestReceipt() async {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    setState(() => _isLoading = true);
    try {
      final sampleTransaction = TransactionModel(
        invoiceNumber: 'TEST-001',
        dateTime: DateTime.now(),
        totalAmount: 25000,
        cashReceived: 50000,
        changeAmount: 25000,
        items: [
          CartItem(
            item: MenuItem(name: 'Menu Tes 1', price: 15000),
            quantity: 1,
          ),
          CartItem(
            item: MenuItem(name: 'Minuman Tes 2', price: 10000),
            quantity: 1,
          ),
        ],
      );

      final success = await _printerHelper.printTransaction(
        sampleTransaction,
        storeName: settingsProvider.storeName,
        storeAddress: settingsProvider.storeAddress,
      );
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Struk tes berhasil dikirim ke printer!'), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal mencetak, pastikan printer terhubung'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saat mencetak: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showEditStoreDialog(BuildContext context, SettingsProvider settings) {
    final nameController = TextEditingController(text: settings.storeName);
    final addressController = TextEditingController(text: settings.storeAddress);

    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.storefront, color: Colors.deepOrange),
            SizedBox(width: 8),
            Text('Nama UMKM di Nota', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nama ini akan dicetak di header struk printer thermal & nota digital.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama UMKM / Toko',
                  hintText: 'Contoh: Kedai Berkah',
                  prefixIcon: Icon(Icons.store),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Alamat / Catatan Kaki Nota',
                  hintText: 'Contoh: Jl. Merdeka No. 12',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.deepOrange),
            onPressed: () async {
              final newName = nameController.text.trim();
              final newAddress = addressController.text.trim();
              if (newName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nama UMKM tidak boleh kosong')),
                );
                return;
              }
              await settings.updateStoreProfile(
                storeName: newName,
                storeAddress: newAddress,
              );
              if (!dCtx.mounted) return;
              Navigator.of(dCtx).pop();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profil UMKM berhasil diperbarui!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Printer Thermal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Pindai Ulang',
            onPressed: _isLoading ? null : _checkStatusAndLoadDevices,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Card Profil UMKM di Struk
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.orange.shade200),
                    ),
                    color: Colors.orange.shade50.withOpacity(0.4),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.storefront, color: Colors.deepOrange),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Nama UMKM di Struk / Nota',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.deepOrange, size: 20),
                                tooltip: 'Ubah Nama UMKM',
                                onPressed: () => _showEditStoreDialog(context, settingsProvider),
                              ),
                            ],
                          ),
                          const Divider(),
                          Text(
                            settingsProvider.storeName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepOrange),
                          ),
                          if (settingsProvider.storeAddress.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              settingsProvider.storeAddress,
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Status Bluetooth Card
                  Card(
                    elevation: 0,
                    color: _isBluetoothEnabled ? Colors.green.shade50 : Colors.red.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: _isBluetoothEnabled ? Colors.green.shade200 : Colors.red.shade200,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            _isBluetoothEnabled ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                            color: _isBluetoothEnabled ? Colors.green.shade700 : Colors.red.shade700,
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isBluetoothEnabled ? 'Bluetooth Aktif' : 'Bluetooth Tidak Aktif',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: _isBluetoothEnabled ? Colors.green.shade900 : Colors.red.shade900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _isConnected
                                      ? 'Status: Terhubung ke printer'
                                      : 'Status: Belum ada printer terhubung',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _isBluetoothEnabled ? Colors.green.shade700 : Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Daftar Printer Terpasang (Paired)
                  const Text(
                    'Perangkat Printer Bluetooth (Paired)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pastikan printer thermal Anda sudah di-pairing di menu Pengaturan Bluetooth HP.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),

                  if (_devices.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.print_disabled, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              'Tidak ada printer Bluetooth terdeteksi',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Hubungkan printer via Bluetooth HP Anda terlebih dahulu, lalu tekan tombol Segarkan di pojok kanan atas.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _devices.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final device = _devices[index];
                        final isDeviceConnected = _isConnected && _connectedMac == device.macAdress;

                        return Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isDeviceConnected ? Colors.deepOrange : Colors.grey.shade200,
                              width: isDeviceConnected ? 2 : 1,
                            ),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isDeviceConnected
                                  ? Colors.deepOrange
                                  : Colors.orange.shade50,
                              child: Icon(
                                Icons.print,
                                color: isDeviceConnected ? Colors.white : Colors.deepOrange,
                              ),
                            ),
                            title: Text(
                              device.name.isNotEmpty ? device.name : 'Unknown Device',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              device.macAdress,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                            trailing: isDeviceConnected
                                ? OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                    ),
                                    onPressed: _disconnectPrinter,
                                    child: const Text('Putus'),
                                  )
                                : FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.deepOrange,
                                    ),
                                    onPressed: () => _connectToPrinter(device.macAdress),
                                    child: const Text('Hubungkan'),
                                  ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 32),

                  // Tombol Cetak Tes Struk
                  if (_isConnected)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.receipt_long),
                      label: const Text(
                        'Cetak Tes Struk',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _printTestReceipt,
                    ),
                ],
              ),
            ),
    );
  }
}
