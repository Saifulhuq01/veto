import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/veto_colors.dart';
import '../../features/dashboard/providers/timer_provider.dart';

/// Animated atmospheric background — indigo + fuchsia orbs floating over
/// dark obsidian canvas with subtle mesh dot overlay.
/// In wind-down mode, shifts to a warm orange-amber sunset glow.
///
/// CRITICAL: This entire widget is wrapped in RepaintBoundary.
/// The orb animations run via AnimationController — they do NOT cause
/// child widgets (glass panels, timer) to repaint.
class AmbientBackground extends ConsumerStatefulWidget {
  const AmbientBackground({super.key});

  @override
  ConsumerState<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends ConsumerState<AmbientBackground>
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
    final timerState = ref.watch(timerProvider);
    final isWindDown = timerState.isWindDown;

    final colorIndigo = isWindDown
        ? const Color(0xFFFFB300) // Amber
        : VetoColors.orbIndigo;

    final colorFuchsia = isWindDown
        ? const Color(0xFFFF3D00) // Deep Orange
        : VetoColors.orbFuchsia;

    return SizedBox.expand(
      child: ColoredBox(
        color: VetoColors.canvasBase,
        child: Stack(
          children: [
            // ── Indigo/Amber orb ──
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
              child: AnimatedContainer(
                duration: const Duration(seconds: 2),
                width: 450,
                height: 450,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colorIndigo.withValues(alpha: 0.35),
                      colorIndigo.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            // ── Fuchsia/Orange orb ──
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
              child: AnimatedContainer(
                duration: const Duration(seconds: 2),
                width: 550,
                height: 550,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colorFuchsia.withValues(alpha: 0.25),
                      colorFuchsia.withValues(alpha: 0.0),
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
