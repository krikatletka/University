class CartItem {
  final int id;
  final int userId;
  final int productId;
  final int qty;
  final String name;
  final double price;

  CartItem({
    required this.id,
    required this.userId,
    required this.productId,
    required this.qty,
    required this.name,
    required this.price,
  });

  factory CartItem.fromMap(Map<String, dynamic> m) {
    double toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is int) return v.toDouble();
      if (v is double) return v;
      return double.tryParse(v.toString()) ?? 0.0;
    }

    return CartItem(
      id: (m['id'] as num).toInt(),
      userId: (m['userId'] as num).toInt(),
      productId: (m['productId'] as num).toInt(),
      qty: (m['qty'] as num).toInt(),
      name: m['name']?.toString() ?? '',
      price: toDouble(m['price']),
    );
  }
}
