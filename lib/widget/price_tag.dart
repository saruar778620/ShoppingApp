import 'package:flutter/material.dart';
import 'package:shoppingapp/services/theme.dart';
import 'package:shoppingapp/models/product.dart';

class DiscountTag extends StatelessWidget {
  final int discount;
  final double fontSize;

  const DiscountTag({super.key, required this.discount, this.fontSize = 10});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: fontSize * 0.7, vertical: fontSize * 0.3),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(fontSize),
      ),
      child: Text(
        "-$discount%",
        style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// Final price, plus the old price crossed out when the product has a discount.
class PriceText extends StatelessWidget {
  final Product product;
  final double fontSize;
  final int quantity;

  const PriceText({super.key, required this.product, this.fontSize = 16, this.quantity = 1});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          "\$${product.finalPrice * quantity}",
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Color(0xFFfd6f3e),
          ),
        ),
        if (product.hasDiscount) ...[
          SizedBox(width: 5),
          Text(
            "\$${product.price * quantity}",
            style: TextStyle(
              fontSize: fontSize * 0.7,
              color: AppColors.textFaint(context),
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ],
      ],
    );
  }
}
