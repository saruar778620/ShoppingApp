import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

// Shows a product picture: a bundled asset ("images/..."), a web link ("http...")
// or an uploaded picture stored as base64 text.
class ProductImage extends StatelessWidget {
  final String image;
  final double? size;

  const ProductImage(this.image, {super.key, this.size});

  static final Map<String, Uint8List> _cache = {};

  Widget _fallback() => SizedBox(
        height: size,
        width: size,
        child: const Icon(Icons.image_not_supported_outlined, color: Colors.black26),
      );

  @override
  Widget build(BuildContext context) {
    if (image.isEmpty) return _fallback();
    if (image.startsWith("images/")) {
      return Image.asset(image, height: size, width: size, fit: BoxFit.contain,
          errorBuilder: (c, e, s) => _fallback());
    }
    if (image.startsWith("http")) {
      return Image.network(image, height: size, width: size, fit: BoxFit.contain,
          errorBuilder: (c, e, s) => _fallback());
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
    return Image.memory(bytes, height: size, width: size, fit: BoxFit.contain, gaplessPlayback: true,
        errorBuilder: (c, e, s) => _fallback());
  }
}
