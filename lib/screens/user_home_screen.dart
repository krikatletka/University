import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../model/client.dart';
import '../model/product.dart';
import '../model/animal.dart';
import '../model/category.dart';
import '../model/subcategory.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart';
import 'login_screen.dart'; // ✅ ДОДАНО: Імпорт LoginScreen

class UserHomeScreen extends StatefulWidget {
  final Client user;
  const UserHomeScreen({super.key, required this.user});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final db = DBHelper.instance;

  List<Product> _products = [];
  List<Animal> _animals = [];
  List<Category> _categories = [];
  List<Subcategory> _subcategories = [];

  // ✅ НОВЕ: Контролер для поля пошуку
  final TextEditingController _searchController = TextEditingController();
  String _currentSearchQuery = '';

  int? _selectedAnimal;
  int? _selectedCategory;
  int? _selectedSubcategory;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    // ✅ НОВЕ: Додаємо слухача для поля пошуку
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // ✅ НОВИЙ МЕТОД: Обробник зміни рядка пошуку
  void _onSearchChanged() {
    // Викликаємо _filterProducts() тільки якщо запит змінився
    if (_currentSearchQuery != _searchController.text.trim()) {
      _currentSearchQuery = _searchController.text.trim();
      _filterProducts();
    }
  }

  Future<void> _loadInitialData() async {
    final animals = await db.getAllAnimals();
    final categories = await db.getAllCategories();
    final subcats = await db.getAllSubcategories();

    // Завантажуємо всі товари (або тільки якщо пошук/фільтри порожні)
    final products = await db.getAllProducts();

    setState(() {
      _animals = animals;
      _categories = categories;
      _subcategories = subcats;
      _products = products;
      _loading = false;
    });
  }

  // ОНОВЛЕНО: Тепер фільтрація/пошук об'єднані
  Future<void> _filterProducts() async {
    setState(() => _loading = true);

    // 1. Якщо є текст у полі пошуку, використовуємо текстовий пошук
    if (_currentSearchQuery.isNotEmpty) {
      final res = await db.searchProducts(_currentSearchQuery);
      setState(() {
        _products = res;
        _loading = false;
      });
      return;
    }

    // 2. Якщо пошук порожній, використовуємо Dropdown фільтри
    final res = await db.getFilteredProducts(
      animalId: _selectedAnimal,
      categoryId: _selectedCategory,
      subcategoryId: _selectedSubcategory,
    );

    // Якщо всі Dropdown'и null, getFilteredProducts поверне всі товари,
    // що еквівалентно getAllProducts
    setState(() {
      _products = res;
      _loading = false;
    });
  }

  void _openCart() {
    final userId = widget.user.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Помилка: Користувач не авторизований (ID відсутній).')));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CartScreen(userId: userId)),
    );
  }

  Future<void> _addToCart(Product p) async {
    final userId = widget.user.id;
    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Помилка: Користувач не авторизований (ID відсутній).')));
      return;
    }

    await db.addToCart(userId, p.id);

    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('${p.name} додано в кошик')));
  }

  // ✅ НОВИЙ МЕТОД: Вихід з облікового запису
  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) =>
          false, // Запобігає поверненню на попередні екрани
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required List<T> items,
    required int? selectedId,
    required String Function(T) getName,
    required int? Function(T) getId,
    required ValueChanged<int?> onChanged,
  }) {
    return DropdownButtonFormField<int>(
      initialValue: selectedId,
      hint: Text(label),
      isExpanded: true,
      items: [
        const DropdownMenuItem<int>(value: null, child: Text('Усі')),
        ...items.map((e) => DropdownMenuItem<int>(
              value: getId(e),
              child: Text(getName(e)),
            ))
      ],
      onChanged: (id) {
        onChanged(id);
        // ✅ НОВЕ: Скидаємо пошуковий рядок при зміні фільтра
        _searchController.clear();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text('Зоомагазин (${widget.user.name})'), // Додамо ім'я користувача
        actions: [
          IconButton(
            onPressed: _openCart,
            icon: const Icon(Icons.shopping_cart),
          ),
          // ✅ НОВА КНОПКА ВИХОДУ
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadInitialData,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    // ✅ НОВЕ: Поле пошуку
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Пошук товарів, виробників, тварин...',
                          prefixIcon: const Icon(Icons.search),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              // _onSearchChanged викличе _filterProducts()
                            },
                          ),
                        ),
                      ),
                    ),

                    // Dropdown фільтри відображаємо, якщо немає активного пошуку
                    if (_currentSearchQuery.isEmpty) ...[
                      _buildDropdown<Animal>(
                        label: 'Тварини',
                        items: _animals,
                        selectedId: _selectedAnimal,
                        getName: (a) => a.name,
                        getId: (a) => a.id,
                        onChanged: (id) {
                          setState(() => _selectedAnimal = id);
                          _filterProducts();
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildDropdown<Category>(
                        label: 'Категорії',
                        items: _categories,
                        selectedId: _selectedCategory,
                        getName: (c) => c.name,
                        getId: (c) => c.id,
                        onChanged: (id) {
                          setState(() => _selectedCategory = id);
                          _filterProducts();
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildDropdown<Subcategory>(
                        label: 'Підкатегорії',
                        items: _subcategories,
                        selectedId: _selectedSubcategory,
                        getName: (s) => s.name,
                        getId: (s) => s.id,
                        onChanged: (id) {
                          setState(() => _selectedSubcategory = id);
                          _filterProducts();
                        },
                      ),
                      const Divider(),
                    ],

                    Expanded(
                      child: _products.isEmpty
                          ? Center(
                              child: Text(_currentSearchQuery.isNotEmpty
                                  ? 'Нічого не знайдено за запитом "$_currentSearchQuery"'
                                  : 'Немає товарів'))
                          : ListView.builder(
                              itemCount: _products.length,
                              itemBuilder: (_, i) {
                                final p = _products[i];
                                return Card(
                                  child: ListTile(
                                    title: Text(p.name),
                                    subtitle: Text(
                                        '₴${p.sellPrice.toStringAsFixed(2)}'),
                                    onTap: () {
                                      final userId = widget.user.id;
                                      if (userId == null) {
                                        // Якщо неавторизований, не даємо додати в кошик, але деталі показуємо
                                      }
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ProductDetailScreen(
                                            product: p,
                                            user: widget.user,
                                          ),
                                        ),
                                      );
                                    },
                                    trailing: IconButton(
                                      icon: const Icon(Icons.add_shopping_cart),
                                      onPressed: () => _addToCart(p),
                                    ),
                                  ),
                                );
                              },
                            ),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}
