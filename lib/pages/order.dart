import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shoppingapp/widget/app_background.dart';
import 'package:shoppingapp/services/theme.dart';
import 'package:shoppingapp/services/database.dart';
import 'package:shoppingapp/widget/product_image.dart';
import 'package:shoppingapp/widget/support_widget.dart';

Color statusColor(String? status) {
  switch (status) {
    case "Delivered":
      return Colors.green;
    case "Cancelled":
      return Colors.red;
    case "Pending":
      return Colors.orange;
    default:
      return Colors.blue;
  }
}

class Order extends StatefulWidget {
  const Order({super.key});

  @override
  State<Order> createState() => _OrderState();
}

class _OrderState extends State<Order> {
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  Widget orderCard(Map<String, dynamic> order) {
    String image = order["ProductImage"] ?? "";
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          image.isEmpty
              ? Icon(Icons.shopping_bag_outlined, size: 80)
              : ProductImage(image, height: 80, width: 80),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order["Product"] ?? "", style: AppWidget.semiBoldTextFeildStyle()),
                SizedBox(height: 5),
                Text(
                  "Qty: ${order["Quantity"] ?? 1}   Total: \$${order["Total"] ?? order["Price"] ?? 0}",
                  style: TextStyle(
                    color: Color(0xFFfd6f3e),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  "Status: ${order["Status"] ?? ""}",
                  style: TextStyle(color: statusColor(order["Status"]), fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text("Current Orders", style: AppWidget.boldTextFeildStyle()),
      ),
      body: userId == null
          ? Center(child: Text("Please login to see your orders", style: AppWidget.lightTextFeildStyle()))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: DatabaseMethods().getOrders(userId!),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Something went wrong", style: AppWidget.lightTextFeildStyle()));
                }
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                List<Map<String, dynamic>> orders = snapshot.data!.docs.map((doc) => doc.data()).toList();
                // newest order first
                orders.sort((a, b) {
                  Timestamp? timeA = a["CreatedAt"];
                  Timestamp? timeB = b["CreatedAt"];
                  if (timeA == null || timeB == null) return 0;
                  return timeB.compareTo(timeA);
                });
                if (orders.isEmpty) {
                  return Center(child: Text("No orders yet", style: AppWidget.lightTextFeildStyle()));
                }
                return ListView.builder(
                  padding: EdgeInsets.all(20),
                  itemCount: orders.length,
                  itemBuilder: (context, index) => orderCard(orders[index]),
                );
              },
            ),
    ));
  }
}
