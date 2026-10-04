import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

// Firebase project "shopapp-68db3" (the same project the shopping app uses).
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) return android;
    // Windows and web both use the web app config
    return web;
  }

  // Firebase app "ShoppingApp Admin Panel" (web)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyB_nPE3XsFUOH2KsX2-gTFkYHjIYanPOtU",
    appId: "1:723221073485:web:96e3efa25fb5ac27f05604",
    messagingSenderId: "723221073485",
    projectId: "shopapp-68db3",
    authDomain: "shopapp-68db3.firebaseapp.com",
    storageBucket: "shopapp-68db3.firebasestorage.app",
    measurementId: "G-54M42GTWBL",
  );

  // Firebase app "ShoppingApp Admin Panel (Android)", package com.example.admin_panel
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyBkxWYRnCkli64_InWNB3hXiWNiZL1oqGk",
    appId: "1:723221073485:android:741753dfa5768089f05604",
    messagingSenderId: "723221073485",
    projectId: "shopapp-68db3",
    storageBucket: "shopapp-68db3.firebasestorage.app",
  );
}
