import 'package:flutter/material.dart';
import 'package:shoppingapp/models/product.dart';
import 'package:shoppingapp/pages/cart_page.dart';
import 'package:shoppingapp/services/cart.dart';
import 'package:shoppingapp/services/theme.dart';
import 'package:shoppingapp/widget/price_tag.dart';
import 'package:shoppingapp/widget/product_image.dart';
import 'package:shoppingapp/widget/support_widget.dart';

class ProductDetaile extends StatefulWidget {
  final Product product;

  const ProductDetaile({super.key, required this.product});

  @override
  State<ProductDetaile> createState() => _ProductDetaileState();
}

class _ProductDetaileState extends State<ProductDetaile> {
  int quantity = 1;

  // Buy now puts the product in the cart; the order is confirmed from the cart.
  void buyNow() {
    Cart.add(widget.product, quantity);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const CartPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    Product product = widget.product;
    return Scaffold(
      // light "stage" behind the product picture in both modes, so dark products stay visible
      backgroundColor: AppColors.isDark(context) ? AppColors.imageBox(context) : Color(0xFFfef5f1),
      body: Container(
        padding: EdgeInsets.only(top: 50,),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Center(child: ProductImage(product.image, height: MediaQuery.of(context).size.height * 0.4)),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: EdgeInsets.only(left: 20.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.arrow_back_ios_new_outlined, color: Colors.black),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.only(top: 20,left: 20,right: 20),
                decoration: BoxDecoration(
                  color: AppColors.card(context),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(20),topRight: Radius.circular(20))
                ),
                width: MediaQuery.of(context).size.width,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(product.name, style: AppWidget.boldTextFeildStyle(),)),
                          PriceText(product: product, fontSize: 22),
                        ],
                      ),
                      if (product.hasDiscount) ...[
                        SizedBox(height: 8,),
                        Row(
                          children: [
                            DiscountTag(discount: product.discount, fontSize: 13),
                            SizedBox(width: 8,),
                            Text("You save \$${product.price - product.finalPrice}",
                                style: TextStyle(color: Colors.green, fontSize: 15, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                      SizedBox(height: 20,),
                      Text('Details',style: AppWidget.semiBoldTextFeildStyle(),),
                      SizedBox(height: 10,),
                      Text(product.detail, style: TextStyle(fontSize: 16, color: AppColors.textMuted(context))),
                      SizedBox(height: 30,),
                      Row(
                        children: [
                          Text('Quantity',style: AppWidget.semiBoldTextFeildStyle(),),
                          Spacer(),
                          IconButton(
                            onPressed: quantity > 1 ? () => setState(() => quantity--) : null,
                            icon: Icon(Icons.remove_circle_outline),
                          ),
                          Text('$quantity', style: AppWidget.semiBoldTextFeildStyle()),
                          IconButton(
                            onPressed: () => setState(() => quantity++),
                            icon: Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                      SizedBox(height: 10,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total', style: AppWidget.semiBoldTextFeildStyle()),
                          PriceText(product: product, fontSize: 22, quantity: quantity),
                        ],
                      ),
                      SizedBox(height: 30,),
                      GestureDetector(
                        onTap: buyNow,
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 15),
                          decoration: BoxDecoration(
                            color: Color(0xFFfd6f3e),
                            borderRadius: BorderRadius.circular(10)
                          ),
                          width:MediaQuery.of(context).size.width,
                          child: Center(
                            child: Text('Buy now',style: TextStyle(color: Colors.white,fontSize: 20,fontWeight: FontWeight.bold),),
                          ),
                        ),
                      ),
                      SizedBox(height: 20,),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
