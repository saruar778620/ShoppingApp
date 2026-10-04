import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:admin_panel/config.dart';
import 'package:admin_panel/models/product.dart';
import 'package:admin_panel/pages/product_form.dart';
import 'package:admin_panel/services/image_upload.dart';

void main() {
  test('product data matches what the shopping app reads', () {
    const p = Product(name: 'TV', image: 'images/tv_4k.png', price: 500, discount: 20, category: 'TV', detail: 'Nice');
    Map<String, dynamic> map = p.toMap();
    expect(map.keys, containsAll(['Name', 'Image', 'Price', 'Discount', 'Category', 'Detail']));
    Product back = Product.fromMap('id1', map);
    expect(back.id, 'id1');
    expect(back.name, 'TV');
    expect(back.finalPrice, 400);
  });

  test('built-in products use known categories and pictures that exist', () {
    for (Product p in builtInProducts) {
      expect(categories, contains(p.category), reason: p.name);
      expect(builtInImages, contains(p.image), reason: p.name);
    }
  });

  test('uploaded pictures are shrunk to at most 600px and stay under the size limit', () {
    img.Image big = img.Image(width: 2400, height: 1200);
    img.fill(big, color: img.ColorRgb8(200, 80, 40));
    Uint8List bytes = Uint8List.fromList(img.encodeJpg(big));
    String encoded = ImageUpload.encode(bytes);
    img.Image small = img.decodeImage(base64Decode(encoded))!;
    expect(small.width, 600);
    expect(small.height, 300);
    expect(base64Decode(encoded).length, lessThan(ImageUpload.maxBytes));
  });

  test('a file that is not a picture is rejected', () {
    expect(() => ImageUpload.encode(Uint8List.fromList(utf8.encode('hello'))), throwsA(isA<String>()));
  });

  test('only the owner email can use the panel', () {
    expect(ownerEmail, 'saruarhossain778620@gmail.com');
  });

  testWidgets('product form checks required fields', (tester) async {
    tester.view.physicalSize = const Size(1200 * 2, 900 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ProductForm())));
    await tester.tap(find.text('Add product').last);
    await tester.pump();
    expect(find.text('Enter the product name'), findsOneWidget);
    expect(find.text('Choose a category'), findsOneWidget);
    expect(find.text('Enter a whole number above 0'), findsOneWidget);
    expect(find.text('Please add a picture'), findsOneWidget);

    // price + discount preview
    await tester.enterText(find.widgetWithText(TextFormField, 'Price'), '200');
    await tester.enterText(find.widgetWithText(TextFormField, 'Discount'), '25');
    await tester.pump();
    expect(find.text('\$150'), findsOneWidget);
  });
}
