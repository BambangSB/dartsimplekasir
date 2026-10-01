import 'package:flutter_test/flutter_test.dart';
import 'package:simple_kasir/models/menu_item.dart';
import 'package:simple_kasir/providers/cart_provider.dart';

void main() {
  group('CartProvider Tests', () {
    test('Initial cart should be empty', () {
      final cart = CartProvider();
      expect(cart.totalItemCount, 0);
      expect(cart.totalAmount, 0.0);
      expect(cart.cartItemList.isEmpty, true);
    });

    test('Adding items should update count and total amount', () {
      final cart = CartProvider();
      final item1 = MenuItem(id: 1, name: 'Kopi Hitam', price: 5000.0);
      final item2 = MenuItem(id: 2, name: 'Es Teh', price: 4000.0);

      cart.addToCart(item1);
      cart.addToCart(item1);
      cart.addToCart(item2);

      expect(cart.totalItemCount, 3);
      expect(cart.getItemQuantity(1), 2);
      expect(cart.getItemQuantity(2), 1);
      expect(cart.totalAmount, 14000.0);
    });

    test('Decreasing item quantity should update or remove item', () {
      final cart = CartProvider();
      final item1 = MenuItem(id: 1, name: 'Kopi Hitam', price: 5000.0);

      cart.addToCart(item1);
      cart.addToCart(item1);
      expect(cart.getItemQuantity(1), 2);

      cart.decreaseQuantity(item1);
      expect(cart.getItemQuantity(1), 1);
      expect(cart.totalAmount, 5000.0);

      cart.decreaseQuantity(item1);
      expect(cart.getItemQuantity(1), 0);
      expect(cart.totalItemCount, 0);
    });

    test('Clear cart should reset all items', () {
      final cart = CartProvider();
      final item = MenuItem(id: 1, name: 'Nasi Goreng', price: 15000.0);

      cart.addToCart(item);
      expect(cart.totalItemCount, 1);

      cart.clearCart();
      expect(cart.totalItemCount, 0);
      expect(cart.totalAmount, 0.0);
    });
  });
}
