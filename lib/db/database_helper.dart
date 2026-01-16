import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';

import '../model/client.dart';
import '../model/product.dart';
import '../model/cart_item.dart';
import '../model/animal.dart';
import '../model/category.dart';
import '../model/subcategory.dart';

class DBHelper {
  DBHelper._private();
  static final DBHelper instance = DBHelper._private();
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB('zoo_new.db');
    return _db!;
  }

  // -------------------- ІНІЦІАЛІЗАЦІЯ --------------------
  Future<Database> _initDB(String fileName) async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final dbPath = await databaseFactory.getDatabasesPath();
    final path = join(dbPath, fileName);

    try {
      final data = await rootBundle.load('assets/db/$fileName');
      final bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await Directory(dirname(path)).create(recursive: true);
      await File(path).writeAsBytes(bytes, flush: true);
      print('✅ Базу даних скопійовано з assets/db/$fileName');
    } catch (e) {
      print('⚠️ Помилка копіювання бази: $e');
      await Directory(dirname(path)).create(recursive: true);
      await File(path).create();
    }

    final db = await databaseFactory.openDatabase(path);

    // створюємо додаткові таблиці, якщо треба
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Cart (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        productId INTEGER,
        qty INTEGER DEFAULT 1
      );
    ''');

    // =========================================================================
    // ✅ СТВОРЕННЯ ТРИГЕРА ЗНИЖКИ
    // =========================================================================
    await db.execute('''
      DROP TRIGGER IF EXISTS Знижка_Новому;
    ''');
    await db.execute('''
      CREATE TRIGGER Знижка_Новому
      BEFORE INSERT ON Продаж
      FOR EACH ROW
      WHEN (SELECT COUNT(ID_Продажу) FROM Продаж WHERE ID_Клієнта = NEW.ID_Клієнта) = 0
      BEGIN
          SELECT NEW.Сума = ROUND(NEW.Сума * 0.9, 2);
      END;
    ''');

    // =========================================================================
    // ✅ СТВОРЕННЯ VIEW (ВИКОРИСТОВУЮЧИ НАДАНІ ТОЧНІ ЗАПИТИ)
    // =========================================================================

    // 1. Активні Покупці (Мають 2+ покупки)
    await db.execute('''
      DROP VIEW IF EXISTS Активні_Покупці;
    ''');
    await db.execute('''
      CREATE VIEW Активні_Покупці AS
      SELECT 
          k.Прізвище || ' ' || k.Імя AS Покупець,
          k.Email,
          COUNT(p.ID_Продажу) AS Кількість_Покупок,
          SUM(p.Сума) AS Витрачено
      FROM Продаж p
      JOIN Користувач k ON p.ID_Клієнта = k.ID_Користувача
      GROUP BY k.ID_Користувача
      HAVING COUNT(p.ID_Продажу) >= 2
      ORDER BY Витрачено DESC;
    ''');

    // 2. Пошук Товарів (Створюємо VIEW без секції WHERE)
    await db.execute('''
      DROP VIEW IF EXISTS Пошук_Товарів;
    ''');
    await db.execute('''
      CREATE VIEW Пошук_Товарів AS 
      SELECT DISTINCT
          t.ID_Товару,
          t.Назва,
          t.Виробник,
          t.Ціна_продажу,
          tv.Назва AS Тварина,
          k.Назва AS Категорія,
          p.Назва AS Підкатегорія
      FROM Товар t
      LEFT JOIN Тварина tv ON t.ID_Тварини = tv.ID_Тварини
      LEFT JOIN Категорія k ON t.ID_Категорії = k.ID_Категорії
      LEFT JOIN Підкатегорія p ON t.ID_Підкатегорії = p.ID_Підкатегорії;
    ''');

    // 3. Звіт Продажів (Створюємо VIEW для звіту)
    await db.execute('''
      DROP VIEW IF EXISTS Звіт_Продажів;
    ''');
    await db.execute('''
      CREATE VIEW Звіт_Продажів AS
      SELECT 
          strftime('%Y-%m', p.Дата_продажу) AS Місяць,
          SUM(p.Сума) AS Загальна_Сума_Продажів,
          SUM((t.Ціна_продажу - t.Ціна_закупки) * p.Кількість) AS Прибуток
      FROM Продаж p
      JOIN Товар t ON p.ID_Товару = t.ID_Товару
      GROUP BY strftime('%Y-%m', p.Дата_продажу)
      ORDER BY Місяць DESC;
    ''');
    // =========================================================================

    print('📂 Підключено до бази: $path');
    return db;
  }

  // ---------------- USERS ----------------
  Future<Client?> login(String login, String password) async {
    final db = await database;
    final res = await db.query(
      'Користувач',
      where: 'Логін = ? AND Пароль = ?',
      whereArgs: [login, password],
      limit: 1,
    );
    return res.isNotEmpty ? Client.fromMap(res.first) : null;
  }

  Future<int> register(Client client) async {
    final db = await database;
    final map = client.toMap()..remove('ID_Користувача');
    return await db.insert('Користувач', map);
  }

  // ✅ НОВИЙ МЕТОД: Отримання ID активних клієнтів
  Future<Set<int>> getActiveClientIds() async {
    final db = await database;
    final res = await db.rawQuery('''
      SELECT k.ID_Користувача 
      FROM Користувач k 
      JOIN Продаж p ON k.ID_Користувача = p.ID_Клієнта
      GROUP BY k.ID_Користувача
      HAVING COUNT(p.ID_Продажу) >= 2
    ''');

    return res.map((row) => row['ID_Користувача'] as int).toSet();
  }

  // ---------------- PRODUCTS ----------------
  Future<List<Product>> getAllProducts() async {
    final db = await database;
    // Використовуємо звичайну таблицю, якщо не задано пошук
    final res = await db.query('Товар');
    return res.map((m) => Product.fromMap(m)).toList();
  }

  // ✅ НОВИЙ МЕТОД: Пошук по VIEW "Пошук_Товарів"
  Future<List<Product>> searchProducts(String query) async {
    if (query.isEmpty) {
      return getAllProducts();
    }

    final db = await database;
    final searchKey = '%${query.trim()}%';

    final res = await db.rawQuery('''
      SELECT * FROM Пошук_Товарів 
      WHERE 
          Назва LIKE ? 
          OR Виробник LIKE ?
          OR Тварина LIKE ? 
          OR Категорія LIKE ? 
          OR Підкатегорія LIKE ?
    ''', [searchKey, searchKey, searchKey, searchKey, searchKey]);

    return res.map((m) => Product.fromMap(m)).toList();
  }

  Future<int> addProduct(Product product) async {
    final db = await database;
    final map = product.toMap()..remove('ID_Товару');
    return await db.insert('Товар', map);
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    return await db.update(
      'Товар',
      product.toMap(),
      where: 'ID_Товару = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete('Товар', where: 'ID_Товару = ?', whereArgs: [id]);
  }

  Future<List<Product>> getFilteredProducts({
    int? animalId,
    int? categoryId,
    int? subcategoryId,
  }) async {
    final db = await database;
    final whereParts = <String>[];
    final args = <Object?>[];

    if (animalId != null) {
      whereParts.add('ID_Тварини = ?');
      args.add(animalId);
    }
    if (categoryId != null) {
      whereParts.add('ID_Категорії = ?');
      args.add(categoryId);
    }
    if (subcategoryId != null) {
      whereParts.add('ID_Підкатегорії = ?');
      args.add(subcategoryId);
    }

    final whereClause = whereParts.isEmpty ? null : whereParts.join(' AND ');
    final res = await db.query('Товар', where: whereClause, whereArgs: args);
    return res.map((m) => Product.fromMap(m)).toList();
  }

  // ✅ НОВИЙ МЕТОД: Отримати товари, відсортовані за терміном придатності
  Future<List<Map<String, dynamic>>> getProductsSortedByExpiry() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT ID_Товару, Назва, Виробник, Термін_придатності, Ціна_продажу, Ціна_закупки, ID_Категорії, ID_Тварини
      FROM Товар
      ORDER BY Термін_придатності ASC;
    ''');
  }

  // ✅ НОВИЙ МЕТОД: Отримати товари, відсортовані за кількістю на складі
  Future<List<Map<String, dynamic>>> getProductsSortedByStock() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT t.ID_Товару, t.Назва, s.Кількість, s.Місто, s.Номер_позиції, t.Ціна_продажу, t.Ціна_закупки, t.ID_Категорії, t.ID_Тварини
      FROM Склад s
      JOIN Товар t ON s.ID_Товару = t.ID_Товару
      ORDER BY s.Кількість ASC;
    ''');
  }

  // ---------------- CART ----------------
  Future<int> addToCart(int userId, int productId, {int qty = 1}) async {
    final db = await database;
    final existing = await db.query(
      'Cart',
      where: 'userId = ? AND productId = ?',
      whereArgs: [userId, productId],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      final id = existing.first['id'] as int;
      final currentQty = (existing.first['qty'] as int?) ?? 1;
      return await db.update('Cart', {'qty': currentQty + qty},
          where: 'id = ?', whereArgs: [id]);
    } else {
      return await db.insert(
          'Cart', {'userId': userId, 'productId': productId, 'qty': qty});
    }
  }

  Future<void> updateCartQty(int id, int qty) async {
    final db = await database;
    await db.update('Cart', {'qty': qty}, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<CartItem>> getCartProducts(int userId) async {
    final db = await database;
    final res = await db.rawQuery('''
      SELECT c.id, c.userId, c.productId, c.qty,
             t.Назва AS name, t."Ціна_продажу" AS price
      FROM Cart c
      JOIN Товар t ON t.ID_Товару = c.productId
      WHERE c.userId = ?
    ''', [userId]);
    return res.map((m) => CartItem.fromMap(m)).toList();
  }

  Future<int> removeFromCart(int id) async {
    final db = await database;
    return await db.delete('Cart', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearCartForUser(int userId) async {
    final db = await database;
    await db.delete('Cart', where: 'userId = ?', whereArgs: [userId]);
  }

  // ✅ НОВИЙ МЕТОД: Перевірка, чи це перша покупка клієнта
  Future<bool> isFirstPurchase(int userId) async {
    final db = await database;
    // Шукаємо будь-які записи для цього клієнта у таблиці Продаж
    final res = await db.query(
      'Продаж',
      where: 'ID_Клієнта = ?',
      whereArgs: [userId],
      limit: 1,
    );
    // Якщо результатів немає (res.isEmpty), це перша покупка (true)
    return res.isEmpty;
  }

  // ---------------- SALES ----------------
  Future<void> finalizeCartToSales(int userId) async {
    final db = await database;
    final cart =
        await db.query('Cart', where: 'userId = ?', whereArgs: [userId]);

    await db.transaction((txn) async {
      for (final row in cart) {
        final prodId = row['productId'] as int;
        final qty = (row['qty'] as int?) ?? 1;

        final product = (await txn.query('Товар',
                where: 'ID_Товару = ?', whereArgs: [prodId], limit: 1))
            .first;
        final price = (product['Ціна_продажу'] as num?)?.toDouble() ?? 0.0;

        // Тригер "Знижка_Новому" спрацює ТУТ, якщо це перша транзакція,
        // і автоматично скоригує Суму
        await txn.insert('Продаж', {
          'ID_Клієнта': userId,
          'ID_Товару': prodId,
          'Кількість': qty,
          'Дата_продажу': DateTime.now().toIso8601String(),
          'Сума': price * qty,
        });
      }
      await txn.delete('Cart', where: 'userId = ?', whereArgs: [userId]);
    });
  }

  // ✅ НОВИЙ МЕТОД: Отримати звіт про продажі та прибуток
  Future<List<Map<String, dynamic>>> getSalesProfitReport() async {
    final db = await database;
    return await db.rawQuery('SELECT * FROM Звіт_Продажів;');
  }

  // ---------------- CATEGORIES ----------------
  Future<List<Category>> getAllCategories() async {
    final db = await database;
    final res = await db.query('Категорія');
    return res.map((m) => Category.fromMap(m)).toList();
  }

  // ---------------- SUBCATEGORIES ----------------
  Future<List<Subcategory>> getAllSubcategories() async {
    final db = await database;
    final res = await db.query('Підкатегорія');
    return res.map((m) => Subcategory.fromMap(m)).toList();
  }

  // ---------------- ANIMALS ----------------
  Future<List<Animal>> getAllAnimals() async {
    final db = await database;
    final res = await db.query('Тварина');
    return res.map((m) => Animal.fromMap(m)).toList();
  }
}
