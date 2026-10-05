import 'package:flutter/foundation.dart';
import '../database/db_helper.dart';

class SettingsProvider with ChangeNotifier {
  final DBHelper _dbHelper = DBHelper();

  String _storeName = 'KasirKu UMKM';
  String _storeAddress = 'Semoga Usaha Anda Lancar & Berkah';
  bool _hasSeenTutorial = false;
  bool _isLoading = false;

  String get storeName => _storeName;
  String get storeAddress => _storeAddress;
  bool get hasSeenTutorial => _hasSeenTutorial;
  bool get isLoading => _isLoading;

  /// Memuat profil toko / UMKM dan status tutorial dari database SQLite
  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final name = await _dbHelper.getSetting('store_name');
      final address = await _dbHelper.getSetting('store_address');
      final tutorialStatus = await _dbHelper.getSetting('has_seen_tutorial');

      if (name != null && name.trim().isNotEmpty) {
        _storeName = name.trim();
      }
      if (address != null) {
        _storeAddress = address.trim();
      }
      _hasSeenTutorial = tutorialStatus == 'true';
    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Menandai bahwa pengguna telah menyelesaikan / melihat tutorial
  Future<void> completeTutorial() async {
    _hasSeenTutorial = true;
    notifyListeners();
    try {
      await _dbHelper.setSetting('has_seen_tutorial', 'true');
    } catch (e) {
      debugPrint('Error saving tutorial status: $e');
    }
  }

  /// Memperbarui nama dan alamat UMKM
  Future<void> updateStoreProfile({
    required String storeName,
    required String storeAddress,
  }) async {
    final cleanedName = storeName.trim().isEmpty ? 'KasirKu UMKM' : storeName.trim();
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
