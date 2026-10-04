import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin_panel/models/product.dart';
import 'package:admin_panel/pages/product_form.dart';
import 'package:admin_panel/pages/shell.dart';
import 'package:admin_panel/services/db.dart';
import 'package:admin_panel/theme/theme.dart';
import 'package:admin_panel/theme/theme_toggle.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Screen sizes the panel must work on without anything overflowing.
const Map<String, Size> screens = {
  'phone': Size(390, 844),
  'tablet': Size(800, 1100),
  'desktop': Size(1366, 800),
};

Future<FakeFirebaseFirestore> fakeShop() async {
  final db = FakeFirebaseFirestore();
  for (final p in builtInProducts.take(4)) {
    await db.collection("Products").add({...p.toMap(), "CreatedAt": Timestamp.now()});
  }
  await db.collection("Products").add({
    ...const Product(name: "A product with a really long name for testing", image: "", price: 99999, discount: 35,
            category: "TV", detail: "x")
        .toMap(),
    "CreatedAt": Timestamp.now(),
  });
  await db.collection("Orders").add({
    "Product": "OLED TV 65\" with an extra long product name", "Quantity": 12, "Price": 1200, "Discount": 10,
    "Total": 14400, "Status": "Pending", "Name": "Customer With A Long Name",
    "Email": "a.really.long.customer.email.address@gmail.com", "ProductImage": "images/tv_oled.png",
    "CreatedAt": Timestamp.now(),
  });
  await db.collection("users").add({"Name": "Saruar", "Email": "saruar@gmail.com"});
  return db;
}

// taps a page in the menu (bottom bar on phones, side menu on bigger screens)
Future<void> openPage(WidgetTester tester, String label) async {
  Finder menu = find.byType(NavigationBar).evaluate().isNotEmpty ? find.byType(NavigationBar) : find.byType(NavigationRail);
  await tester.tap(find.descendant(of: menu, matching: find.text(label)));
}

void main() {
  for (final entry in screens.entries) {
    testWidgets('every page fits on ${entry.key}', (tester) async {
      tester.view.physicalSize = entry.value * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      Db.useForTests(await fakeShop());

      await tester.pumpWidget(const MaterialApp(home: AdminShell()));
      await tester.pumpAndSettle();
      expect(find.text('Dashboard'), findsWidgets);

      for (final page in ['Orders', 'Products', 'Users', 'Dashboard']) {
        await openPage(tester, page);
        await tester.pumpAndSettle();
        final error = tester.takeException();
        expect(error, isNull, reason: '$page on ${entry.key}: ${error is FlutterError ? error.toStringDeep() : error}');
      }

      // the add/edit product form
      await openPage(tester, 'Products');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('Edit').first); // phones: scroll down to it
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Edit').first);
      await tester.pumpAndSettle();
      expect(find.byType(ProductForm), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'product form on ${entry.key}');
    });
  }

  for (final entry in screens.entries) {
    testWidgets('dark mode: every page fits on ${entry.key}', (tester) async {
      tester.view.physicalSize = entry.value * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      Db.useForTests(await fakeShop());
      await tester.pumpWidget(MaterialApp(
        theme: AppColors.lightTheme(),
        darkTheme: AppColors.darkTheme(),
        themeMode: ThemeMode.dark,
        home: const AdminShell(),
      ));
      await tester.pumpAndSettle();
      for (final page in ['Orders', 'Products', 'Users', 'Dashboard']) {
        await openPage(tester, page);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$page (dark) on ${entry.key}');
      }
    });
  }

  testWidgets('sun/moon button switches the panel between light and dark', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await ThemeController.set(ThemeMode.light);
    tester.view.physicalSize = const Size(1366, 800) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    Db.useForTests(await fakeShop());
    await tester.pumpWidget(ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, mode, child) => MaterialApp(
        theme: AppColors.lightTheme(),
        darkTheme: AppColors.darkTheme(),
        themeMode: mode,
        home: const AdminShell(),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ThemeToggleButton));
    await tester.pumpAndSettle();
    expect(ThemeController.mode.value, ThemeMode.dark);
    expect(find.byTooltip('Light mode'), findsOneWidget);

    await tester.tap(find.byType(ThemeToggleButton));
    await tester.pumpAndSettle();
    expect(ThemeController.mode.value, ThemeMode.light);
  });

  testWidgets('a new order shows a notification and a badge', (tester) async {
    tester.view.physicalSize = const Size(1366, 800) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final db = await fakeShop();
    Db.useForTests(db);

    await tester.pumpWidget(const MaterialApp(home: AdminShell()));
    await tester.pumpAndSettle();
    expect(find.textContaining('New order'), findsNothing); // existing orders are not "new"

    await db.collection("Orders").add({
      "Product": "Webcam", "Quantity": 2, "Total": 140, "Status": "Pending", "Name": "Rahim",
      "CreatedAt": Timestamp.now(),
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('New order: Webcam x2 from Rahim'), findsOneWidget);
    expect(find.descendant(of: find.byType(Badge), matching: find.text('1')), findsOneWidget);

    // opening Orders clears the badge
    await openPage(tester, 'Orders');
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byType(Badge), matching: find.text('1')), findsNothing);
  });

  testWidgets('changing an order status saves it', (tester) async {
    tester.view.physicalSize = const Size(1366, 800) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final db = await fakeShop();
    Db.useForTests(db);

    await tester.pumpWidget(const MaterialApp(home: AdminShell()));
    await tester.pumpAndSettle();
    await openPage(tester, 'Orders');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pending').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delivered').last);
    await tester.pumpAndSettle();

    final orders = await db.collection("Orders").get();
    expect(orders.docs.first.data()["Status"], 'Delivered');
  });
}
