import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shoppingapp/pages/bottomnav.dart';
import 'package:shoppingapp/services/cart.dart';
import 'package:shoppingapp/services/database.dart';
import 'package:shoppingapp/services/theme.dart';
import 'package:shoppingapp/pages/onboarding.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // e.g. on web when no Firebase web app is configured: show why instead of a blank screen
    runApp(FirebaseErrorApp(error: e.toString()));
    return;
  }
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
  );
  await ThemeController.load();
  DatabaseMethods().listenToProducts();
  runApp(MyApp(start: await startPage()));
}

// Decide the first screen: the shop for verified users, otherwise the onboarding/login flow.
Future<Widget> startPage() async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user == null) return const Onboarding();
  if (user.emailVerified) {
    await Cart.load(user.uid);
    return const BottomNav();
  }
  await FirebaseAuth.instance.signOut();
  return const Onboarding();
}

class MyApp extends StatelessWidget {
  final Widget start;

  const MyApp({super.key, this.start = const Onboarding()});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, mode, child) {
        return MaterialApp(
          title: 'Shopping App',
          debugShowCheckedModeBanner: false,
          theme: AppColors.lightTheme(),
          darkTheme: AppColors.darkTheme(),
          themeMode: mode,
          // fade the colors smoothly together with the sun/moon animation
          themeAnimationDuration: const Duration(milliseconds: 500),
          themeAnimationCurve: Curves.easeInOut,
          home: start,
        );
      },
    );
  }
}

class FirebaseErrorApp extends StatelessWidget {
  final String error;

  const FirebaseErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppColors.lightTheme(),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off, size: 60, color: Color(0xFFfd6f3e)),
                SizedBox(height: 16),
                Text(
                  "Could not connect to Firebase",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  "This platform is not configured in Firebase yet.\n$error",
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
