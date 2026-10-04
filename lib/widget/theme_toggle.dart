import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:shoppingapp/services/theme.dart';

// Round sun/moon button. When the theme changes the sun morphs into a moon:
// the rays spin and pull in, a "bite" slides over the sun to carve a crescent,
// and two little stars twinkle in (and the reverse when going back to light).
class ThemeToggleButton extends StatefulWidget {
  final double size;

  const ThemeToggleButton({super.key, this.size = 48});

  @override
  State<ThemeToggleButton> createState() => _ThemeToggleButtonState();
}

class _ThemeToggleButtonState extends State<ThemeToggleButton> with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );
  bool started = false;
  bool pressed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    double target = AppColors.isDark(context) ? 1 : 0;
    if (!started) {
      // first build: show the right icon straight away, no animation
      controller.value = target;
      started = true;
    } else if (controller.value != target) {
      controller.animateTo(target, curve: Curves.easeInOutCubic);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool dark = AppColors.isDark(context);
    return Tooltip(
      message: dark ? "Light mode" : "Dark mode",
      child: GestureDetector(
        onTapDown: (_) => setState(() => pressed = true),
        onTapCancel: () => setState(() => pressed = false),
        onTapUp: (_) => setState(() => pressed = false),
        onTap: () => ThemeController.toggle(context),
        child: AnimatedScale(
          scale: pressed ? 0.88 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeInOut,
            height: widget.size,
            width: widget.size,
            decoration: BoxDecoration(
              color: AppColors.card(context),
              shape: BoxShape.circle,
              boxShadow: [
                // soft warm glow in light mode, cool glow in dark mode
                BoxShadow(
                  color: (dark ? const Color(0xFF8AA2FF) : const Color(0xFFFFB300)).withValues(alpha: 0.22),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ],
            ),
            padding: EdgeInsets.all(widget.size * 0.22),
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, child) => CustomPaint(painter: SunMoonPainter(controller.value)),
            ),
          ),
        ),
      ),
    );
  }
}

// t = 0 is the sun, t = 1 is the moon; anything in between is the morph.
class SunMoonPainter extends CustomPainter {
  final double t;

  SunMoonPainter(this.t);

  static const Color sunColor = Color(0xFFFFB300);
  static const Color moonColor = Color(0xFFE9E4FF);

  @override
  void paint(Canvas canvas, Size size) {
    double s = math.min(size.width, size.height);
    Offset c = size.center(Offset.zero);
    Color color = Color.lerp(sunColor, moonColor, t)!;

    canvas.save();
    // the whole icon turns a little while it morphs
    canvas.translate(c.dx, c.dy);
    canvas.rotate(t * math.pi * 0.5);
    canvas.translate(-c.dx, -c.dy);

    // rays: spin, shorten and fade out on the way to the moon
    double rayFade = (1 - t * 1.6).clamp(0.0, 1.0);
    if (rayFade > 0) {
      Paint rayPaint = Paint()
        ..color = color.withValues(alpha: rayFade)
        ..strokeWidth = s * 0.085
        ..strokeCap = StrokeCap.round;
      double core = s * 0.24;
      double start = core + s * 0.09;
      double length = s * 0.11 * rayFade;
      for (int i = 0; i < 8; i++) {
        double a = i * math.pi / 4;
        Offset dir = Offset(math.cos(a), math.sin(a));
        canvas.drawLine(c + dir * start, c + dir * (start + length), rayPaint);
      }
    }

    // body: the sun grows into the moon, and a "bite" slides in to make the crescent
    double radius = lerpDouble(s * 0.24, s * 0.42, t)!;
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawCircle(c, radius, Paint()..color = color);
    Offset biteFrom = c + Offset(s * 0.9, -s * 0.9); // far outside: no bite on the sun
    Offset biteTo = c + Offset(s * 0.2, -s * 0.18);
    Offset bite = Offset.lerp(biteFrom, biteTo, Curves.easeOut.transform(t))!;
    canvas.drawCircle(bite, radius * 0.82, Paint()..blendMode = BlendMode.clear);
    canvas.restore();

    canvas.restore();

    // stars twinkle in next to the moon (drawn without rotation so they stay upright)
    double starIn = ((t - 0.55) / 0.45).clamp(0.0, 1.0);
    if (starIn > 0) {
      Paint starPaint = Paint()..color = moonColor.withValues(alpha: starIn);
      _star(canvas, c + Offset(s * 0.36, -s * 0.34), s * 0.13 * Curves.elasticOut.transform(starIn), starPaint);
      _star(canvas, c + Offset(s * 0.48, s * 0.02), s * 0.08 * Curves.elasticOut.transform(starIn), starPaint);
    }
  }

  // four-point sparkle
  void _star(Canvas canvas, Offset p, double r, Paint paint) {
    if (r <= 0) return;
    double w = r * 0.28;
    Path path = Path()
      ..moveTo(p.dx, p.dy - r)
      ..quadraticBezierTo(p.dx + w, p.dy - w, p.dx + r, p.dy)
      ..quadraticBezierTo(p.dx + w, p.dy + w, p.dx, p.dy + r)
      ..quadraticBezierTo(p.dx - w, p.dy + w, p.dx - r, p.dy)
      ..quadraticBezierTo(p.dx - w, p.dy - w, p.dx, p.dy - r)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(SunMoonPainter old) => old.t != t;
}
