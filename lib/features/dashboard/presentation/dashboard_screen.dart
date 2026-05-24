import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/veto_colors.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../directives/providers/accessibility_provider.dart';
import '../providers/timer_provider.dart';
import 'widgets/stats_pills.dart';
import 'widgets/timer_centerpiece.dart';

/// Focus Dashboard — the main screen of Veto.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibility = ref.watch(accessibilityProvider);

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
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    VetoColors.canvasBase.withValues(alpha: 0.8),
                    VetoColors.canvasBase,
                  ],
                  stops: const [0.0, 0.3, 1.0],
                ),
              ),
              child: Consumer(
                builder: (context, ref, _) {
                  final timerState = ref.watch(timerProvider);
                  final notifier = ref.read(timerProvider.notifier);

                  if (timerState.isRunning && !timerState.isPaused) {
                    return Row(
                      children: [
                        Expanded(
                          child: GlassButton(
                            label: 'Pause',
                            icon: Icons.pause,
                            variant: GlassButtonVariant.secondary,
                            onPressed: () => notifier.pause(),
                            isExpanded: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 56,
                          height: 56,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => notifier.reset(),
                              borderRadius: BorderRadius.circular(9999),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: VetoColors.glassWhite10,
                                  border: Border.all(
                                    color: VetoColors.glassBorder,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.stop,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  if (timerState.isPaused) {
                    return Row(
                      children: [
                        Expanded(
                          child: GlassButton(
                            label: 'Resume',
                            icon: Icons.play_arrow,
                            onPressed: () => notifier.resume(),
                            isExpanded: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 56,
                          height: 56,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => notifier.reset(),
                              borderRadius: BorderRadius.circular(9999),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: VetoColors.glassWhite10,
                                  border: Border.all(
                                    color: VetoColors.glassBorder,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.stop,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return GlassButton(
                    label: 'Engage Lockdown',
                    icon: Icons.lock,
                    onPressed: () => notifier.start(),
                    isExpanded: true,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 64), // Space for floating nav island
        ],
      ),
    );
  }
}
