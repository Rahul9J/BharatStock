class Product {
  final String id;
  final String name;
  final String category;
  final double price;
  final int quantity;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.quantity,
  });

  // Convert "Product" to something Firebase understands (Map)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'price': price,
      'quantity': quantity,
    };
  }

  // Convert Firebase data back to "Product"
  factory Product.fromMap(String id, Map<String, dynamic> map) {
    return Product(
      id: id,
      name: map['name'] ?? '',
      category: map['category'] ?? 'General',
      price: (map['price'] ?? 0).toDouble(),
      quantity: (map['quantity'] ?? 0).toInt(),
    );
  }
}
