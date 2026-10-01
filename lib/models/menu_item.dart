class MenuItem {
  final int? id;
  final String name;
  final double price;
  final String? imagePath;
  final String? category;

  MenuItem({
    this.id,
    required this.name,
    required this.price,
    this.imagePath,
    this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'imagePath': imagePath,
      'category': category ?? 'Umum',
    };
  }

  factory MenuItem.fromMap(Map<String, dynamic> map) {
    return MenuItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      imagePath: map['imagePath'] as String?,
      category: map['category'] as String?,
    );
  }

  MenuItem copyWith({
    int? id,
    String? name,
    double? price,
    String? imagePath,
    String? category,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      imagePath: imagePath ?? this.imagePath,
      category: category ?? this.category,
    );
  }
}
