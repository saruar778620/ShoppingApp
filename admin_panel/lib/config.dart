import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Only this account can use the admin panel. Firestore rules (firestore.rules in the
// shopping app folder) check the same email, so change both together.
const String ownerEmail = "saruarhossain778620@gmail.com";

bool isOwner(User? user) => user?.email?.toLowerCase() == ownerEmail.toLowerCase();

const Color accent = Color(0xFFfd6f3e);

// Must match the categories in the shopping app (lib/models/product.dart).
const List<String> categories = ["Headphone", "Airpods", "Earbuds", "Laptop", "Webcam", "Watch", "TV"];

const List<String> orderStatuses = ["Pending", "On the way!", "Delivered", "Cancelled"];

Color statusColor(String? status) {
  switch (status) {
    case "Delivered":
      return Colors.green;
    case "Cancelled":
      return Colors.red;
    case "Pending":
      return Colors.orange;
    default:
      return Colors.blue;
  }
}

String formatDate(DateTime? d) {
  if (d == null) return "";
  String two(int n) => n.toString().padLeft(2, "0");
  return "${two(d.day)}/${two(d.month)}/${d.year}  ${two(d.hour)}:${two(d.minute)}";
}
