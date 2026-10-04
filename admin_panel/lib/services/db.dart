import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:admin_panel/models/product.dart';

// All reads/writes the admin panel does. Collection and field names match the shopping app.
class Db {
  static FirebaseFirestore? _testInstance;
  static FirebaseFirestore get _db => _testInstance ?? FirebaseFirestore.instance;

  // tests use an in-memory Firestore instead of the real one
  static void useForTests(FirebaseFirestore firestore) => _testInstance = firestore;

  // ---------- products ----------

  static Stream<List<Product>> products() {
    return _db
        .collection("Products")
        .orderBy("CreatedAt", descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Product.fromMap(d.id, d.data())).toList());
  }

  static Future<void> addProduct(Product product) {
    return _db.collection("Products").add({...product.toMap(), "CreatedAt": FieldValue.serverTimestamp()});
  }

  static Future<void> updateProduct(Product product) {
    return _db.collection("Products").doc(product.id).update(product.toMap());
  }

  static Future<void> deleteProduct(String id) {
    return _db.collection("Products").doc(id).delete();
  }

  // copies the shopping app's built-in products so they can be edited here
  static Future<void> importBuiltInProducts() {
    WriteBatch batch = _db.batch();
    for (Product product in builtInProducts.reversed) {
      batch.set(_db.collection("Products").doc(), {...product.toMap(), "CreatedAt": FieldValue.serverTimestamp()});
    }
    return batch.commit();
  }

  // ---------- orders ----------

  static Stream<QuerySnapshot<Map<String, dynamic>>> orders() {
    return _db.collection("Orders").orderBy("CreatedAt", descending: true).snapshots();
  }

  static Future<void> setOrderStatus(String id, String status) {
    return _db.collection("Orders").doc(id).update({"Status": status});
  }

  static Future<void> deleteOrder(String id) {
    return _db.collection("Orders").doc(id).delete();
  }

  // ---------- users ----------

  static Stream<QuerySnapshot<Map<String, dynamic>>> users() {
    return _db.collection("users").snapshots();
  }
}
