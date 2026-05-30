import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/veto_colors.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/glass_button.dart';
import '../../../../core/widgets/animated_streak_flame.dart';
import '../../providers/streak_provider.dart';
import '../../providers/usage_stats_provider.dart';

/// Session complete celebration sheet — shown when a focus timer finishes.
class SessionCompleteSheet extends ConsumerWidget {
  const SessionCompleteSheet({
    super.key,
    required this.completedMinutes,
  });

  final int completedMinutes;

  static Future<bool?> show(BuildContext context, {required int completedMinutes}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (context) => SessionCompleteSheet(completedMinutes: completedMinutes),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streakProvider);
    final usage = ref.watch(usageStatsProvider);
    final streakCount = streak.streakCount;

    // Milestone detection
    String? milestone;
    if (streakCount == 3) milestone = '🎯 Focus Apprentice Unlocked!';
    if (streakCount == 7) milestone = '⚡ Flow State Master Unlocked!';
    if (streakCount == 14) milestone = '🛡️ Distraction Exorcist Unlocked!';
    if (streakCount == 30) milestone = '🧘 Productivity Zen Unlocked!';

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFA05050A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: VetoColors.glassBorder, width: 1.5),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
            24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
        child: Stack(
          children: [
            // Confetti overlay
            const Positioned.fill(
              child: IgnorePointer(child: _ConfettiPainter()),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Trophy + Flame
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              VetoColors.secondary.withValues(alpha: 0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      AnimatedStreakFlame(size: 80, streakCount: streakCount),
                    ],
                  ),
                )
                    .animate()
                    .scale(
                        duration: 600.ms,
                        curve: Curves.elasticOut,
                        begin: const Offset(0.3, 0.3),
                        end: const Offset(1, 1)),

                const SizedBox(height: 20),

                // Celebration text
                const Text(
                  'SESSION COMPLETE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 3.0,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 400.ms)
                    .slideY(begin: 0.3, end: 0),

                const SizedBox(height: 8),

                Text(
                  'You focused for $completedMinutes minutes. Incredible discipline.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.65),
                    height: 1.4,
                  ),
                ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                // Milestone callout
                if (milestone != null) ...[
                  const SizedBox(height: 16),
                  GlassPanel(
                    borderRadius: 14,
                    blurSigma: 16,
                    fillOpacity: 0.1,
                    borderColor:
                        VetoColors.secondary.withValues(alpha: 0.5),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.emoji_events,
                            color: VetoColors.secondary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          milestone,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: VetoColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 500.ms, duration: 400.ms)
                      .scale(begin: const Offset(0.8, 0.8)),
                ],

                const SizedBox(height: 24),

                // Stats row
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.timer,
                        label: 'Duration',
                        value: '${completedMinutes}m',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.local_fire_department,
                        label: 'Streak',
                        value: '$streakCount days',
                        valueColor: VetoColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.psychology,
                        label: 'Total Focus',
                        value: usage.focusDisplay,
                      ),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 400.ms)
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 28),

                // Actions
                GlassButton(
                  label: 'Start Another Session',
                  icon: Icons.replay,
                  onPressed: () => Navigator.of(context).pop(true),
                  isExpanded: true,
                )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 400.ms),
                const SizedBox(height: 12),
                GlassButton(
                  label: 'Done',
                  variant: GlassButtonVariant.secondary,
                  onPressed: () => Navigator.of(context).pop(false),
                  isExpanded: true,
                )
                    .animate()
                    .fadeIn(delay: 700.ms, duration: 400.ms),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      borderRadius: 14,
      blurSigma: 16,
      fillOpacity: 0.05,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        children: [
          Icon(icon, color: Colors.white38, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: valueColor ?? Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated confetti particles using CustomPaint.
class _ConfettiPainter extends StatefulWidget {
  const _ConfettiPainter();

  @override
  State<_ConfettiPainter> createState() => _ConfettiPainterState();
}

class _ConfettiPainterState extends State<_ConfettiPainter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_Particle> _particles = [];
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..forward();

    // Generate particles
    for (int i = 0; i < 40; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble(),
        y: -_random.nextDouble() * 0.5,
        speed: 0.3 + _random.nextDouble() * 0.7,
        size: 3 + _random.nextDouble() * 5,
        color: [
          VetoColors.secondary,
          VetoColors.orbIndigo,
          VetoColors.orbFuchsia,
          Colors.amber,
          Colors.white,
        ][_random.nextInt(5)],
        rotation: _random.nextDouble() * pi * 2,
        rotationSpeed: (_random.nextDouble() - 0.5) * 4,
        drift: (_random.nextDouble() - 0.5) * 0.3,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _ConfettiCustomPainter(
            particles: _particles,
            progress: _controller.value,
          ),
        );
      },
    );
  }
}

class _Particle {
  final double x;
  final double y;
  final double speed;
  final double size;
  final Color color;
  final double rotation;
  final double rotationSpeed;
  final double drift;

  _Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
    required this.drift,
  });
}

class _ConfettiCustomPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ConfettiCustomPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    if (opacity <= 0) return;

    for (final p in particles) {
      final x = (p.x + p.drift * progress) * size.width;
      final y = (p.y + p.speed * progress) * size.height;
      final angle = p.rotation + p.rotationSpeed * progress;

      if (y < 0 || y > size.height || x < 0 || x > size.width) continue;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
        Paint()
          ..color = p.color.withValues(alpha: opacity * 0.8)
          ..style = PaintingStyle.fill,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiCustomPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
