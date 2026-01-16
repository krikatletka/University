import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../model/product.dart';
import '../model/client.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final Client user;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.user,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int quantity = 1;
  bool adding = false;

  Future<void> _addToCart() async {
    final userId = widget.user.id;
    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Помилка: Користувач не авторизований (ID відсутній).')),
      );
      return;
    }

    setState(() => adding = true);

    try {
      // ✅ ВИПРАВЛЕНО: Використовуємо userId, який ми перевірили
      await DBHelper.instance.addToCart(
        userId,
        widget.product.id,
        qty: quantity,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.product.name} додано в кошик ($quantity шт.)',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Помилка: $e')),
      );
    } finally {
      if (mounted) setState(() => adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;

    return Scaffold(
      appBar: AppBar(
        title: Text(p.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Container(
              height: 180,
              color: Colors.grey.shade200,
              child: const Center(
                child: Icon(Icons.pets, size: 80, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              p.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Виробник: ${p.manufacturer}',
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Text(
              'Ціна: ${p.price.toStringAsFixed(2)} грн',
              style: const TextStyle(fontSize: 18, color: Colors.teal),
            ),
            const Divider(height: 30),

            // 🔹 Кількість товару
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed:
                      quantity > 1 ? () => setState(() => quantity--) : null,
                ),
                Text(
                  '$quantity',
                  style: const TextStyle(fontSize: 20),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => setState(() => quantity++),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 🔹 Кнопка "Додати в кошик"
            ElevatedButton.icon(
              icon: adding
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_shopping_cart),
              label: Text(
                adding
                    ? 'Додається...'
                    : 'Додати в кошик (${(p.price * quantity).toStringAsFixed(2)} грн)',
              ),
              onPressed: adding ? null : _addToCart,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
