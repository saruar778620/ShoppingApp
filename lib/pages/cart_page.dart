import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shoppingapp/widget/app_background.dart';
import 'package:shoppingapp/services/theme.dart';
import 'package:shoppingapp/models/product.dart';
import 'package:shoppingapp/services/cart.dart';
import 'package:shoppingapp/services/database.dart';
import 'package:shoppingapp/services/shared_pref.dart';
import 'package:shoppingapp/widget/price_tag.dart';
import 'package:shoppingapp/widget/product_image.dart';
import 'package:shoppingapp/widget/support_widget.dart';

class CartPage extends StatefulWidget {
  // called after the order is confirmed (used by the bottom bar to open the Orders tab)
  final VoidCallback? onOrderConfirmed;

  const CartPage({super.key, this.onOrderConfirmed});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool placing = false;

  void showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: error ? Colors.redAccent : Colors.green,
        content: Text(message, style: TextStyle(fontSize: 17))));
  }

  void deleteItem(CartItem item) {
    Cart.remove(item.product);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("${item.product.name} removed from cart"),
      // Flutter keeps snack bars with an action open until tapped; let this one close by itself
      persist: false,
      duration: Duration(seconds: 3),
      action: SnackBarAction(label: "UNDO", onPressed: () => Cart.add(item.product, item.quantity)),
    ));
  }

  Future<void> confirmOrder() async {
    List<CartItem> items = Cart.list;
    if (items.isEmpty) return;
    bool? ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm Order"),
        content: Text("Place an order for ${Cart.count} item(s) for a total of \$${Cart.total}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text("Confirm")),
        ],
      ),
    );
    if (ok != true) return;

    setState(() {
      placing = true;
    });
    try {
      User? user = FirebaseAuth.instance.currentUser;
      String? name = await SharedPreferenceHelper().getUserName();
      List<Map<String, dynamic>> orders = items.map((item) => {
            "UserId": user?.uid,
            "Name": name,
            "Email": user?.email,
            "Product": item.product.name,
            // uploaded pictures are too large to copy into every order
            "ProductImage": ProductImage.isUploaded(item.product.image) ? "" : item.product.image,
            "ProductId": item.product.id,
            "Price": item.product.finalPrice,
            "Discount": item.product.discount,
            "Quantity": item.quantity,
            "Total": item.total,
            "Status": "Pending",
            "CreatedAt": FieldValue.serverTimestamp(),
          }).toList();
      await DatabaseMethods().placeOrders(orders);
      Cart.clear();
      if (!mounted) return;
      showMessage("Order confirmed! See it in Current Orders");
      if (widget.onOrderConfirmed != null) {
        widget.onOrderConfirmed!();
      } else if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      showMessage("Could not place order: $e", error: true);
    } finally {
      if (mounted) {
        setState(() {
          placing = false;
        });
      }
    }
  }

  Widget cartTile(CartItem item) {
    return Container(
      margin: EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.shadow(context), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            height: 80,
            width: 80,
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.imageBox(context), borderRadius: BorderRadius.circular(12)),
            child: ProductImage(item.product.image),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                PriceText(product: item.product, fontSize: 15, quantity: item.quantity),
                SizedBox(height: 6),
                Row(
                  children: [
                    qtyButton(Icons.remove, () => Cart.setQuantity(item.product, item.quantity - 1),
                        enabled: item.quantity > 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text("${item.quantity}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    qtyButton(Icons.add, () => Cart.setQuantity(item.product, item.quantity + 1)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: "Delete",
            onPressed: () => deleteItem(item),
            icon: Icon(Icons.delete_outline, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget qtyButton(IconData icon, VoidCallback onTap, {bool enabled = true}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 28,
        width: 28,
        decoration: BoxDecoration(
          color: enabled ? AppColors.strong(context) : AppColors.textFaint(context),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: AppColors.onStrong(context)),
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
        title: Text("My Cart", style: AppWidget.boldTextFeildStyle()),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([Cart.items, shopProducts]),
        builder: (context, child) {
          List<CartItem> items = Cart.list;
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: AppColors.textFaint(context)),
                  SizedBox(height: 12),
                  Text("Your cart is empty", style: AppWidget.semiBoldTextFeildStyle()),
                  SizedBox(height: 4),
                  Text("Tap Buy now on a product to add it here", style: TextStyle(color: AppColors.textMuted(context))),
                ],
              ),
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.all(20),
                  children: items.map(cartTile).toList(),
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 20),
                decoration: BoxDecoration(
                  color: AppColors.card(context),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                  boxShadow: [BoxShadow(color: AppColors.shadow(context), blurRadius: 12, offset: Offset(0, -4))],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Total (${Cart.count} items)", style: TextStyle(fontSize: 16, color: AppColors.textMuted(context))),
                        Text("\$${Cart.total}",
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFfd6f3e))),
                      ],
                    ),
                    SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFfd6f3e),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: placing ? null : confirmOrder,
                        child: placing
                            ? SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                            : Text("Confirm Order",
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ));
  }
}
