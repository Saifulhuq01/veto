import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/veto_colors.dart';
import '../../providers/usage_stats_provider.dart';

/// Stats pills row — "Usage: 2h 59m" and "Focus: 0m" glass capsules.
/// Only rebuilds when usage stats change (very infrequent).
class StatsPills extends ConsumerWidget {
  const StatsPills({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usage = ref.watch(usageStatsProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Pill(
          icon: Icons.smartphone,
          iconColor: VetoColors.onSurfaceVariant,
          label: 'Usage: ${usage.usageDisplay}',
        ),
        const SizedBox(width: 16),
        _Pill(
          icon: Icons.psychology,
          iconColor: VetoColors.secondary,
          label: 'Focus: ${usage.focusDisplay}',
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(9999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 48, sigmaY: 48),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: VetoColors.onSurface,
                  height: 20 / 14,
                  letterSpacing: 0.14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
