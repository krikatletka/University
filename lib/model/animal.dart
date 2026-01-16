// lib/model/animal.dart
class Animal {
  final int? id;
  final String name;
  Animal({this.id, required this.name});
  factory Animal.fromMap(Map<String, dynamic> m) =>
      Animal(id: m['ID_Тварини'] as int?, name: m['Назва'] as String? ?? '');
  Map<String, dynamic> toMap() => {'ID_Тварини': id, 'Назва': name};
}
