import 'package:flutter/foundation.dart';

class Product {
  final String id; // Firestore document id ("" for built-in products)
  final String name;
  final String image;
  final int price;
  final int discount; // percent, 0 = no discount
  final String category;
  final String detail;

  const Product({
    this.id = "",
    required this.name,
    required this.image,
    required this.price,
    this.discount = 0,
    required this.category,
    required this.detail,
  });

  bool get hasDiscount => discount > 0;

  // price after discount, rounded to whole dollars
  int get finalPrice => (price * (100 - discount) / 100).round();

  // same field names as the admin panel writes to the "Products" collection
  factory Product.fromMap(String id, Map<String, dynamic> map) {
    return Product(
      id: id,
      name: map["Name"] ?? "",
      image: map["Image"] ?? "",
      price: (map["Price"] as num?)?.toInt() ?? 0,
      discount: (map["Discount"] as num?)?.toInt() ?? 0,
      category: map["Category"] ?? "",
      detail: map["Detail"] ?? "",
    );
  }
}

// Products the shop shows right now: the ones from the admin panel (Firestore),
// or the built-in list until the admin has added any.
final ValueNotifier<List<Product>> shopProducts = ValueNotifier<List<Product>>(builtInProducts);

Product? findProduct(String name) {
  for (Product product in shopProducts.value) {
    if (product.name == name) return product;
  }
  return null;
}


class Category {
  final String name;
  final String image;

  const Category({required this.name, required this.image});
}

const List<Category> categories = [
  Category(name: "Headphone", image: "images/headphone_icon.png"),
  Category(name: "Airpods", image: "images/airpods.png"),
  Category(name: "Earbuds", image: "images/airbads.png"),
  Category(name: "Laptop", image: "images/laptop.png"),
  Category(name: "Webcam", image: "images/webcam.png"),
  Category(name: "Watch", image: "images/watch.png"),
  Category(name: "TV", image: "images/TV.png"),
];

String _normalize(String text) {
  return text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}

// Case-insensitive search that ignores spaces and a trailing plural "s",
// so "airpods", "AIR POD" and "apple airpod " all find "Apple Airpod".
bool matchesSearch(Product product, String query) {
  String target = _normalize("${product.name} ${product.category}");
  List<String> words = query.split(RegExp(r'\s+')).map(_normalize).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return true;

  bool contains(String word) {
    if (target.contains(word)) return true;
    return word.length > 3 && word.endsWith('s') && target.contains(word.substring(0, word.length - 1));
  }

  // every word matches separately, or the whole query typed without spaces
  return words.every(contains) || contains(words.join());
}

// Built-in products, shown until the admin panel adds products to Firestore.
const List<Product> builtInProducts = [
  Product(
    name: "Headphone",
    image: "images/headphone2.png",
    price: 100,
    category: "Headphone",
    detail: "Premium over-ear headphones with deep bass, clear sound and soft ear cushions for all-day comfort. Comes with 1 year warranty.",
  ),
  Product(
    name: "JBL Live 660NC",
    image: "images/headphone.PNG",
    price: 150,
    category: "Headphone",
    detail: "Wireless over-ear headphones with adaptive noise cancelling, JBL Signature Sound and up to 50 hours of battery life.",
  ),
  Product(
    name: "Apple Airpod",
    image: "images/airpods.png",
    price: 250,
    category: "Airpods",
    detail: "Wireless earphones with active noise cancellation, easy pairing and a charging case that lasts all day.",
  ),
  Product(
    name: "Earbuds",
    image: "images/airbads.png",
    price: 20,
    category: "Earbuds",
    detail: "Compact wireless earbuds with clear sound and a pocket-size charging case. Great value for everyday use.",
  ),
  Product(
    name: "Laptop",
    image: "images/laptop2.png",
    price: 1000,
    category: "Laptop",
    detail: "A fast and lightweight laptop for work, study and entertainment. Long battery life, sharp display and 1 year warranty.",
  ),
  Product(
    name: "Webcam",
    image: "images/webcam.png",
    price: 70,
    category: "Webcam",
    detail: "Full HD webcam with built-in microphone. Perfect for video calls, online classes and streaming.",
  ),
  Product(
    name: "Apple Watch",
    image: "images/watch2.png",
    price: 300,
    category: "Watch",
    detail: "Stay connected and track your health with the Apple Watch. It has a bright always-on display, fitness tracking, heart-rate monitoring and comes with 1 year warranty.",
  ),
  Product(
    name: "Classic Leather Watch",
    image: "images/watch.png",
    price: 90,
    category: "Watch",
    detail: "A timeless analog watch with a genuine tan leather strap, scratch-resistant glass and water resistance for daily wear.",
  ),
  Product(
    name: "Smart TV 43\"",
    image: "images/tv_smart.png",
    price: 350,
    category: "TV",
    detail: "43 inch Full HD Smart TV with built-in apps, Wi-Fi and screen mirroring. A great fit for bedrooms and small living rooms.",
  ),
  Product(
    name: "4K UHD TV 55\"",
    image: "images/tv_4k.png",
    price: 550,
    category: "TV",
    detail: "55 inch 4K Ultra HD TV with HDR, vivid colors and Dolby Audio. Stream your favourite shows in stunning detail.",
  ),
  Product(
    name: "OLED TV 65\"",
    image: "images/tv_oled.png",
    price: 1200,
    category: "TV",
    detail: "65 inch OLED TV with perfect blacks, ultra-thin design and cinema-quality picture. The ultimate home theatre experience.",
  ),
];
