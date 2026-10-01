import 'package:flutter/foundation.dart';
import '../database/db_helper.dart';
import '../models/menu_item.dart';

class MenuProvider with ChangeNotifier {
  final DBHelper _dbHelper = DBHelper();
  List<MenuItem> _menus = [];
  bool _isLoading = false;
  String _selectedCategory = 'Semua';

  List<MenuItem> get menus {
    if (_selectedCategory == 'Semua') {
      return _menus;
    }
    return _menus.where((item) => item.category == _selectedCategory).toList();
  }

  List<MenuItem> get allMenus => _menus;
  bool get isLoading => _isLoading;
  String get selectedCategory => _selectedCategory;

  List<String> get categories {
    final Set<String> cats = {'Semua', 'Makanan', 'Minuman', 'Lainnya'};
    for (var m in _menus) {
      if (m.category != null && m.category!.isNotEmpty) {
        cats.add(m.category!);
      }
    }
    return cats.toList();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<void> fetchMenus() async {
    _isLoading = true;
    notifyListeners();
    try {
      _menus = await _dbHelper.getMenus();
    } catch (e) {
      debugPrint('Error fetching menus: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addMenu(MenuItem item) async {
    await _dbHelper.insertMenu(item);
    await fetchMenus();
  }

  Future<void> updateMenu(MenuItem item) async {
    await _dbHelper.updateMenu(item);
    await fetchMenus();
  }

  Future<void> deleteMenu(int id) async {
    await _dbHelper.deleteMenu(id);
    await fetchMenus();
  }
}
