import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/veto_colors.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../core/widgets/paywall_sheet.dart';
import '../../directives/providers/accessibility_provider.dart';
import '../providers/timer_provider.dart';
import '../providers/profiles_provider.dart';
import '../providers/blocked_apps_provider.dart';
import '../providers/subscription_provider.dart';
import 'widgets/stats_pills.dart';
import 'widgets/timer_centerpiece.dart';
import 'widgets/emergency_bypass_sheet.dart';
import 'widgets/weekly_report_card.dart';

/// Focus Dashboard — the main screen of Veto.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibility = ref.watch(accessibilityProvider);
    final timerState = ref.watch(timerProvider);

    if (timerState.isRunning) {
      return SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 80), // Space for floating top nav
            
            // ── Accessibility Permission Required Banner ──
            if (!accessibility.isEnabled) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: GlassPanel(
                  borderRadius: 14,
                  blurSigma: 24,
                  fillOpacity: 0.08,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: VetoColors.error,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Accessibility Service Required',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Enable Veto to run node-blocking rules.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                        onPressed: () => ref.read(accessibilityProvider.notifier).openSettings(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // ── Stats pills ──
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: StatsPills(),
            ),

            // ── Timer centerpiece ──
            const Expanded(
              child: Center(
                child: TimerCenterpiece(),
              ),
            ),
            
            // ── Bottom action ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: GlassButton(
                label: 'Bypass Lockdown',
                icon: Icons.lock_open,
                color: VetoColors.error,
                onPressed: () => EmergencyBypassSheet.show(context),
                isExpanded: true,
              ),
            ),
            const SizedBox(height: 64), // Space for floating nav island
          ],
        ),
      );
    }

    // Idle / configuration state: Scrollable screen with Weekly Focus Report
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 80), // Space for floating top nav
            
            // ── Accessibility Permission Required Banner ──
            if (!accessibility.isEnabled) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: GlassPanel(
                  borderRadius: 14,
                  blurSigma: 24,
                  fillOpacity: 0.08,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: VetoColors.error,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Accessibility Service Required',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Enable Veto to run node-blocking rules.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                        onPressed: () => ref.read(accessibilityProvider.notifier).openSettings(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // ── Stats pills ──
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: StatsPills(),
            ),

            // ── Focus Profiles Selector ──
            const SizedBox(height: 24),
            const _ProfilesSelector(),

            // ── Timer centerpiece (not expanded) ──
            const SizedBox(height: 32),
            const Center(
              child: TimerCenterpiece(),
            ),

            // ── Weekly focus report bar chart ──
            const SizedBox(height: 32),
            const WeeklyReportCard(),

            // ── Bottom action ──
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GlassButton(
                label: 'Engage Lockdown',
                icon: Icons.lock,
                onPressed: () => ref.read(timerProvider.notifier).start(),
                isExpanded: true,
              ),
            ),
            const SizedBox(height: 120), // Extra space for bottom navigation island
          ],
        ),
      ),
    );
  }
}

/// Horizontal selection list for Focus Profiles.
class _ProfilesSelector extends ConsumerWidget {
  const _ProfilesSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(focusProfilesProvider);
    final isPro = ref.watch(subscriptionProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'FOCUS PROFILES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: VetoColors.onSurfaceVariant,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 64,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            itemCount: state.profiles.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final profile = state.profiles[index];
              final isSelected = profile.id == state.selectedProfileId;
              final isLocked = !isPro && profile.id != 'deep_work';

              return GestureDetector(
                onTap: () {
                  if (isLocked) {
                    PaywallSheet.show(context, customMessage: 'Focus profiles are a Veto Pro feature.');
                  } else {
                    ref.read(focusProfilesProvider.notifier).selectProfile(profile.id);
                    ref.read(timerProvider.notifier).setDuration(profile.durationMinutes);
                    ref.read(blockedAppsProvider.notifier).applyProfileBlockedPackages(profile.blockedPackages);
                  }
                },
                child: GlassPanel(
                  borderRadius: 14,
                  blurSigma: 24,
                  fillOpacity: isSelected ? 0.12 : 0.04,
                  borderColor: isSelected
                      ? VetoColors.emeraldActive.withValues(alpha: 0.5)
                      : VetoColors.glassBorder,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        IconData(profile.iconCode, fontFamily: 'MaterialIcons'),
                        color: isSelected ? VetoColors.emeraldActive : Colors.white60,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                profile.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? Colors.white : Colors.white70,
                                ),
                              ),
                              if (isLocked) ...[
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.lock,
                                  color: Colors.white.withValues(alpha: 0.4),
                                  size: 11,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${profile.durationMinutes} min',
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected
                                  ? VetoColors.emeraldActive.withValues(alpha: 0.8)
                                  : Colors.white38,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

