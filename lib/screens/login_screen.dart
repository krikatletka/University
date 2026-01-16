import 'package:flutter/material.dart';
import 'package:flutter_application_9/db/database_helper.dart';
import 'package:flutter_application_9/model/client.dart';
import 'package:flutter_application_9/screens/registration_screen.dart';
import 'package:flutter_application_9/screens/user_home_screen.dart';
import 'package:flutter_application_9/screens/admin_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _loginCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    final login = _loginCtrl.text.trim();
    final pass = _passCtrl.text;

    if (login.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Введіть логін і пароль')));
      return;
    }

    setState(() => _loading = true);

    try {
      final Client? user = await DBHelper.instance.login(login, pass);

      setState(() => _loading = false);

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Невірний логін або пароль')));
        return;
      }

      final role = (user.role ?? '').toLowerCase();
      if (role.contains('адмін')) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const AdminHomeScreen()));
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => UserHomeScreen(user: user)),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Помилка входу: $e')));
    }
  }

  @override
  void dispose() {
    _loginCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Вхід')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          TextField(
              controller: _loginCtrl,
              decoration: const InputDecoration(labelText: 'Логін')),
          const SizedBox(height: 8),
          TextField(
              controller: _passCtrl,
              decoration: const InputDecoration(labelText: 'Пароль'),
              obscureText: true),
          const SizedBox(height: 16),
          _loading
              ? const CircularProgressIndicator()
              : ElevatedButton(onPressed: _login, child: const Text('Увійти')),
          const SizedBox(height: 8),
          TextButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const RegistrationScreen()));
              },
              child: const Text('Реєстрація'))
        ]),
      ),
    );
  }
}
