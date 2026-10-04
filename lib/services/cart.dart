import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoppingapp/models/product.dart';

class CartItem {
  final Product product;
  final int quantity;

  const CartItem(this.product, this.quantity);

  int get total => product.finalPrice * quantity;
}

// The shopping cart: product name -> quantity. Saved on the phone per user,
// so it is still there after the app is closed.
class Cart {
  static final ValueNotifier<Map<String, int>> items = ValueNotifier<Map<String, int>>({});
  static String _userId = "";

  static String get _key => "CART_$_userId";

  static Future<void> load(String userId) async {
    _userId = userId;
    Map<String, int> loaded = {};
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? saved = prefs.getString(_key);
      if (saved != null) {
        Map<String, dynamic> data = jsonDecode(saved);
        data.forEach((name, qty) {
          // keep every saved item: admin-panel products may not have loaded yet
          if (qty is int && qty > 0) loaded[name] = qty;
        });
      }
    } catch (e) {
      loaded = {};
    }
    items.value = loaded;
  }

  // forget the cart in memory on logout (it stays saved for that user)
  static void reset() {
    _userId = "";
    items.value = {};
  }

  static Future<void> _save() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(items.value));
    } catch (e) {
      // the cart still works for this session even if saving fails
    }
  }

  static List<CartItem> get list {
    List<CartItem> result = [];
    items.value.forEach((name, qty) {
      Product? product = findProduct(name);
      if (product != null) result.add(CartItem(product, qty));
    });
    return result;
  }

  // total number of pieces in the cart (shown on the cart badge)
  static int get count => list.fold(0, (sum, item) => sum + item.quantity);

  static int get total => list.fold(0, (sum, item) => sum + item.total);

  static void add(Product product, [int quantity = 1]) {
    Map<String, int> next = Map.of(items.value);
    next[product.name] = (next[product.name] ?? 0) + quantity;
    items.value = next;
    _save();
  }

  static void setQuantity(Product product, int quantity) {
    Map<String, int> next = Map.of(items.value);
    if (quantity <= 0) {
      next.remove(product.name);
    } else {
      next[product.name] = quantity;
    }
    items.value = next;
    _save();
  }

  static void remove(Product product) => setQuantity(product, 0);

  static void clear() {
    items.value = {};
    _save();
  }
}

class CartNavIcon extends StatelessWidget {
  const CartNavIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      // also rebuild when the shop products load, so the count includes them
      listenable: Listenable.merge([Cart.items, shopProducts]),
      builder: (context, child) {
        int count = Cart.count;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.shopping_cart_outlined, color: Colors.white),
            if (count > 0)
              Positioned(
                top: -6,
                right: -8,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      count > 9 ? "9+" : "$count",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
