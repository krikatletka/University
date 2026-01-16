class Client {
  final int? id;
  final String login;
  final String password;
  final String surname;
  final String name; // <-- тут тепер без апострофа
  final String phone;
  final String email;
  final String role;

  Client({
    this.id,
    required this.login,
    required this.password,
    required this.surname,
    required this.name,
    required this.phone,
    required this.email,
    required this.role,
  });

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['ID_Користувача'] as int?,
      login: map['Логін'] ?? '',
      password: map['Пароль'] ?? '',
      surname: map['Прізвище'] ?? '',
      name: map['Імя'] ?? '', // <--- тут головне зміна
      phone: map['Телефон'] ?? '',
      email: map['Email'] ?? '',
      role: map['Роль'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ID_Користувача': id,
      'Логін': login,
      'Пароль': password,
      'Прізвище': surname,
      'Імя': name, // <--- тут головне зміна
      'Телефон': phone,
      'Email': email,
      'Роль': role,
    };
  }
}
