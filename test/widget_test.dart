import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shoppingapp/models/product.dart';
import 'package:shoppingapp/pages/home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoppingapp/pages/cart_page.dart';
import 'package:shoppingapp/pages/forgot_password.dart';
import 'package:shoppingapp/pages/login.dart';
import 'package:shoppingapp/pages/settings_page.dart';
import 'package:shoppingapp/pages/signup.dart';
import 'package:shoppingapp/services/cart.dart';
import 'package:shoppingapp/services/theme.dart';
import 'package:shoppingapp/widget/theme_toggle.dart';

void main() {
  testWidgets('ProductCard shows product name and price', (WidgetTester tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 260,
            child: ProductCard(product: builtInProducts.first, onTap: () => tapped = true),
          ),
        ),
      ),
    );

    expect(find.text(builtInProducts.first.name), findsOneWidget);
    expect(find.text('\$${builtInProducts.first.price}'), findsOneWidget);

    await tester.tap(find.byType(ProductCard));
    expect(tapped, isTrue);
  });

  group('Cart', () {
    Product watch = findProduct('Apple Watch')!;
    Product laptop = findProduct('Laptop')!;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await Cart.load('user1');
    });

    test('add, change quantity, remove and total', () {
      Cart.add(watch);
      Cart.add(watch);
      Cart.add(laptop, 3);
      expect(Cart.count, 5);
      expect(Cart.total, watch.finalPrice * 2 + laptop.finalPrice * 3);

      Cart.setQuantity(laptop, 1);
      expect(Cart.count, 3);

      Cart.remove(watch);
      expect(Cart.list.map((i) => i.product.name), ['Laptop']);

      Cart.clear();
      expect(Cart.count, 0);
    });

    test('cart is saved per user and comes back after reload', () async {
      Cart.add(watch, 2);
      await Future<void>.delayed(Duration.zero);

      await Cart.load('user2');
      expect(Cart.count, 0);

      await Cart.load('user1');
      expect(Cart.count, 2);
    });

    testWidgets('cart icon shows the number of items', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Center(child: CartNavIcon()))));
      expect(find.text('1'), findsNothing);

      Cart.add(watch);
      await tester.pump();
      expect(find.text('1'), findsOneWidget);

      Cart.add(laptop, 2);
      await tester.pump();
      expect(find.text('3'), findsOneWidget);

      Cart.clear();
      await tester.pump();
      expect(find.text('3'), findsNothing);
    });

    testWidgets('cart page lists items and the delete button removes one', (WidgetTester tester) async {
      Cart.add(watch);
      Cart.add(laptop);
      await tester.pumpWidget(const MaterialApp(home: CartPage()));
      expect(find.text('Apple Watch'), findsOneWidget);
      expect(find.text('Laptop'), findsOneWidget);
      expect(find.text('Confirm Order'), findsOneWidget);

      await tester.tap(find.byTooltip('Delete').first);
      await tester.pump();
      expect(find.text('Apple Watch'), findsNothing);
      expect(Cart.count, 1);
    });

    testWidgets('removed-from-cart message closes by itself, UNDO brings the item back', (WidgetTester tester) async {
      Cart.add(watch);
      Cart.add(laptop);
      await tester.pumpWidget(const MaterialApp(home: CartPage()));

      // delete and wait without tapping UNDO
      await tester.tap(find.byTooltip('Delete').first);
      await tester.pump();
      expect(find.text('Apple Watch removed from cart'), findsOneWidget);
      // the 3 second timer starts once the slide-in animation has finished
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Apple Watch removed from cart'), findsOneWidget); // still visible after ~2s
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('Apple Watch removed from cart'), findsNothing);

      // delete the laptop too, then tap UNDO: only the laptop comes back
      await tester.tap(find.byTooltip('Delete').first);
      await tester.pumpAndSettle(); // let the message slide in fully
      expect(Cart.count, 0);
      await tester.tap(find.text('UNDO'));
      await tester.pumpAndSettle();
      expect(Cart.count, 1);
      expect(find.text('Laptop'), findsOneWidget);
      expect(find.text('Laptop removed from cart'), findsNothing);
    });
  });

  List<String> search(String query) =>
      builtInProducts.where((p) => matchesSearch(p, query)).map((p) => p.name).toList();

  test('search ignores case, spaces and plural', () {
    expect(search('apple watch'), ['Apple Watch']);
    expect(search('APPLE WATCH'), ['Apple Watch']);
    expect(search('  laptop  '), ['Laptop']);
    expect(search('airpods'), ['Apple Airpod']);
    expect(search('air pod'), ['Apple Airpod']);
    expect(search('WebCam'), ['Webcam']);
    expect(search('phone'), ['Headphone', 'JBL Live 660NC']);
    expect(search('tv'), ['Smart TV 43"', '4K UHD TV 55"', 'OLED TV 65"']);
    expect(search('oled'), ['OLED TV 65"']);
    expect(search('xyz'), isEmpty);
  });

  test('each category only has its own products', () {
    List<String> inCategory(String name) =>
        builtInProducts.where((p) => p.category == name).map((p) => p.name).toList();
    expect(inCategory('Headphone'), ['Headphone', 'JBL Live 660NC']);
    expect(inCategory('Airpods'), ['Apple Airpod']);
    expect(inCategory('Earbuds'), ['Earbuds']);
    expect(inCategory('Laptop'), ['Laptop']);
    expect(inCategory('Webcam'), ['Webcam']);
    expect(inCategory('Watch'), ['Apple Watch', 'Classic Leather Watch']);
    expect(inCategory('TV'), ['Smart TV 43"', '4K UHD TV 55"', 'OLED TV 65"']);
  });

  test('discount lowers the final price', () {
    const product = Product(name: 'TV', image: '', price: 200, discount: 25, category: 'TV', detail: '');
    expect(product.hasDiscount, isTrue);
    expect(product.finalPrice, 150);
    const noDiscount = Product(name: 'TV', image: '', price: 200, category: 'TV', detail: '');
    expect(noDiscount.hasDiscount, isFalse);
    expect(noDiscount.finalPrice, 200);
  });

  testWidgets('ProductCard shows the discounted price and the old price', (WidgetTester tester) async {
    const product = Product(name: 'Laptop', image: 'images/laptop2.png', price: 1000, discount: 20, category: 'Laptop', detail: '');
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: SizedBox(width: 200, height: 260, child: ProductCard(product: product))),
    ));
    expect(find.text('\$800'), findsOneWidget);
    expect(find.text('\$1000'), findsOneWidget);
    expect(find.text('-20%'), findsOneWidget);
  });

  test('reset code is read from the email link', () {
    const link = 'https://shopapp-68db3.firebaseapp.com/__/auth/action?mode=resetPassword&oobCode=AbC-123_xyz&apiKey=KEY&lang=en';
    expect(extractResetCode(link), 'AbC-123_xyz');
    expect(extractResetCode('  $link  '), 'AbC-123_xyz');
    // Gmail sometimes wraps links and encodes them
    expect(extractResetCode('https://www.google.com/url?q=${Uri.encodeComponent(link)}&sa=D'), 'AbC-123_xyz');
    // just the code pasted
    expect(extractResetCode('AbC-123_xyz'), 'AbC-123_xyz');
    expect(extractResetCode(''), isNull);
    expect(extractResetCode('hello there'), isNull);
    expect(extractResetCode('https://example.com/page'), isNull);
  });

  testWidgets('forgot password shows the email step first', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ForgotPassword(email: 'me@gmail.com')));
    expect(find.text('Send reset link'), findsOneWidget);
    expect(find.text('me@gmail.com'), findsOneWidget);
    expect(find.text('Paste reset link'), findsNothing);
  });

  testWidgets('home: banner scrolls away, search and categories stay pinned', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'USERNAMEKEY': 'Saruar'});
    tester.view.physicalSize = const Size(412 * 3, 892 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: Home()));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Hey, Saruar'), findsOneWidget);
    double searchTopBefore = tester.getTopLeft(find.byType(TextField)).dy;
    expect(searchTopBefore, greaterThan(150)); // below the greeting and banner

    // scroll the page up by a lot
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
    await tester.pump(const Duration(milliseconds: 500));

    // greeting + banner are gone off the top of the screen
    expect(find.text('Hey, Saruar').hitTestable(), findsNothing);
    expect(find.byType(ProductBannerSlider).hitTestable(), findsNothing);
    // search bar and categories are still at the top
    expect(tester.getTopLeft(find.byType(TextField)).dy, lessThan(30));
    expect(find.text('Categories').hitTestable(), findsOneWidget);
    expect(tester.getTopLeft(find.text('All').first).dy, greaterThan(0));

    // stop the banner's auto-play timer
    await tester.pumpWidget(const SizedBox());
  });

  test('theme choice is saved and loaded again', () async {
    SharedPreferences.setMockInitialValues({});
    await ThemeController.load();
    expect(ThemeController.mode.value, ThemeMode.system);

    await ThemeController.set(ThemeMode.dark);
    ThemeController.mode.value = ThemeMode.light; // pretend the app restarted
    await ThemeController.load();
    expect(ThemeController.mode.value, ThemeMode.dark);
  });

  testWidgets('sun/moon button on home switches between light and dark', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await ThemeController.set(ThemeMode.light);
    await tester.pumpWidget(ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, mode, child) => MaterialApp(
        theme: AppColors.lightTheme(),
        darkTheme: AppColors.darkTheme(),
        themeMode: mode,
        home: const Home(),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byTooltip('Dark mode'));
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100)); // let the theme animation finish
    }
    expect(ThemeController.mode.value, ThemeMode.dark);
    expect(find.byTooltip('Light mode'), findsOneWidget);

    await tester.tap(find.byTooltip('Light mode'));
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100)); // let the theme animation finish
    }
    expect(ThemeController.mode.value, ThemeMode.light);

    await tester.pumpWidget(const SizedBox());
  });

  group('Settings', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({'USERNAMEKEY': 'Saruar'});
      await Cart.load('u');
      await ThemeController.set(ThemeMode.system);
    });

    Future<void> openSettings(WidgetTester tester) async {
      tester.view.physicalSize = const Size(412 * 3, 1600 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
      await tester.pump();
    }

    Future<void> openSection(WidgetTester tester, String name) async {
      await tester.tap(find.text(name));
      await tester.pumpAndSettle();
    }

    testWidgets('shows only section names until a section is tapped', (WidgetTester tester) async {
      await openSettings(tester);
      for (String section in ['Account', 'Appearance', 'Shopping', 'Support', 'About', 'Logout', 'Delete Account']) {
        expect(find.text(section), findsOneWidget, reason: section);
      }
      // options are hidden at first
      for (String option in ['Change Password', 'Dark', 'Clear Cart', 'Help & FAQ', 'App Version']) {
        expect(find.text(option), findsNothing, reason: option);
      }

      Map<String, List<String>> options = {
        'Account': ['Name', 'Saruar', 'Email', 'Change Password'],
        'Appearance': ['Light', 'Dark', 'System'],
        'Shopping': ['Clear Cart'],
        'Support': ['Help & FAQ', 'Privacy Policy'],
        'About': ['App Version', appVersion],
      };
      for (MapEntry<String, List<String>> entry in options.entries) {
        await openSection(tester, entry.key);
        for (String option in entry.value) {
          expect(find.text(option), findsOneWidget, reason: '${entry.key} > $option');
        }
      }

      // tapping a section again closes it
      await openSection(tester, 'Account');
      expect(find.text('Change Password'), findsNothing);
    });

    testWidgets('appearance buttons change the theme', (WidgetTester tester) async {
      await openSettings(tester);
      await openSection(tester, 'Appearance');
      await tester.tap(find.text('Dark'));
      await tester.pump();
      expect(ThemeController.mode.value, ThemeMode.dark);
      await tester.tap(find.text('Light'));
      await tester.pump();
      expect(ThemeController.mode.value, ThemeMode.light);
    });

    testWidgets('clear cart empties the cart after confirming', (WidgetTester tester) async {
      Cart.add(findProduct('Laptop')!, 2);
      await openSettings(tester);
      await openSection(tester, 'Shopping');
      expect(find.text('2 item(s) in cart'), findsOneWidget);

      await tester.tap(find.text('Clear Cart'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();
      expect(Cart.count, 0);
      expect(find.text('0 item(s) in cart'), findsOneWidget);
    });

    testWidgets('edit name and delete account dialogs close without errors', (WidgetTester tester) async {
      await openSettings(tester);
      await openSection(tester, 'Account');

      // Edit Name -> Cancel
      await tester.tap(find.text('Saruar'));
      await tester.pumpAndSettle();
      expect(find.text('Edit Name'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Edit Name'), findsNothing);
      expect(tester.takeException(), isNull);

      // Delete Account -> Cancel
      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('help page opens', (WidgetTester tester) async {
      await openSettings(tester);
      await openSection(tester, 'Support');
      await tester.tap(find.text('Help & FAQ'));
      await tester.pumpAndSettle();
      expect(find.text('How do I buy a product?'), findsOneWidget);
    });
  });

  for (MapEntry<String, Widget> page in {'Login': const LogIn(), 'Sign Up': const Signup()}.entries) {
    testWidgets('${page.key}: eye button shows and hides the password', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(412 * 3, 1400 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(home: page.value));

      bool passwordHidden() => tester
          .widget<EditableText>(find.descendant(
              of: find.widgetWithText(TextFormField, 'Password'), matching: find.byType(EditableText)))
          .obscureText;

      expect(passwordHidden(), isTrue);
      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();
      expect(passwordHidden(), isFalse);
      await tester.tap(find.byTooltip('Hide password'));
      await tester.pump();
      expect(passwordHidden(), isTrue);
    });
  }

  testWidgets('sun/moon icon morphs smoothly when the theme changes', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await ThemeController.set(ThemeMode.light);
    await tester.pumpWidget(ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, mode, child) => MaterialApp(
        theme: AppColors.lightTheme(),
        darkTheme: AppColors.darkTheme(),
        themeMode: mode,
        themeAnimationDuration: Duration.zero,
        home: const Scaffold(body: Center(child: ThemeToggleButton())),
      ),
    ));
    double morph() => (tester.widget<CustomPaint>(
            find.descendant(of: find.byType(ThemeToggleButton), matching: find.byType(CustomPaint)).last)
        .painter as SunMoonPainter).t;

    expect(morph(), 0); // sun

    await tester.tap(find.byType(ThemeToggleButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(morph(), allOf(greaterThan(0.1), lessThan(0.9))); // half way: part sun, part moon

    await tester.pumpAndSettle();
    expect(morph(), 1); // moon
    expect(ThemeController.mode.value, ThemeMode.dark);

    // and back to the sun
    await tester.tap(find.byType(ThemeToggleButton));
    await tester.pumpAndSettle();
    expect(morph(), 0);
  });

  test('every product belongs to a known category', () {
    Set<String> categoryNames = categories.map((c) => c.name).toSet();
    for (Product product in builtInProducts) {
      expect(categoryNames, contains(product.category));
    }
  });
}
