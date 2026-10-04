import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Light / Dark / System setting, saved on the phone.
class ThemeController {
  static const String _key = "THEMEMODE";
  static final ValueNotifier<ThemeMode> mode = ValueNotifier<ThemeMode>(ThemeMode.system);

  static Future<void> load() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? saved = prefs.getString(_key);
      mode.value = ThemeMode.values.firstWhere((m) => m.name == saved, orElse: () => ThemeMode.system);
    } catch (e) {
      mode.value = ThemeMode.system;
    }
  }

  static Future<void> set(ThemeMode value) async {
    mode.value = value;
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, value.name);
    } catch (e) {
      // still applied for this session
    }
  }

  // quick switch used by the sun/moon button
  static void toggle(BuildContext context) {
    set(AppColors.isDark(context) ? ThemeMode.light : ThemeMode.dark);
  }
}

// App colors for the current light/dark mode.
class AppColors {
  static const Color accent = Color(0xFFfd6f3e);

  // premium page background: a soft vertical gradient (see AppBackground for the glows)
  static const Color lightTop = Color(0xFFFFF6F0); // warm cream
  static const Color lightBottom = Color(0xFFF3F0FA); // soft lavender white
  static const Color darkTop = Color(0xFF15132A); // deep indigo
  static const Color darkBottom = Color(0xFF0D0D16); // near black

  static bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  // solid page color (bottom of the gradient), e.g. behind the bottom bar
  static Color background(BuildContext context) => isDark(context) ? darkBottom : lightBottom;
  // see-through "frosted glass" for bars that float over the content
  static Color glass(BuildContext context) =>
      isDark(context) ? darkTop.withValues(alpha: 0.86) : lightTop.withValues(alpha: 0.86);
  // cards, tiles, sheets
  static Color card(BuildContext context) => isDark(context) ? Color(0xFF1D1B2C) : Colors.white;
  // box behind product pictures; stays light in dark mode so dark products are still visible
  static Color imageBox(BuildContext context) => isDark(context) ? Color(0xFFE4E4E9) : Color(0xFFF6F6F8);
  // text field fill
  static Color field(BuildContext context) => isDark(context) ? Color(0xFF292739) : Color(0xFFF4F5F9);
  static Color text(BuildContext context) => isDark(context) ? Colors.white : Colors.black;
  static Color textMuted(BuildContext context) => isDark(context) ? Colors.white70 : Colors.black54;
  static Color textFaint(BuildContext context) => isDark(context) ? Colors.white38 : Colors.black38;
  // strong buttons (black in light mode, white in dark mode) and what goes on them
  static Color strong(BuildContext context) => isDark(context) ? Colors.white : Colors.black;
  static Color onStrong(BuildContext context) => isDark(context) ? Colors.black : Colors.white;
  // bottom navigation bar
  static Color navBar(BuildContext context) => isDark(context) ? Color(0xFF26233B) : Colors.black;
  static Color shadow(BuildContext context) =>
      isDark(context) ? Colors.black.withValues(alpha: 0.45) : Colors.black.withValues(alpha: 0.06);

  // Poppins: clear, rounded letters that are easy to read for every age
  static const String fontFamily = "Poppins";

  // app bars are see-through so the page background shows behind them
  static const AppBarTheme _appBar = AppBarTheme(
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    scrolledUnderElevation: 0,
    elevation: 0,
  );

  static ThemeData lightTheme() => ThemeData(
        fontFamily: fontFamily,
        colorScheme: ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.light),
        scaffoldBackgroundColor: lightBottom,
        appBarTheme: _appBar,
      );

  static ThemeData darkTheme() => ThemeData(
        fontFamily: fontFamily,
        colorScheme: ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.dark),
        scaffoldBackgroundColor: darkBottom,
        appBarTheme: _appBar,
      );
}
