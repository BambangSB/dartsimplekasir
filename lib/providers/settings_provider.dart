import 'package:flutter/foundation.dart';
import '../database/db_helper.dart';

class SettingsProvider with ChangeNotifier {
  final DBHelper _dbHelper = DBHelper();

  String _storeName = 'KASIR UMKM';
  String _storeAddress = 'Semoga Usaha Anda Lancar & Berkah';
  bool _isLoading = false;

  String get storeName => _storeName;
  String get storeAddress => _storeAddress;
  bool get isLoading => _isLoading;

  /// Memuat profil toko / UMKM dari database SQLite
  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final name = await _dbHelper.getSetting('store_name');
      final address = await _dbHelper.getSetting('store_address');

      if (name != null && name.trim().isNotEmpty) {
        _storeName = name.trim();
      }
      if (address != null) {
        _storeAddress = address.trim();
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Memperbarui nama dan alamat UMKM
  Future<void> updateStoreProfile({
    required String storeName,
    required String storeAddress,
  }) async {
    final cleanedName = storeName.trim().isEmpty ? 'KASIR UMKM' : storeName.trim();
    final cleanedAddress = storeAddress.trim();

    _storeName = cleanedName;
    _storeAddress = cleanedAddress;
    notifyListeners();

    try {
      await _dbHelper.setSetting('store_name', cleanedName);
      await _dbHelper.setSetting('store_address', cleanedAddress);
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }
}
