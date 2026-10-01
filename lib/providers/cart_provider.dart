import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';

class CartProvider with ChangeNotifier {
  final Map<int, CartItem> _items = {};

  Map<int, CartItem> get items => {..._items};

  List<CartItem> get cartItemList => _items.values.toList();

  int get totalItemCount {
    int total = 0;
    _items.forEach((key, cartItem) {
      total += cartItem.quantity;
    });
    return total;
  }

  double get totalAmount {
    double total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.subtotal;
    });
    return total;
  }

  int getItemQuantity(int menuId) {
    if (_items.containsKey(menuId)) {
      return _items[menuId]!.quantity;
    }
    return 0;
  }

  void addToCart(MenuItem menu) {
    if (menu.id == null) return;
    if (_items.containsKey(menu.id)) {
      _items.update(
        menu.id!,
        (existing) => CartItem(
          item: existing.item,
          quantity: existing.quantity + 1,
        ),
      );
    } else {
      _items.putIfAbsent(
        menu.id!,
        () => CartItem(item: menu, quantity: 1),
      );
    }
    notifyListeners();
  }

  void decreaseQuantity(MenuItem menu) {
    if (menu.id == null || !_items.containsKey(menu.id)) return;

    if (_items[menu.id]!.quantity > 1) {
      _items.update(
        menu.id!,
        (existing) => CartItem(
          item: existing.item,
          quantity: existing.quantity - 1,
        ),
      );
    } else {
      _items.remove(menu.id);
    }
    notifyListeners();
  }

  void removeItem(int menuId) {
    _items.remove(menuId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
