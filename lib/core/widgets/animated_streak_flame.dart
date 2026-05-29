import 'dart:math';
import 'package:flutter/material.dart';

/// Animated custom-drawn Pomodoro streak flame widget.
/// Draws different levels of flames based on the current streak count:
/// - Level 0 (0 days): Sleeping/breathing warm ember.
/// - Level 1 (1-3 days): Flickering yellow-orange flame.
/// - Level 2 (4-7 days): High-heat cyan blazing flame.
/// - Level 3 (8+ days): High-intensity cosmic purple-magenta supernova.
class AnimatedStreakFlame extends StatefulWidget {
  const AnimatedStreakFlame({
    super.key,
    this.size = 20,
    required this.streakCount,
  });

  final double size;
  final int streakCount;

  @override
  State<AnimatedStreakFlame> createState() => _AnimatedStreakFlameState();
}

class _AnimatedStreakFlameState extends State<AnimatedStreakFlame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _getDuration(widget.streakCount),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant AnimatedStreakFlame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_getLevel(oldWidget.streakCount) != _getLevel(widget.streakCount)) {
      _controller.duration = _getDuration(widget.streakCount);
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _getLevel(int count) {
    if (count == 0) return 0;
    if (count <= 3) return 1;
    if (count <= 7) return 2;
    return 3;
  }

  Duration _getDuration(int count) {
    final level = _getLevel(count);
    switch (level) {
      case 0:
        return const Duration(milliseconds: 2400);
      case 1:
        return const Duration(milliseconds: 1500);
      case 2:
        return const Duration(milliseconds: 1000);
      case 3:
      default:
        return const Duration(milliseconds: 700);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size * 1.25),
          painter: _FlamePainter(_controller.value, widget.streakCount),
        );
      },
    );
  }
}

class _FlamePainter extends CustomPainter {
  _FlamePainter(this.animationValue, this.streakCount);
  final double animationValue;
  final int streakCount;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    final level = streakCount == 0
        ? 0
        : (streakCount <= 3
            ? 1
            : (streakCount <= 7 ? 2 : 3));

    // Customize flicker and height oscillation based on level
    final double flicker;
    final double heightFactor;
    switch (level) {
      case 0:
        flicker = 0.02 * sin(animationValue * 2 * pi);
        heightFactor = 1.0 + 0.02 * cos(animationValue * pi);
        break;
      case 1:
        flicker = 0.06 * sin(animationValue * 4 * pi);
        heightFactor = 1.0 + 0.08 * cos(animationValue * 2 * pi);
        break;
      case 2:
        flicker = 0.09 * sin(animationValue * 6 * pi);
        heightFactor = 1.0 + 0.12 * cos(animationValue * 3 * pi);
        break;
      case 3:
      default:
        flicker = 0.12 * sin(animationValue * 8 * pi);
        heightFactor = 1.0 + 0.16 * cos(animationValue * 4 * pi);
        break;
    }

    final pathOuter = Path();
    final pathMiddle = Path();
    final pathInner = Path();

