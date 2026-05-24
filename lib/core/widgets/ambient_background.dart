import 'package:flutter/material.dart';
import '../theme/veto_colors.dart';

/// Animated atmospheric background — indigo + fuchsia orbs floating over
/// dark obsidian canvas with subtle mesh dot overlay.
///
/// CRITICAL: This entire widget is wrapped in RepaintBoundary.
/// The orb animations run via AnimationController — they do NOT cause
/// child widgets (glass panels, timer) to repaint.
class AmbientBackground extends StatefulWidget {
  const AmbientBackground({super.key});

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with TickerProviderStateMixin {
  late final AnimationController _controller1;
  late final AnimationController _controller2;

  @override
  void initState() {
    super.initState();
    _controller1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);

    _controller2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: ColoredBox(
        color: VetoColors.canvasBase,
        child: Stack(
          children: [
            // ── Indigo orb using RadialGradient to avoid BackdropFilter ──
            AnimatedBuilder(
              animation: _controller1,
              builder: (context, child) {
                final t = _controller1.value;
                return Positioned(
                  top: -100 + (t * 50),
                  right: -100 - (t * 50),
                  child: child!,
                );
              },
              child: Container(
                width: 450,
                height: 450,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      VetoColors.orbIndigo.withValues(alpha: 0.35),
                      VetoColors.orbIndigo.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            // ── Fuchsia orb using RadialGradient to avoid BackdropFilter ──
            AnimatedBuilder(
              animation: _controller2,
              builder: (context, child) {
                final t = _controller2.value;
                return Positioned(
                  bottom: -150 + (t * 50),
                  left: -150 - (t * 50),
                  child: child!,
                );
              },
              child: Container(
                width: 550,
                height: 550,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      VetoColors.orbFuchsia.withValues(alpha: 0.25),
                      VetoColors.orbFuchsia.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            // ── Mesh dot overlay ──
            Positioned.fill(
              child: Opacity(
                opacity: 0.03,
                child: CustomPaint(
                  painter: _MeshDotPainter(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated builder that exposes the animation as a listenable.
class AnimatedBuilder extends AnimatedWidget {
  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}

class _MeshDotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    const spacing = 20.0;
    const radius = 0.5;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
