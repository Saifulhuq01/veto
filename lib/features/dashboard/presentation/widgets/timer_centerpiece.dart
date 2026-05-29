import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/veto_colors.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/glass_toggle.dart';
import '../../providers/timer_provider.dart';
import '../../providers/blocked_apps_provider.dart';

/// Central timer orb — the glass circle centerpiece.
class TimerCenterpiece extends ConsumerWidget {
  const TimerCenterpiece({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockedState = ref.watch(blockedAppsProvider);
    final blockedCount = blockedState.apps.where((app) => app.isBlocked).length;
    final timerState = ref.watch(timerProvider);
    final isWindDown = timerState.isWindDown;

    return GlassPanel(
      isCircle: true,
      width: 288,
      height: 288,
      blurSigma: 48,
      fillOpacity: 0.05,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            // Inner glow — premium glass depth
            BoxShadow(
              color: isWindDown
                  ? const Color(0x33FFB300)
                  : Colors.white.withValues(alpha: 0.05),
              blurRadius: 40,
              spreadRadius: 0,
              blurStyle: BlurStyle.inner,
            ),
            BoxShadow(
              color: isWindDown
                  ? const Color(0x66FFB300)
                  : Colors.white.withValues(alpha: 0.2),
              blurRadius: 4,
              spreadRadius: 0,
              offset: const Offset(0, 2),
              blurStyle: BlurStyle.inner,
            ),
            // Depth shadow
            const BoxShadow(
              color: Color(0x99000000),
              blurRadius: 60,
              spreadRadius: 0,
              offset: Offset(0, 30),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Timer text (isolated rebuild + duration picker tap) ──
            RepaintBoundary(
              child: GestureDetector(
                onTap: timerState.isRunning
                    ? null
                    : () => _showDurationPicker(context, ref),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    timerState.display,
                    style: TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.w700,
                      color: timerState.isRunning
                          ? (isWindDown ? const Color(0xFFFFB300) : Colors.white)
                          : VetoColors.secondary,
                      letterSpacing: -2,
                      height: 80 / 72,
                      shadows: [
                        Shadow(
                          color: isWindDown
                              ? const Color(0x66FFB300)
                              : const Color(0x33FFFFFF),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // ── Blocked app avatars & label (clickable to open apps sheet) ──
            GestureDetector(
              onTap: () => _showCustomizeAppsSheet(context, ref),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BlockedAppsRow(),
                  const SizedBox(height: 8),
                  Text(
                    '$blockedCount ${blockedCount == 1 ? "APP" : "APPS"} BLOCKED',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: VetoColors.onSurfaceVariant.withValues(alpha: 0.8),
                      letterSpacing: 2.0,
                      height: 16 / 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomizeAppsSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => const _CustomizeAppsSheet(),
    );
  }

  void _showDurationPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => const _DurationPickerSheet(),
    );
  }
}

/// Row of blocked app icon avatars overlapping like a stack.
class BlockedAppsRow extends ConsumerWidget {
  const BlockedAppsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockedApps = ref.watch(blockedAppsProvider).apps
        .where((app) => app.isBlocked)
        .toList();

    if (blockedApps.isEmpty) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: VetoColors.glassWhite10,
          border: Border.all(
            color: const Color(0xFF1A1B26),
            width: 2,
          ),
        ),
        child: const Icon(
          Icons.lock_open,
          color: Colors.white60,
          size: 16,
        ),
      );
    }

    const maxVisible = 4;
    final displayApps = blockedApps.take(maxVisible).toList();
    final hasExtra = blockedApps.length > maxVisible;
    final visibleCount = hasExtra ? maxVisible - 1 : displayApps.length;
    final extraCount = blockedApps.length - visibleCount;

    return SizedBox(
      height: 32,
      width: 32.0 * (visibleCount + (hasExtra ? 1 : 0)) - 8.0 * (visibleCount + (hasExtra ? 1 : 0) - 1) + 16,
      child: Stack(
        children: [
          ...List.generate(visibleCount, (i) {
            final app = displayApps[i];
            return Positioned(
              left: i * 24.0,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getCategoryColor(app.category),
                  border: Border.all(
                    color: const Color(0xFF1A1B26),
                    width: 2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  app.icon,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            );
          }),
          if (hasExtra)
            Positioned(
              left: visibleCount * 24.0,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: VetoColors.surfaceContainerHigh,
                  border: Border.all(
                    color: const Color(0xFF1A1B26),
                    width: 2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '+$extraCount',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'education':
        return VetoColors.emeraldActive;
      case 'entertainment':
        return VetoColors.orbFuchsia;
      default:
        return VetoColors.orbIndigo;
    }
  }
}

/// Sheet to customize blocked apps
class _CustomizeAppsSheet extends ConsumerWidget {
  const _CustomizeAppsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(blockedAppsProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    final educationApps = state.apps.where((app) => app.category == 'education').toList();
    final entertainmentApps = state.apps.where((app) => app.category == 'entertainment').toList();
    final otherApps = state.apps.where((app) => app.category == 'other').toList();

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Color(0xD905050A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: VetoColors.glassBorder, width: 1),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Blocked Applications',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select apps to block during lockdown',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (educationApps.isNotEmpty) ...[
                      const _CategoryHeader(label: 'EDUCATION / PRODUCTIVITY'),
                      const SizedBox(height: 12),
                      _AppCategoryList(apps: educationApps),
                      const SizedBox(height: 24),
                    ],
                    if (entertainmentApps.isNotEmpty) ...[
                      const _CategoryHeader(label: 'ENTERTAINMENT'),
                      const SizedBox(height: 12),
                      _AppCategoryList(apps: entertainmentApps),
                      const SizedBox(height: 24),
                    ],
                    if (otherApps.isNotEmpty) ...[
                      const _CategoryHeader(label: 'SOCIAL / OTHER'),
                      const SizedBox(height: 12),
                      _AppCategoryList(apps: otherApps),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.5),
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _AppCategoryList extends ConsumerWidget {
  const _AppCategoryList({required this.apps});
  final List<BlockedApp> apps;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassPanel(
      borderRadius: 16,
      blurSigma: 24,
      child: Column(
        children: List.generate(apps.length, (idx) {
          final app = apps[idx];
          final isLast = idx == apps.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(app.category).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _getCategoryColor(app.category).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Icon(app.icon, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            app.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            app.packageName,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GlassToggle(
                      value: app.isBlocked,
                      onChanged: (_) {
                        ref.read(blockedAppsProvider.notifier).toggleAppBlock(app.id);
                      },
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.05),
                  indent: 16,
                  endIndent: 16,
                ),
            ],
          );
        }),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'education':
        return VetoColors.emeraldActive;
      case 'entertainment':
        return VetoColors.orbFuchsia;
      default:
        return VetoColors.orbIndigo;
    }
  }
}

/// Sheet to pick timer duration
class _DurationPickerSheet extends ConsumerWidget {
  const _DurationPickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerProvider);
    final currentDurationMinutes = timerState.totalSeconds ~/ 60;

    const options = [
      _DurationOption(label: '15 Minutes', minutes: 15),
      _DurationOption(label: '25 Minutes (Default)', minutes: 25),
      _DurationOption(label: '45 Minutes', minutes: 45),
      _DurationOption(label: '1 Hour', minutes: 60),
      _DurationOption(label: '2 Hours', minutes: 120),
    ];

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xD905050A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: VetoColors.glassBorder, width: 1),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Set Session Duration',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GlassPanel(
              borderRadius: 16,
              blurSigma: 24,
              child: Column(
                children: List.generate(options.length, (idx) {
                  final opt = options[idx];
                  final isSelected = currentDurationMinutes == opt.minutes;
                  final isLast = idx == options.length - 1;

                  return Column(
                    children: [
                      ListTile(
                        title: Text(
                          opt.label,
                          style: TextStyle(
                            color: isSelected ? VetoColors.secondary : Colors.white,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check, color: VetoColors.secondary)
                            : null,
                        onTap: () {
                          ref.read(timerProvider.notifier).setDuration(opt.minutes);
                          Navigator.pop(context);
                        },
                      ),
                      if (!isLast)
                        Divider(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationOption {
  const _DurationOption({required this.label, required this.minutes});
  final String label;
  final int minutes;
}
