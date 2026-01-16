import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../model/client.dart';
import 'user_home_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _login = TextEditingController();
  final _pass = TextEditingController();
  final _surname = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  bool _loading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final userToRegister = Client(
      id: null,
      login: _login.text.trim(),
      password: _pass.text,
      surname: _surname.text.trim(),
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      role: 'покупець',
    );

    try {
      // 1. Зберігаємо користувача і отримуємо новий ID, згенерований базою даних.
      final newId = await DBHelper.instance.register(userToRegister);

      // 2. Створюємо оновлений об'єкт Client з отриманим ID.
      final registeredUser = Client(
        id: newId, // ✅ ВИПРАВЛЕНО: Присвоюємо згенерований ID
        login: userToRegister.login,
        password: userToRegister.password,
        surname: userToRegister.surname,
        name: userToRegister.name,
        phone: userToRegister.phone,
        email: userToRegister.email,
        role: userToRegister.role,
      );

      if (!mounted) return;

      // 3. Переходимо на головний екран, передаючи користувача з дійсним ID.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => UserHomeScreen(user: registeredUser)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Помилка реєстрації: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _login.dispose();
    _pass.dispose();
    _surname.dispose();
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Реєстрація')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _login,
                decoration: const InputDecoration(labelText: 'Логін'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Введіть логін' : null,
              ),
              TextFormField(
                controller: _pass,
                decoration: const InputDecoration(labelText: 'Пароль'),
                obscureText: true,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Введіть пароль' : null,
              ),
              TextFormField(
                controller: _surname,
                decoration: const InputDecoration(labelText: 'Прізвище'),
              ),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: "Ім'я"),
              ),
              TextFormField(
                controller: _phone,
                decoration: const InputDecoration(labelText: 'Телефон'),
              ),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 16),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _register,
                      child: const Text('Зареєструватися'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
