// lib/model/category.dart
class Category {
  final int? id;
  final int? animalId;
  final String name;
  Category({this.id, required this.animalId, required this.name});
  factory Category.fromMap(Map<String, dynamic> m) => Category(
      id: m['ID_Категорії'] as int?,
      animalId: m['ID_Тварини'] as int?,
      name: m['Назва'] as String? ?? '');
  Map<String, dynamic> toMap() =>
      {'ID_Категорії': id, 'ID_Тварини': animalId, 'Назва': name};
}
