import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:admin_panel/config.dart';
import 'package:admin_panel/firebase_options.dart';
import 'package:admin_panel/pages/login_page.dart';
import 'package:admin_panel/pages/shell.dart';
import 'package:admin_panel/theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await ThemeController.load();
  runApp(const AdminApp());
}

// Light/dark themes shared with the shopping app, plus untinted dialogs and menus.
ThemeData adminTheme(ThemeData base, Color surface) => base.copyWith(
      dialogTheme: DialogThemeData(backgroundColor: surface, surfaceTintColor: Colors.transparent),
      navigationRailTheme: NavigationRailThemeData(backgroundColor: surface),
      navigationBarTheme: NavigationBarThemeData(backgroundColor: surface, surfaceTintColor: Colors.transparent),
      // orange buttons always get white text (dark mode would otherwise use dark text)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white),
      ),
    );

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, mode, child) => MaterialApp(
        title: "ShoppingApp Admin",
        debugShowCheckedModeBanner: false,
        theme: adminTheme(AppColors.lightTheme(), Colors.white),
        darkTheme: adminTheme(AppColors.darkTheme(), const Color(0xFF1D1B2C)),
        themeMode: mode,
        // colors fade smoothly together with the sun/moon animation
        themeAnimationDuration: const Duration(milliseconds: 500),
        themeAnimationCurve: Curves.easeInOut,
        home: const AuthGate(),
      ),
    );
  }
}

// Shows the panel only to the verified owner account, otherwise the login screen.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        User? user = snapshot.data;
        if (user != null && isOwner(user) && user.emailVerified) {
          return const AdminShell();
        }
        return const LoginPage();
      },
    );
  }
}
