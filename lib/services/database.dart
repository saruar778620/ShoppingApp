import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shoppingapp/models/product.dart';

class DatabaseMethods{
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static StreamSubscription? _productSubscription;

  // Keeps shopProducts in sync with the products added in the admin panel.
  // Falls back to the built-in products while Firestore has none (or can't be reached).
  void listenToProducts(){
    _productSubscription ??= _db
        .collection("Products")
        .orderBy("CreatedAt", descending: true)
        .snapshots()
        .listen((snapshot) {
      List<Product> list = snapshot.docs.map((doc) => Product.fromMap(doc.id, doc.data())).toList();
      shopProducts.value = list.isEmpty ? builtInProducts : list;
    }, onError: (error) {
      shopProducts.value = builtInProducts;
    });
  }

  Future addUserDetails(Map<String, dynamic> userInfoMap, String id)async{
    return await _db
        .collection("users")
        .doc(id)
        .set(userInfoMap);
  }

  Future<Map<String, dynamic>?> getUserDetails(String id)async{
    DocumentSnapshot<Map<String, dynamic>> doc = await _db
        .collection("users")
        .doc(id)
        .get();
    return doc.data();
  }

  Future updateUserName(String id, String name)async{
    return await _db
        .collection("users")
        .doc(id)
        .set({"Name": name}, SetOptions(merge: true));
  }

  Future deleteUserDetails(String id)async{
    return await _db
        .collection("users")
        .doc(id)
        .delete();
  }

  // saves several orders at once (all or nothing)
  Future placeOrders(List<Map<String, dynamic>> orders)async{
    WriteBatch batch = _db.batch();
    for (Map<String, dynamic> order in orders) {
      batch.set(_db.collection("Orders").doc(), order);
    }
    return await batch.commit();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getOrders(String userId){
    return _db
        .collection("Orders")
        .where("UserId", isEqualTo: userId)
        .snapshots();
  }
}
