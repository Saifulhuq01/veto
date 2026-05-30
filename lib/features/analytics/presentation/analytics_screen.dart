import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/veto_colors.dart';
import '../../../core/widgets/glass_panel.dart';
import '../providers/analytics_provider.dart';

/// Analytics screen — charts and insights about focus and usage history.
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(analyticsProvider);

    if (analytics.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: VetoColors.secondary),
      );
    }

    final weekData = analytics.lastNDays(7);
    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 104, 24, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analytics',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Track your focus journey and screen time trends.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 24),

            // ── Summary cards ──
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.psychology,
                    label: 'Total Focus',
                    value: _formatMinutes(analytics.totalFocusMinutes),
                    color: VetoColors.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.check_circle_outline,
                    label: 'Sessions',
                    value: '${analytics.totalSessions}',
                    color: VetoColors.orbIndigo,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.trending_up,
                    label: 'Avg/Day',
                    value: '${analytics.avgDailyFocus.round()}m',
                    color: VetoColors.orbFuchsia,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Weekly Focus Chart ──
            const Text(
              'WEEKLY FOCUS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: VetoColors.onSurfaceVariant,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            GlassPanel(
              borderRadius: 18,
              blurSigma: 24,
              fillOpacity: 0.05,
              padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
              child: SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _getMaxY(weekData),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => const Color(0xE6131319),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${rod.toY.round()}m',
                            const TextStyle(
                              color: VetoColors.secondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= weekData.length) {
                              return const SizedBox.shrink();
                            }
                            // Parse date to get day name
                            try {
                              final date = DateTime.parse(weekData[idx].date);
                              final dayName = dayLabels[date.weekday - 1];
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  dayName,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            } catch (_) {
                              return const SizedBox.shrink();
                            }
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.round()}m',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.3),
                                fontSize: 9,
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: _getMaxY(weekData) / 4,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.white.withValues(alpha: 0.05),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(weekData.length, (i) {
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: weekData[i].focusMinutes.toDouble(),
                            color: VetoColors.secondary,
                            width: 16,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6)),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: _getMaxY(weekData),
                              color: VetoColors.glassWhite5,
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Usage vs Focus Comparison ──
            const Text(
              'USAGE vs FOCUS (THIS WEEK)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: VetoColors.onSurfaceVariant,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            GlassPanel(
              borderRadius: 18,
              blurSigma: 24,
              fillOpacity: 0.05,
              padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
              child: SizedBox(
                height: 180,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval:
                          (_getMaxLineY(weekData)) / 4,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.white.withValues(alpha: 0.05),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= weekData.length) {
                              return const SizedBox.shrink();
                            }
                            try {
                              final date = DateTime.parse(weekData[idx].date);
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  dayLabels[date.weekday - 1],
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            } catch (_) {
                              return const SizedBox.shrink();
                            }
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.round()}m',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.3),
                                fontSize: 9,
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: (weekData.length - 1).toDouble(),
                    minY: 0,
                    maxY: _getMaxLineY(weekData),
                    lineBarsData: [
                      // Usage line (red/warning)
                      LineChartBarData(
                        spots: List.generate(
                            weekData.length,
                            (i) => FlSpot(
                                i.toDouble(),
                                weekData[i]
                                    .usageMinutes
                                    .toDouble())),
                        isCurved: true,
                        color: VetoColors.error.withValues(alpha: 0.7),
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: VetoColors.error.withValues(alpha: 0.05),
                        ),
                      ),
                      // Focus line (emerald/good)
                      LineChartBarData(
                        spots: List.generate(
                            weekData.length,
                            (i) => FlSpot(
                                i.toDouble(),
                                weekData[i]
                                    .focusMinutes
                                    .toDouble())),
                        isCurved: true,
                        color: VetoColors.secondary,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) =>
                              FlDotCirclePainter(
                            radius: 3,
                            color: VetoColors.secondary,
                            strokeWidth: 1,
                            strokeColor: Colors.white,
                          ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: VetoColors.secondary
                              .withValues(alpha: 0.08),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendDot(
                    color: VetoColors.error.withValues(alpha: 0.7),
                    label: 'Screen Time'),
                const SizedBox(width: 24),
                const _LegendDot(
                    color: VetoColors.secondary, label: 'Focus Time'),
              ],
            ),
            const SizedBox(height: 24),

            // ── Best Day ──
            if (analytics.bestDayThisWeek != null) ...[
              GlassPanel(
                borderRadius: 16,
                blurSigma: 24,
                fillOpacity: 0.06,
                borderColor:
                    VetoColors.secondary.withValues(alpha: 0.3),
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: VetoColors.secondary
                            .withValues(alpha: 0.15),
                      ),
                      child: const Icon(Icons.emoji_events,
                          color: VetoColors.secondary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Best Day This Week',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_formatMinutes(analytics.bestDayThisWeek!.focusMinutes)} of deep focus on ${_formatDateLabel(analytics.bestDayThisWeek!.date)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  double _getMaxY(List<DailyRecord> data) {
    final maxFocus = data.fold(0, (max, r) => r.focusMinutes > max ? r.focusMinutes : max);
    return (maxFocus + 15).toDouble().clamp(30, 500);
  }

  double _getMaxLineY(List<DailyRecord> data) {
    int maxVal = 0;
    for (final r in data) {
      if (r.usageMinutes > maxVal) maxVal = r.usageMinutes;
      if (r.focusMinutes > maxVal) maxVal = r.focusMinutes;
    }
    return (maxVal + 30).toDouble().clamp(60, 1000);
  }

  String _formatMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  String _formatDateLabel(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
    } catch (_) {
      return dateStr;
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      borderRadius: 16,
      blurSigma: 16,
      fillOpacity: 0.05,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
