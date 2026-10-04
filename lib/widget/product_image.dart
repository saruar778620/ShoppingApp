import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

// Shows a product image that can be a bundled asset ("images/..."), a web link ("http...")
// or a picture uploaded from the admin panel (stored as base64 text in Firestore).
class ProductImage extends StatelessWidget {
  final String image;
  final double? height;
  final double? width;
  final BoxFit fit;

  const ProductImage(this.image, {super.key, this.height, this.width, this.fit = BoxFit.contain});

  static final Map<String, Uint8List> _cache = {};

  // true for pictures uploaded from the admin panel (too large to copy into every order)
  static bool isUploaded(String image) =>
      image.isNotEmpty && !image.startsWith("images/") && !image.startsWith("http");

  Widget _fallback() => SizedBox(
        height: height,
        width: width,
        child: const Icon(Icons.image_not_supported_outlined, color: Colors.black26, size: 40),
      );

  @override
  Widget build(BuildContext context) {
    if (image.isEmpty) return _fallback();
    if (image.startsWith("images/")) {
      return Image.asset(image, height: height, width: width, fit: fit,
          errorBuilder: (context, error, stack) => _fallback());
    }
    if (image.startsWith("http")) {
      return Image.network(image, height: height, width: width, fit: fit,
          errorBuilder: (context, error, stack) => _fallback());
    }
    Uint8List? bytes = _cache[image];
    if (bytes == null) {
      try {
        bytes = base64Decode(image);
        _cache[image] = bytes;
      } catch (e) {
        return _fallback();
      }
    }
    return Image.memory(bytes, height: height, width: width, fit: fit, gaplessPlayback: true,
        errorBuilder: (context, error, stack) => _fallback());
  }
}
