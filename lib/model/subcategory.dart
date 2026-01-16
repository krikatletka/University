// lib/model/subcategory.dart
class Subcategory {
  final int? id;
  final int? categoryId;
  final String name;
  Subcategory({this.id, required this.categoryId, required this.name});
  factory Subcategory.fromMap(Map<String, dynamic> m) => Subcategory(
      id: m['ID_Підкатегорії'] as int?,
      categoryId: m['ID_Категорії'] as int?,
      name: m['Назва'] as String? ?? '');
  Map<String, dynamic> toMap() =>
      {'ID_Підкатегорії': id, 'ID_Категорії': categoryId, 'Назва': name};
}
