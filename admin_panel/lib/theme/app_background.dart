import 'package:flutter/material.dart';
import 'package:admin_panel/theme/theme.dart';

// Premium page background: a soft vertical gradient with blurred color glows.
// Light: warm cream -> lavender with orange, pink and violet glows.
// Dark: deep indigo -> near black with orange, violet and teal glows.
// It is part of each page (not the whole app), so page transitions never show
// two pages on top of each other. Switching light/dark blends smoothly.
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: AppColors.isDark(context) ? 1 : 0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      builder: (context, dark, child) {
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(AppColors.lightTop, AppColors.darkTop, dark)!,
                Color.lerp(AppColors.lightBottom, AppColors.darkBottom, dark)!,
              ],
            ),
          ),
          child: CustomPaint(
            painter: GlowPainter(dark),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _Glow {
  final Offset position; // fraction of the screen (0..1)
  final double radius; // fraction of the screen width
  final Color light;
  final Color dark;
  final double lightAlpha;
  final double darkAlpha;

  const _Glow(this.position, this.radius, this.light, this.dark, this.lightAlpha, this.darkAlpha);
}

// Soft round glows drawn with radial gradients (cheap, no blur filter needed).
class GlowPainter extends CustomPainter {
  final double dark; // 0 = light mode, 1 = dark mode

  GlowPainter(this.dark);

  static const List<_Glow> _glows = [
    // top right: brand orange
    _Glow(Offset(1.0, 0.04), 0.85, AppColors.accent, AppColors.accent, 0.20, 0.22),
    // middle left: pink in light mode, violet in dark mode
    _Glow(Offset(-0.05, 0.48), 0.75, Color(0xFFFF7EB3), Color(0xFF7B5CFF), 0.13, 0.22),
    // bottom right: lavender in light mode, teal in dark mode
    _Glow(Offset(1.05, 0.92), 0.85, Color(0xFF8F7CFF), Color(0xFF1FB5B0), 0.14, 0.12),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (_Glow g in _glows) {
      Offset center = Offset(g.position.dx * size.width, g.position.dy * size.height);
      double radius = g.radius * size.width;
      Color color = Color.lerp(g.light, g.dark, dark)!;
      double alpha = g.lightAlpha + (g.darkAlpha - g.lightAlpha) * dark;
      Paint paint = Paint()
        ..shader = RadialGradient(
          colors: [color.withValues(alpha: alpha), color.withValues(alpha: alpha * 0.4), color.withValues(alpha: 0)],
          stops: const [0, 0.45, 1],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(GlowPainter old) => old.dark != dark;
}
