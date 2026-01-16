import 'package:flutter/material.dart';
import '../db/database_helper.dart';

class AdminSalesPage extends StatefulWidget {
  const AdminSalesPage({super.key});

  @override
  State<AdminSalesPage> createState() => _AdminSalesPageState();
}

class _AdminSalesPageState extends State<AdminSalesPage> {
  List<Map<String, dynamic>> sales = [];
  // ✅ НОВЕ: Змінна для зберігання звіту
  List<Map<String, dynamic>> salesReport = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ОНОВЛЕНО: Завантажує продажі та звіт
  Future<void> _loadData() async {
    setState(() {
      _loading = true;
    });

    await _loadSales();
    await _loadReport();

    setState(() {
      _loading = false;
    });
  }

  // Метод для завантаження детальних продажів
  Future<void> _loadSales() async {
    final db = DBHelper.instance;
    final database = await db.database;
    final res = await database.rawQuery('''
      SELECT s.ID_Продажу, s.Дата_продажу, s.Кількість, s.Сума,
             t.Назва AS Товар, u.Логін AS Користувач
      FROM Продаж s
      JOIN Товар t ON s.ID_Товару = t.ID_Товару
      JOIN Користувач u ON s.ID_Клієнта = u.ID_Користувача
      ORDER BY s.Дата_продажу DESC
    ''');
    setState(() {
      sales = res;
    });
  }

  // ✅ НОВИЙ МЕТОД: Завантаження звіту про продажі
  Future<void> _loadReport() async {
    try {
      final db = DBHelper.instance;
      final report = await db.getSalesProfitReport();
      setState(() {
        salesReport = report;
      });
    } catch (e) {
      debugPrint('Error loading sales report: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Продажі'),
        backgroundColor: Colors.indigo,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ НОВЕ: Секція "Звіт Продажів"
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Звіт Продажів за Місяць 📊',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  _buildReportCard(),
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Детальні Транзакції 📋',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  // Список продажів
                  Expanded(
                    child: sales.isEmpty
                        ? const Center(child: Text('Немає продажів'))
                        : ListView.builder(
                            itemCount: sales.length,
                            itemBuilder: (context, index) {
                              final s = sales[index];
                              return ListTile(
                                leading: const Icon(Icons.shopping_cart),
                                title: Text(s['Товар'] ?? '—'),
                                subtitle: Text(
                                  'Користувач: ${s['Користувач']} | ${s['Дата_продажу']}',
                                ),
                                trailing: Text(
                                  '${(s['Сума'] as num).toStringAsFixed(2)} ₴\nК-сть: ${s['Кількість']}',
                                  textAlign: TextAlign.right,
                                ),
                                isThreeLine: true,
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  // ✅ НОВИЙ ВІДЖЕТ: Відображення звіту
  Widget _buildReportCard() {
    if (salesReport.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Text('Звіт відсутній або немає даних.'),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListView.builder(
        shrinkWrap: true, // Обмежує висоту ListView в Column
        itemCount: salesReport.length,
        itemBuilder: (context, index) {
          final report = salesReport[index];
          final month = report['Місяць'] ?? '—';
          // Безпечне приведення до double
          final totalSales =
              (report['Загальна_Сума_Продажів'] as num?)?.toStringAsFixed(2) ??
                  '0.00';
          final profit =
              (report['Прибуток'] as num?)?.toStringAsFixed(2) ?? '0.00';

          return Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text('Місяць: $month',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 3,
                  child: Text('Продажі: $totalSales ₴',
                      style: const TextStyle(
                          color: Colors.green, fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  flex: 3,
                  child: Text('Прибуток: $profit ₴',
                      style: const TextStyle(
                          color: Colors.blue, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
