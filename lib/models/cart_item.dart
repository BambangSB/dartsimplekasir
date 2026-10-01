import 'menu_item.dart';

class CartItem {
  final MenuItem item;
  int quantity;

  CartItem({
    required this.item,
    this.quantity = 1,
  });

  double get subtotal => item.price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'menuId': item.id,
      'menuName': item.name,
      'price': item.price,
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      item: MenuItem(
        id: map['menuId'] as int?,
        name: map['menuName'] as String,
        price: (map['price'] as num).toDouble(),
      ),
      quantity: map['quantity'] as int,
    );
  }
}
