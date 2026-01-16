import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../model/cart_item.dart';

class CartScreen extends StatefulWidget {
  final int userId;
  const CartScreen({super.key, required this.userId});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // ✅ ОНОВЛЕНО: Тепер Future повертає Map з усіма даними (кошик, сума, знижка)
  late Future<Map<String, dynamic>> _futureData;

  @override
  void initState() {
    super.initState();
    _futureData = _loadCartData();
  }

  // ✅ НОВИЙ МЕТОД: Завантаження даних кошика та розрахунок знижки
  Future<Map<String, dynamic>> _loadCartData() async {
    final items = await DBHelper.instance.getCartProducts(widget.userId);
    final isNewCustomer =
        await DBHelper.instance.isFirstPurchase(widget.userId);

    final subtotal =
        items.fold<double>(0, (sum, it) => sum + it.price * it.qty.toDouble());

    // Розрахунок знижки (10%)
    final discountRate = 0.10;
    final discount = isNewCustomer ? subtotal * discountRate : 0.0;
    final total = subtotal - discount;

    return {
      'items': items,
      'isNewCustomer': isNewCustomer,
      'subtotal': subtotal,
      'discount': discount, // Додаємо розраховану знижку
      'total': total,
    };
  }

  Future<void> _refresh() async {
    setState(() {
      _futureData = _loadCartData();
    });
  }

  Future<void> _increaseQty(CartItem item) async {
    await DBHelper.instance.updateCartQty(item.id, item.qty + 1);
    _refresh();
  }

  Future<void> _decreaseQty(CartItem item) async {
    if (item.qty > 1) {
      await DBHelper.instance.updateCartQty(item.id, item.qty - 1);
    } else {
      await DBHelper.instance.removeFromCart(item.id);
    }
    _refresh();
  }

  Future<void> _checkout() async {
    await DBHelper.instance.finalizeCartToSales(widget.userId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Оплата пройшла успішно ✅')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Кошик')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _futureData,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Помилка: ${snap.error}'));
          }

          final data = snap.data!;
          final items = data['items'] as List<CartItem>;
          final isNewCustomer = data['isNewCustomer'] as bool;
          final subtotal = data['subtotal'] as double;
          final discount = data['discount'] as double;
          final total = data['total'] as double;

          if (items.isEmpty) {
            return const Center(child: Text('Кошик порожній'));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final it = items[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        elevation: 2,
                        child: ListTile(
                          title: Text(
                            it.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Text(
                            '₴${it.price.toStringAsFixed(2)} • Кількість: ${it.qty}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => _decreaseQty(it),
                              ),
                              Text('${it.qty}',
                                  style: const TextStyle(fontSize: 16)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () => _increaseQty(it),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  await DBHelper.instance.removeFromCart(it.id);
                                  _refresh();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4)
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ✅ Відображення проміжної суми та знижки
                      if (isNewCustomer && discount > 0) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Проміжна сума:',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black54)),
                            Text('₴${subtotal.toStringAsFixed(2)}'),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Знижка нового покупця (10%):',
                                style:
                                    TextStyle(fontSize: 16, color: Colors.red)),
                            Text('- ₴${discount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Divider(),
                      ],
                      // Вивід загальної суми
                      Text(
                        'Разом до сплати: ₴${total.toStringAsFixed(2)}',
                        textAlign: isNewCustomer && discount > 0
                            ? TextAlign.left
                            : TextAlign.center,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _checkout,
                        icon: const Icon(Icons.payment),
                        label: const Text('Оплатити'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
