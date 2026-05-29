import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/veto_colors.dart';
import '../../../../core/widgets/animated_streak_flame.dart';
import '../../providers/usage_stats_provider.dart';
import '../../providers/streak_provider.dart';

/// Stats pills row — "Usage", "Focus", and "Streak" glass capsules.
class StatsPills extends ConsumerWidget {
  const StatsPills({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usage = ref.watch(usageStatsProvider);
    final streak = ref.watch(streakProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Pill(
          icon: Icons.smartphone,
          iconColor: VetoColors.onSurfaceVariant,
          label: usage.usageDisplay,
        ),
        const SizedBox(width: 8),
        _Pill(
          icon: Icons.psychology,
          iconColor: VetoColors.secondary,
          label: usage.focusDisplay,
        ),
        const SizedBox(width: 8),
        _Pill(
          customIcon: Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: AnimatedStreakFlame(size: 14, streakCount: streak.streakCount),
          ),
          label: '${streak.streakCount} days',
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    this.icon,
    this.iconColor,
    this.customIcon,
    required this.label,
  });

  final IconData? icon;
  final Color? iconColor;
  final Widget? customIcon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(9999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 48, sigmaY: 48),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: VetoColors.glassWhite5,
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(
              color: VetoColors.glassBorder,
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: VetoColors.glassInnerGlow,
                blurRadius: 1,
                offset: Offset(0, 1),
                blurStyle: BlurStyle.inner,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (customIcon != null)
                customIcon!
              else if (icon != null)
                Icon(icon!, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: VetoColors.onSurface,
                  height: 18 / 13,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
