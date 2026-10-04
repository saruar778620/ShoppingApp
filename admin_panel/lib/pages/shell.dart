import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:admin_panel/theme/app_background.dart';
import 'package:admin_panel/theme/theme.dart';
import 'package:admin_panel/theme/theme_toggle.dart';
import 'package:admin_panel/config.dart';
import 'package:admin_panel/pages/dashboard_page.dart';
import 'package:admin_panel/pages/orders_page.dart';
import 'package:admin_panel/pages/products_page.dart';
import 'package:admin_panel/pages/users_page.dart';
import 'package:admin_panel/services/db.dart';
import 'package:admin_panel/widgets/common.dart';

// Main admin layout: side menu + the selected page. Also watches for new orders.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int page = 0;
  int newOrders = 0; // orders that arrived since the Orders page was last opened
  StreamSubscription? orderWatch;
  bool firstSnapshot = true;

  @override
  void initState() {
    super.initState();
    orderWatch = Db.orders().listen((snapshot) {
      // the first snapshot is the existing orders; after that, "added" means a new order
      if (firstSnapshot) {
        firstSnapshot = false;
        return;
      }
      List<DocumentChange<Map<String, dynamic>>> added =
          snapshot.docChanges.where((c) => c.type == DocumentChangeType.added).toList();
      if (added.isEmpty || !mounted) return;
      setState(() {
        if (page != 1) newOrders += added.length;
      });
      Map<String, dynamic> order = added.first.doc.data() ?? {};
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        width: isPhone(context) ? null : 420,
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 6),
        persist: false,
        content: Text(
          added.length == 1
              ? "New order: ${order["Product"]} x${order["Quantity"] ?? 1} from ${order["Name"] ?? order["Email"] ?? "a customer"}"
              : "${added.length} new orders received",
        ),
        action: SnackBarAction(label: "VIEW", textColor: Colors.white, onPressed: () => select(1)),
      ));
    });
  }

  @override
  void dispose() {
    orderWatch?.cancel();
    super.dispose();
  }

  void select(int index) {
    setState(() {
      page = index;
      if (index == 1) newOrders = 0;
    });
  }

  Future<void> logout() async {
    bool? ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Log out"),
        content: const Text("Log out of the admin panel?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("Log out")),
        ],
      ),
    );
    if (ok == true) await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(onOpenOrders: () => select(1)),
      const OrdersPage(),
      const ProductsPage(),
      const UsersPage(),
    ];
    bool wide = MediaQuery.sizeOf(context).width >= 900;

    // phones: title bar on top, menu at the bottom (like the shopping app)
    if (isPhone(context)) {
      return AppBackground(child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: AppColors.card(context),
          titleSpacing: 16,
          title: const Row(
            children: [
              Icon(Icons.storefront, color: accent),
              SizedBox(width: 8),
              Text("Shop Admin", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            const ThemeToggleButton(size: 38),
            const SizedBox(width: 4),
            IconButton(tooltip: "Log out", onPressed: logout, icon: const Icon(Icons.logout)),
          ],
        ),
        body: pages[page],
        bottomNavigationBar: NavigationBar(
          selectedIndex: page,
          onDestinationSelected: select,
          backgroundColor: AppColors.card(context),
          indicatorColor: accent.withValues(alpha: 0.15),
          destinations: [
            const NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: "Dashboard"),
            NavigationDestination(
              icon: Badge(isLabelVisible: newOrders > 0, label: Text("$newOrders"), child: const Icon(Icons.receipt_long_outlined)),
              selectedIcon: const Icon(Icons.receipt_long),
              label: "Orders",
            ),
            const NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: "Products"),
            const NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: "Users"),
          ],
        ),
      ));
    }

    return AppBackground(child: Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        children: [
          NavigationRail(
            extended: wide,
            minExtendedWidth: 220,
            backgroundColor: AppColors.card(context),
            selectedIndex: page,
            onDestinationSelected: select,
            indicatorColor: accent.withValues(alpha: 0.15),
            selectedIconTheme: const IconThemeData(color: accent),
            selectedLabelTextStyle: const TextStyle(color: accent, fontWeight: FontWeight.w600, fontFamily: "Poppins"),
            labelType: wide ? NavigationRailLabelType.none : NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.storefront, color: accent, size: 30),
                  if (wide) ...[
                    const SizedBox(width: 10),
                    const Text("Shop Admin", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ],
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // animated sun <-> moon switch
                      const ThemeToggleButton(size: 44),
                      const SizedBox(height: 14),
                      wide
                          ? TextButton.icon(onPressed: logout, icon: const Icon(Icons.logout), label: const Text("Log out"))
                          : IconButton(tooltip: "Log out", onPressed: logout, icon: const Icon(Icons.logout)),
                    ],
                  ),
                ),
              ),
            ),
            destinations: [
              const NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text("Dashboard")),
              NavigationRailDestination(
                icon: Badge(
                  isLabelVisible: newOrders > 0,
                  label: Text("$newOrders"),
                  child: const Icon(Icons.receipt_long_outlined),
                ),
                selectedIcon: const Icon(Icons.receipt_long),
                label: const Text("Orders"),
              ),
              const NavigationRailDestination(
                  icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: Text("Products")),
              const NavigationRailDestination(
                  icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: Text("Users")),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: pages[page]),
        ],
      ),
    ));
  }
}
