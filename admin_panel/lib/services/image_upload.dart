import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:image/image.dart' as img;

// Lets the admin pick a picture from the computer and turns it into a small JPEG
// stored as base64 text, so it fits inside a Firestore document (1 MB limit)
// without needing Firebase Storage (which is not on the free plan).
class ImageUpload {
  static const int maxSide = 600;
  static const int maxBytes = 700 * 1024;

  // returns null when the user cancels
  static Future<String?> pick() async {
    const XTypeGroup images = XTypeGroup(label: "Images", extensions: ["jpg", "jpeg", "png", "webp", "gif", "bmp"]);
    XFile? file = await openFile(acceptedTypeGroups: [images]);
    if (file == null) return null;
    return encode(await file.readAsBytes());
  }

  // shrink + compress; throws a readable message if the file is not a picture or still too big
  static String encode(Uint8List bytes) {
    img.Image? picture;
    try {
      picture = img.decodeImage(bytes);
    } catch (e) {
      picture = null; // broken or unknown file
    }
    if (picture == null) throw "This file is not a picture";
    if (picture.width > maxSide || picture.height > maxSide) {
      picture = picture.width >= picture.height
          ? img.copyResize(picture, width: maxSide)
          : img.copyResize(picture, height: maxSide);
    }
    // PNGs with transparency keep it (product photos often have no background)
    bool transparent = picture.hasAlpha;
    Uint8List out = transparent
        ? Uint8List.fromList(img.encodePng(picture, level: 9))
        : Uint8List.fromList(img.encodeJpg(picture, quality: 75));
    if (out.length > maxBytes) {
      out = Uint8List.fromList(img.encodeJpg(picture, quality: 60));
    }
    if (out.length > maxBytes) throw "Picture is too large even after compressing, please use a smaller one";
    return base64Encode(out);
  }
}
