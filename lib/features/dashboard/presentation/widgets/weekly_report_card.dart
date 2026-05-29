import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/veto_colors.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../providers/streak_provider.dart';
import '../../../../core/widgets/animated_streak_flame.dart';

class WeeklyReportCard extends ConsumerWidget {
  const WeeklyReportCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streakProvider);
    final history = streak.weeklyHistory;
    
    // Calculate stats
    final totalFocusMinutes = history.values.fold(0, (sum, val) => sum + val);
    final focusDaysCount = history.values.where((m) => m > 0).length;
    
    // Scale for chart bars
    final maxMinutes = history.values.fold(0, (m, val) => max(m, val));
    const double maxBarHeight = 100.0;
    
    final daysList = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GlassPanel(
        borderRadius: 20,
        blurSigma: 32,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'WEEKLY REPORT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: VetoColors.onSurfaceVariant,
                    letterSpacing: 1.5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: VetoColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: VetoColors.secondary.withValues(alpha: 0.3), width: 0.5),
                  ),
                  child: Text(
                    '$focusDaysCount active days',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: VetoColors.secondaryFixedDim,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Summary Stats Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Focus Time',
                        style: TextStyle(
                          fontSize: 12,
                          color: VetoColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${totalFocusMinutes ~/ 60}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            'h ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: VetoColors.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '${totalFocusMinutes % 60}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            'm',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: VetoColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Streak',
                        style: TextStyle(
                          fontSize: 12,
                          color: VetoColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${streak.streakCount}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'days ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.orangeAccent,
                            ),
                          ),
                          AnimatedStreakFlame(
                            size: 16,
                            streakCount: streak.streakCount,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Bar Chart
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: daysList.map((day) {
                final mins = history[day] ?? 0;
                final double ratio = maxMinutes > 0 ? mins / maxMinutes : 0.0;
                final double barHeight = max(10.0, ratio * maxBarHeight);
                final bool isZero = mins == 0;

                return Column(
                  children: [
                    // Bar
                    Container(
                      width: 16,
                      height: maxBarHeight,
                      alignment: Alignment.bottomCenter,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 0.5),
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutBack,
                        width: 16,
                        height: barHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: isZero
                                ? [Colors.transparent, Colors.transparent]
                                : [
                                    VetoColors.secondary,
                                    VetoColors.emeraldActive,
                                  ],
                          ),
                          boxShadow: isZero
                              ? null
                              : [
                                  BoxShadow(
                                    color: VetoColors.secondary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                    offset: const Offset(0, -2),
                                  ),
                                ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Value Label
                    Text(
                      isZero ? '-' : '${mins}m',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: isZero ? Colors.white30 : Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Day Name Label
                    Text(
                      day,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: VetoColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
