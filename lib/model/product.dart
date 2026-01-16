class Product {
  final int id;
  final String name;
  final String manufacturer;
  final double purchasePrice; // Ціна_закупки
  final double salePrice; // Ціна_продажу
  final String expiryDate;
  final int animalId;
  final int categoryId;
  final int subcategoryId;
  final int supplierId;

  Product({
    required this.id,
    required this.name,
    required this.manufacturer,
    required this.purchasePrice,
    required this.salePrice,
    required this.expiryDate,
    required this.animalId,
    required this.categoryId,
    required this.subcategoryId,
    required this.supplierId,
  });

  /// 🔹 Геттеры для совместимости с другими экранами
  double get price => salePrice;
  double get sellPrice => salePrice;

  factory Product.fromMap(Map<String, dynamic> m) {
    double toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is int) return v.toDouble();
      if (v is double) return v;
      return double.tryParse(v.toString()) ?? 0.0;
    }

    return Product(
      id: (m['ID_Товару'] as num?)?.toInt() ?? 0,
      name: m['Назва']?.toString() ?? '',
      manufacturer: m['Виробник']?.toString() ?? '',
      purchasePrice: toDouble(
        m['Ціна_закупки'] ?? m['"Ціна_закупки"'] ?? m['ЦІна_закупки'],
      ),
      salePrice: toDouble(m['Ціна_продажу']),
      expiryDate: m['Термін_придатності']?.toString() ?? '',
      animalId: (m['ID_Тварини'] as num?)?.toInt() ?? 0,
      categoryId: (m['ID_Категорії'] as num?)?.toInt() ?? 0,
      subcategoryId: (m['ID_Підкатегорії'] as num?)?.toInt() ?? 0,
      supplierId: (m['ID_Постачальника'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ID_Товару': id,
      'Назва': name,
      'Виробник': manufacturer,
      'Ціна_закупки': purchasePrice,
      'Ціна_продажу': salePrice,
      'Термін_придатності': expiryDate,
      'ID_Тварини': animalId,
      'ID_Категорії': categoryId,
      'ID_Підкатегорії': subcategoryId,
      'ID_Постачальника': supplierId,
    };
  }
}