    if (level == 0) {
      // Draw sleeping/breathing round ember shape
      final radiusFactor = 0.85 + 0.15 * sin(animationValue * 2 * pi);
      final rOuter = width * 0.42 * radiusFactor;
      final rMiddle = width * 0.28 * radiusFactor;
      final rInner = width * 0.15 * radiusFactor;
      
      final centerEmber = Offset(width / 2, height * 0.65);

      pathOuter.addOval(Rect.fromCircle(center: centerEmber, radius: rOuter));
      pathMiddle.addOval(Rect.fromCircle(center: centerEmber, radius: rMiddle));
      pathInner.addOval(Rect.fromCircle(center: centerEmber, radius: rInner));
    } else {
      // Draw flame shapes (Level 1, 2, 3)
      pathOuter.moveTo(width * 0.5, height * (0.1 - flicker) * heightFactor);
      pathOuter.quadraticBezierTo(
        width * (0.8 + flicker), height * 0.4,
        width * 0.75, height * 0.8,
      );
      pathOuter.quadraticBezierTo(
        width * 0.5, height * 0.95,
        width * 0.25, height * 0.8,
      );
      pathOuter.quadraticBezierTo(
        width * (0.2 - flicker), height * 0.4,
        width * 0.5, height * (0.1 - flicker) * heightFactor,
      );
      pathOuter.close();

      pathMiddle.moveTo(width * 0.5, height * (0.35 - flicker) * heightFactor);
      pathMiddle.quadraticBezierTo(
        width * (0.7 + flicker), height * 0.5,
        width * 0.65, height * 0.8,
      );
      pathMiddle.quadraticBezierTo(
        width * 0.5, height * 0.9,
        width * 0.35, height * 0.8,
      );
      pathMiddle.quadraticBezierTo(
        width * (0.3 - flicker), height * 0.5,
        width * 0.5, height * (0.35 - flicker) * heightFactor,
      );
      pathMiddle.close();

      pathInner.moveTo(width * 0.5, height * (0.55 - flicker) * heightFactor);
      pathInner.quadraticBezierTo(
        width * (0.62 + flicker), height * 0.65,
        width * 0.58, height * 0.8,
      );
      pathInner.quadraticBezierTo(
        width * 0.5, height * 0.85,
        width * 0.42, height * 0.8,
      );
      pathInner.quadraticBezierTo(
        width * (0.38 - flicker), height * 0.65,
        width * 0.5, height * (0.55 - flicker) * heightFactor,
      );
      pathInner.close();
    }

    final Paint paintOuter;
    final Paint paintMiddle;
    final Paint paintInner;

    final gradCenter = level == 0 ? Offset(width / 2, height * 0.65) : Offset(width / 2, height / 2);

