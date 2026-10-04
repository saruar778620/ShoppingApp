import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:shoppingapp/services/theme.dart';
import 'package:shoppingapp/pages/cart_page.dart';
import 'package:shoppingapp/pages/order.dart';
import 'package:shoppingapp/pages/home.dart';
import 'package:shoppingapp/pages/profile.dart';
import 'package:shoppingapp/services/cart.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  final GlobalKey<CurvedNavigationBarState> navKey = GlobalKey<CurvedNavigationBarState>();
  late final List<Widget> pages;
  int currentTapIndex = 0;

  @override
  void initState() {
    super.initState();
    pages = [
      const Home(),
      // after confirming the cart, jump to the Orders tab
      CartPage(onOrderConfirmed: () => navKey.currentState?.setPage(2)),
      const Order(),
      const Profile(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CurvedNavigationBar(
        key: navKey,
        height: 65,
        backgroundColor: AppColors.background(context),
        color: AppColors.navBar(context),
        animationDuration: const Duration(milliseconds: 500),
        onTap: (int index) {
          setState(() {
            currentTapIndex = index;
          });
        },
        items: const [
          Icon(Icons.home_outlined, color: Colors.white),
          CartNavIcon(),
          Icon(Icons.receipt_long_outlined, color: Colors.white),
          Icon(Icons.person_outlined, color: Colors.white),
        ],
      ),
      body: IndexedStack(index: currentTapIndex, children: pages),
    );
  }
}
