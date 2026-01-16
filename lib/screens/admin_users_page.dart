import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../model/client.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  List<Client> users = [];
  // ✅ НОВЕ: Зберігаємо ID активних клієнтів
  Set<int> _activeClientIds = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
    });
    final db = DBHelper.instance;

    try {
      // 1. Отримуємо всіх користувачів
      final database = await db.database;
      final res = await database.query('Користувач');

      // 2. Отримуємо ID активних клієнтів (використовуючи новий метод)
      final activeIds = await db.getActiveClientIds();

      setState(() {
        users = res.map((m) => Client.fromMap(m)).toList();
        _activeClientIds = activeIds; // Зберігаємо для швидкої перевірки
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading users: $e');
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Помилка завантаження користувачів: $e')),
      );
    }
  }

  // ✅ НОВИЙ ВІДЖЕТ: Створюємо позначку
  Widget _buildActiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.amber.shade700,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'АКТИВНИЙ ПОКУПЕЦЬ 🌟',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Користувачі'),
        backgroundColor: Colors.indigo,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : users.isEmpty
              ? const Center(child: Text('Немає користувачів'))
              : RefreshIndicator(
                  // Додаємо RefreshIndicator для оновлення списку
                  onRefresh: _loadUsers,
                  child: ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final u = users[index];
                      // ✅ ПЕРЕВІРКА: Чи є користувач активним покупцем
                      final isActiveClient =
                          u.id != null && _activeClientIds.contains(u.id);

                      return ListTile(
                        leading: const Icon(Icons.person, color: Colors.indigo),
                        title: Row(
                          children: [
                            Text('${u.surname} ${u.name}'),
                            const SizedBox(width: 8),
                            // ✅ ВІДОБРАЖЕННЯ: Якщо активний, показуємо позначку
                            if (isActiveClient) _buildActiveBadge(),
                          ],
                        ),
                        subtitle: Text('${u.role} | ${u.email}'),
                        trailing: Text(u.phone),
                      );
                    },
                  ),
                ),
    );
  }
}