    switch (level) {
      case 0:
        paintOuter = Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.orange.withValues(alpha: 0.4),
              Colors.redAccent.withValues(alpha: 0.05),
            ],
          ).createShader(Rect.fromCircle(center: gradCenter, radius: width * 0.42))
          ..style = PaintingStyle.fill;
        paintMiddle = Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.deepOrange.withValues(alpha: 0.6),
              Colors.orange.withValues(alpha: 0.05),
            ],
          ).createShader(Rect.fromCircle(center: gradCenter, radius: width * 0.28))
          ..style = PaintingStyle.fill;
        paintInner = Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.yellowAccent.withValues(alpha: 0.8),
              Colors.amber.withValues(alpha: 0.1),
            ],
          ).createShader(Rect.fromCircle(center: gradCenter, radius: width * 0.15))
          ..style = PaintingStyle.fill;
        break;
      case 1:
        paintOuter = Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.deepOrange.withValues(alpha: 0.85),
              Colors.redAccent.withValues(alpha: 0.1),
            ],
          ).createShader(Rect.fromCircle(center: gradCenter, radius: width * 0.5))
          ..style = PaintingStyle.fill;
        paintMiddle = Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.orangeAccent.withValues(alpha: 0.95),
              Colors.orange.withValues(alpha: 0.15),
            ],
          ).createShader(Rect.fromCircle(center: gradCenter, radius: width * 0.35))
          ..style = PaintingStyle.fill;
        paintInner = Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white,
              Colors.amber.withValues(alpha: 0.4),
            ],
          ).createShader(Rect.fromCircle(center: gradCenter, radius: width * 0.2))
          ..style = PaintingStyle.fill;
        break;
      case 2:
        paintOuter = Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.blue.withValues(alpha: 0.85),
              Colors.cyanAccent.withValues(alpha: 0.1),
            ],
          ).createShader(Rect.fromCircle(center: gradCenter, radius: width * 0.5))
          ..style = PaintingStyle.fill;
        paintMiddle = Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.cyan.withValues(alpha: 0.95),
              Colors.teal.withValues(alpha: 0.15),
            ],
          ).createShader(Rect.fromCircle(center: gradCenter, radius: width * 0.35))
          ..style = PaintingStyle.fill;
        paintInner = Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white,
              Colors.cyanAccent.withValues(alpha: 0.4),
            ],
          ).createShader(Rect.fromCircle(center: gradCenter, radius: width * 0.2))
          ..style = PaintingStyle.fill;
        break;
      case 3:
      default:
        paintOuter = Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.purple.withValues(alpha: 0.85),
              Colors.deepPurpleAccent.withValues(alpha: 0.1),
            ],
          ).createShader(Rect.fromCircle(center: gradCenter, radius: width * 0.5))
          ..style = PaintingStyle.fill;
        paintMiddle = Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.pinkAccent.withValues(alpha: 0.95),
              Colors.amber.withValues(alpha: 0.15),
            ],
          ).createShader(Rect.fromCircle(center: gradCenter, radius: width * 0.35))
          ..style = PaintingStyle.fill;
        paintInner = Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white,
              Colors.amberAccent.withValues(alpha: 0.4),
            ],
          ).createShader(Rect.fromCircle(center: gradCenter, radius: width * 0.2))
          ..style = PaintingStyle.fill;
        break;
    }

    canvas.drawPath(pathOuter, paintOuter);
    canvas.drawPath(pathMiddle, paintMiddle);
    canvas.drawPath(pathInner, paintInner);

    // Draw particle sparks rising
    final paintParticle = Paint()..style = PaintingStyle.fill;
    final int particleCount;
    switch (level) {
      case 0:
        particleCount = 1;
        break;
      case 1:
        particleCount = 3;
        break;
      case 2:
        particleCount = 5;
        break;
      case 3:
      default:
        particleCount = 8;
        break;
    }

    for (int i = 0; i < particleCount; i++) {
      final pVal = (animationValue + (i / particleCount.toDouble())) % 1.0;
      final double px;
      final double py;
      final double pRadius;
      final Color pColor;

      if (level == 0) {
        // Ember particle (rising slowly, very small offset)
        px = width * 0.5 + sin(pVal * 2 * pi + i) * (width * 0.1);
        py = height * (0.8 - pVal * 0.3);
        pRadius = width * 0.05 * (1.0 - pVal);
        pColor = Colors.orangeAccent.withValues(alpha: 0.5 * (1.0 - pVal));
      } else if (level == 1) {
        // Ignited particle (amber spark)
        px = width * 0.5 + sin(pVal * 2 * pi + i) * (width * 0.2);
        py = height * (0.65 - pVal * 0.65);
        pRadius = width * 0.08 * (1.0 - pVal);
        pColor = Colors.amberAccent.withValues(alpha: 1.0 - pVal);
      } else if (level == 2) {
        // Blazing particle (cyan spark rising faster)
        px = width * 0.5 + sin(pVal * 3 * pi + i) * (width * 0.25);
        py = height * (0.7 - pVal * 0.7);
        pRadius = width * 0.09 * (1.0 - pVal);
        pColor = Colors.cyanAccent.withValues(alpha: 1.0 - pVal);
      } else {
        // Supernova particle (magenta/yellow fast spark)
        px = width * 0.5 + sin(pVal * 4 * pi + i) * (width * 0.3);
        py = height * (0.75 - pVal * 0.75);
        pRadius = width * 0.1 * (1.0 - pVal);
        pColor = (i % 2 == 0 ? Colors.pinkAccent : Colors.amberAccent)
            .withValues(alpha: 1.0 - pVal);
      }

      paintParticle.color = pColor;
      canvas.drawCircle(Offset(px, py), pRadius, paintParticle);
    }
  }

  @override
  bool shouldRepaint(_FlamePainter oldDelegate) =>
      oldDelegate.animationValue != animationValue ||
      oldDelegate.streakCount != streakCount;
}
