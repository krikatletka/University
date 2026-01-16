import 'package:flutter/material.dart';
import '../db/database_helper.dart';

// ✅ НОВИЙ ТИП: Для визначення поточного сортування
enum ProductSortType {
  defaultAll, // За замовчуванням (SELECT * FROM Товар)
  expiryDate, // Сортування за терміном придатності
  stockQuantity // Сортування за кількістю на складі
}

class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({super.key});

  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  List<Map<String, dynamic>> products = [];
  ProductSortType _currentSort =
      ProductSortType.defaultAll; // Сортування за замовчуванням
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadProducts(sort: _currentSort);
  }

  // ОНОВЛЕНО: Основний метод завантаження/фільтрації
  Future<void> _loadProducts({ProductSortType? sort}) async {
    setState(() {
      _loading = true;
      if (sort != null) {
        _currentSort = sort;
      }
    });

    final db = DBHelper.instance;
    List<Map<String, dynamic>> res = [];

    try {
      switch (_currentSort) {
        case ProductSortType.expiryDate:
          res = await db.getProductsSortedByExpiry();
          break;
        case ProductSortType.stockQuantity:
          res = await db.getProductsSortedByStock();
          break;
        case ProductSortType.defaultAll:
        default:
          final database = await db.database;
          res = await database.rawQuery('SELECT * FROM Товар');
          break;
      }
    } catch (e) {
      debugPrint('Error loading products: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Помилка завантаження товарів: $e')),
      );
    }

    setState(() {
      products = res;
      _loading = false;
    });
  }

  Future<void> _deleteProduct(int id) async {
    final db = DBHelper.instance;
    final database = await db.database;
    await database.delete('Товар', where: 'ID_Товару = ?', whereArgs: [id]);
    _loadProducts(sort: _currentSort);
  }

  // =========================================================================
  // МЕТОД ДЛЯ ДОБАВЛЕНИЯ/РЕДАКТИРОВАНИЯ (ПОЛНОЕ ЗАПОЛНЕНИЕ ВСЕХ ПОЛЕЙ)
  // =========================================================================
  Future<void> _showEditDialog({Map<String, dynamic>? product}) async {
    // 1. Создание контроллеров с начальными данными
    final nameController = TextEditingController(text: product?['Назва'] ?? '');
    final manufacturerController =
        TextEditingController(text: product?['Виробник'] ?? '');
    final purchasePriceController = TextEditingController(
        text: (product?['Ціна_закупки'] as num?)?.toString() ?? '');
    final salePriceController = TextEditingController(
        text: (product?['Ціна_продажу'] as num?)?.toString() ?? '');
    final expiryDateController = TextEditingController(
        text: product?['Термін_придатності']?.toString() ?? '');
    final animalIdController = TextEditingController(
        text: (product?['ID_Тварини'] as num?)?.toString() ?? '');
    final categoryIdController = TextEditingController(
        text: (product?['ID_Категорії'] as num?)?.toString() ?? '');
    final subcategoryIdController = TextEditingController(
        text: (product?['ID_Підкатегорії'] as num?)?.toString() ?? '');
    final supplierIdController = TextEditingController(
        text: (product?['ID_Постачальника'] as num?)?.toString() ?? '');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(product == null ? 'Додати товар' : 'Редагувати товар'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Назва
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Назва'),
                ),
                // 2. Виробник
                TextField(
                  controller: manufacturerController,
                  decoration: const InputDecoration(labelText: 'Виробник'),
                ),
                // 3. Ціна_закупки (REAL)
                TextField(
                  controller: purchasePriceController,
                  decoration: const InputDecoration(labelText: 'Ціна закупки'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                // 4. Ціна_продажу (REAL)
                TextField(
                  controller: salePriceController,
                  decoration: const InputDecoration(labelText: 'Ціна продажу'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                // 5. Термін_придатності (DATE)
                TextField(
                  controller: expiryDateController,
                  decoration: const InputDecoration(
                      labelText: 'Термін придатності (YYYY-MM-DD)'),
                ),
                // 6. ID_Тварини (INTEGER)
                TextField(
                  controller: animalIdController,
                  decoration: const InputDecoration(labelText: 'ID Тварини'),
                  keyboardType: TextInputType.number,
                ),
                // 7. ID_Категорії (INTEGER)
                TextField(
                  controller: categoryIdController,
                  decoration: const InputDecoration(labelText: 'ID Категорії'),
                  keyboardType: TextInputType.number,
                ),
                // 8. ID_Підкатегорії (INTEGER)
                TextField(
                  controller: subcategoryIdController,
                  decoration:
                      const InputDecoration(labelText: 'ID Підкатегорії'),
                  keyboardType: TextInputType.number,
                ),
                // 9. ID_Постачальника (INTEGER)
                TextField(
                  controller: supplierIdController,
                  decoration:
                      const InputDecoration(labelText: 'ID Постачальника'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Скасувати'),
          ),
          ElevatedButton(
            onPressed: () async {
              // 2. Сбор и валидация данных
              final name = nameController.text;
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Назва не може бути порожньою.')));
                return;
              }

              final db = DBHelper.instance;
              final database = await db.database;

              // 3. Формирование Map
              final data = {
                'Назва': name,
                'Виробник': manufacturerController.text.isEmpty
                    ? null
                    : manufacturerController.text,

                // Ценовые поля
                'Ціна_закупки':
                    double.tryParse(purchasePriceController.text) ?? 0.0,
                'Ціна_продажу':
                    double.tryParse(salePriceController.text) ?? 0.0,

                // Дата
                'Термін_придатності': expiryDateController.text.isEmpty
                    ? null
                    : expiryDateController.text,

                // Поля ID (ID_Тварини, ID_Категорії, ID_Підкатегорії, ID_Постачальника)
                'ID_Тварини': int.tryParse(animalIdController.text),
                'ID_Категорії': int.tryParse(categoryIdController.text),
                'ID_Підкатегорії': int.tryParse(subcategoryIdController.text),
                'ID_Постачальника': int.tryParse(supplierIdController.text),
              };

              // 4. INSERT или UPDATE
              try {
                if (product == null) {
                  await database.insert('Товар', data);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Товар успішно додано.')),
                  );
                } else {
                  await database.update('Товар', data,
                      where: 'ID_Товару = ?',
                      whereArgs: [product['ID_Товару']]);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Товар успішно оновлено.')),
                  );
                }
                Navigator.pop(context);
                _loadProducts(sort: _currentSort);
              } catch (e) {
                debugPrint('Save error: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Помилка збереження: $e')));
              }
            },
            child: const Text('Зберегти'),
          ),
        ],
      ),
    );
  }
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Керування товарами'),
        backgroundColor: Colors.indigo,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ✅ НОВЕ: Панель сортування
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSortButton(
                        label: 'За замовчуванням',
                        type: ProductSortType.defaultAll,
                      ),
                      _buildSortButton(
                        label: 'Термін придатності',
                        type: ProductSortType.expiryDate,
                      ),
                      _buildSortButton(
                        label: 'Кількість на складі',
                        type: ProductSortType.stockQuantity,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: products.isEmpty
                      ? const Center(child: Text('Немає товарів'))
                      : ListView.builder(
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final p = products[index];
                            return ListTile(
                              leading: const Icon(Icons.shopping_bag),
                              title: Text(p['Назва'] ?? ''),
                              // Оновлюємо subtitle залежно від сортування
                              subtitle: Text(
                                _currentSort == ProductSortType.expiryDate
                                    ? 'Термін: ${p['Термін_придатності'] ?? '—'} | Продаж: ${(p['Ціна_продажу'] as num).toStringAsFixed(2)} ₴'
                                    : _currentSort ==
                                            ProductSortType.stockQuantity
                                        ? 'Кількість: ${p['Кількість'] ?? '—'} | Місто: ${p['Місто'] ?? '—'} | Позиція: ${p['Номер_позиції'] ?? '—'}'
                                        : 'Продаж: ${(p['Ціна_продажу'] as num).toStringAsFixed(2)} ₴ | Закупка: ${(p['Ціна_закупки'] as num).toStringAsFixed(2)} ₴\nID Категорії: ${p['ID_Категорії'] ?? '—'} | ID Тварини: ${p['ID_Тварини'] ?? '—'}',
                              ),
                              isThreeLine: true,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.orange),
                                    onPressed: () =>
                                        _showEditDialog(product: p),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () =>
                                        _deleteProduct(p['ID_Товару']),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        onPressed: () => _showEditDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  // ✅ НОВИЙ ВІДЖЕТ: Кнопка сортування
  Widget _buildSortButton({
    required String label,
    required ProductSortType type,
  }) {
    final isSelected = _currentSort == type;
    return TextButton(
      onPressed: () => _loadProducts(sort: type),
      style: TextButton.styleFrom(
        foregroundColor: isSelected ? Colors.white : Colors.indigo.shade700,
        backgroundColor: isSelected ? Colors.indigo : Colors.indigo.shade50,
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}
