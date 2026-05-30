import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/veto_colors.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/ambient_background.dart';
import '../../../bridge/veto_method_channel.dart';
import '../providers/onboarding_provider.dart';

/// Full-screen glassmorphic onboarding experience — 4-step PageView.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, required this.onComplete});
  final VoidCallback onComplete;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;
  List<Map<String, String>> _installedApps = [];
  bool _loadingApps = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fetchInstalledApps();
  }

  Future<void> _fetchInstalledApps() async {
    final apps = await VetoMethodChannel().getInstalledApps();
    if (mounted) {
      setState(() {
        _installedApps = apps;
        _loadingApps = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
    ref.read(onboardingProvider.notifier).goToStep(page);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(child: AmbientBackground()),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),
                // Dot indicators
                _DotIndicator(
                  currentStep: state.currentStep,
                  totalSteps: state.totalSteps,
                ),
                const SizedBox(height: 24),
                // Pages
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) =>
                        ref.read(onboardingProvider.notifier).goToStep(i),
                    children: [
                      _WelcomePage(onNext: () => _goToPage(1)),
                      _ProfileSetupPage(onNext: () => _goToPage(2)),
                      _AppSelectionPage(
                        installedApps: _installedApps,
                        isLoading: _loadingApps,
                        onNext: () => _goToPage(3),
                      ),
                      _PermissionsPage(
                        onComplete: () async {
                          await ref
                              .read(onboardingProvider.notifier)
                              .completeOnboarding();
                          widget.onComplete();
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: bottomPadding + 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dot Indicator ──
class _DotIndicator extends StatelessWidget {
  const _DotIndicator({required this.currentStep, required this.totalSteps});
  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (i) {
        final isActive = i == currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isActive
                ? VetoColors.secondary
                : Colors.white.withValues(alpha: 0.2),
          ),
        );
      }),
    );
  }
}

// ── Step 1: Welcome ──
class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated logo/icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [
                  VetoColors.secondary,
                  VetoColors.orbIndigo,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: VetoColors.secondary.withValues(alpha: 0.4),
                  blurRadius: 48,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: const Icon(
              Icons.shield_outlined,
              size: 56,
              color: Colors.white,
            ),
          ).animate().scale(
                duration: 600.ms,
                curve: Curves.elasticOut,
              ),
          const SizedBox(height: 48),
          const Text(
            'Welcome to Veto',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          )
              .animate()
              .fadeIn(delay: 200.ms, duration: 500.ms)
              .slideY(begin: 0.3, end: 0),
          const SizedBox(height: 16),
          Text(
            'Your personal focus shield.\nBlock distractions at the system level,\nprotect your deep work, and build streaks.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.7),
              height: 1.5,
            ),
          )
              .animate()
              .fadeIn(delay: 400.ms, duration: 500.ms)
              .slideY(begin: 0.3, end: 0),
          const SizedBox(height: 56),
          GlassButton(
            label: 'Get Started',
            icon: Icons.arrow_forward,
            onPressed: onNext,
            isExpanded: true,
          )
              .animate()
              .fadeIn(delay: 600.ms, duration: 400.ms)
              .slideY(begin: 0.5, end: 0),
        ],
      ),
    );
  }
}

// ── Step 2: Profile Setup ──
class _ProfileSetupPage extends ConsumerWidget {
  const _ProfileSetupPage({required this.onNext});
  final VoidCallback onNext;

  static const _profiles = [
    _ProfileOption('Deep Work', Icons.laptop_mac, '45 min', 'deep_work'),
    _ProfileOption('Gym Focus', Icons.fitness_center, '60 min', 'gym'),
    _ProfileOption('Study', Icons.menu_book, '30 min', 'study'),
    _ProfileOption(
        'Night Wind-Down', Icons.nightlight_round, '20 min', 'night'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          const Icon(Icons.dashboard_customize,
              color: VetoColors.secondary, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Pick Your Focus Style',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a default profile. You can customize later.',
            style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.separated(
              itemCount: _profiles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final p = _profiles[i];
                return GlassPanel(
                  borderRadius: 16,
                  blurSigma: 24,
                  fillOpacity: 0.06,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              VetoColors.secondary.withValues(alpha: 0.15),
                        ),
                        child:
                            Icon(p.icon, color: VetoColors.secondary, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            const SizedBox(height: 2),
                            Text(p.duration,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white
                                        .withValues(alpha: 0.5))),
                          ],
                        ),
                      ),
                      const Icon(Icons.check_circle_outline,
                          color: VetoColors.secondary, size: 24),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: (100 * i).ms, duration: 300.ms)
                    .slideX(begin: 0.2, end: 0);
              },
            ),
          ),
          const SizedBox(height: 16),
          GlassButton(
            label: 'Continue',
            icon: Icons.arrow_forward,
            onPressed: onNext,
            isExpanded: true,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ProfileOption {
  const _ProfileOption(this.name, this.icon, this.duration, this.id);
  final String name;
  final IconData icon;
  final String duration;
  final String id;
}

// ── Step 3: App Selection ──
class _AppSelectionPage extends ConsumerWidget {
  const _AppSelectionPage({
    required this.installedApps,
    required this.isLoading,
    required this.onNext,
  });
  final List<Map<String, String>> installedApps;
  final bool isLoading;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(onboardingProvider).selectedAppsToBlock;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          const Icon(Icons.block, color: VetoColors.error, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Block Distractions',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Select apps to block during focus sessions.',
            style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 24),
          if (isLoading)
            const Expanded(
              child: Center(
                child:
                    CircularProgressIndicator(color: VetoColors.secondary),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: installedApps.length,
                separatorBuilder: (_, __) => Divider(
                    color: Colors.white.withValues(alpha: 0.05),
                    height: 1),
                itemBuilder: (context, i) {
                  final app = installedApps[i];
                  final pkg = app['packageName'] ?? '';
                  final name = app['appName'] ?? pkg;
                  final isSelected = selected.contains(pkg);

                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? VetoColors.error.withValues(alpha: 0.15)
                            : VetoColors.glassWhite5,
                      ),
                      child: Icon(
                        isSelected
                            ? Icons.block
                            : Icons.android,
                        color: isSelected
                            ? VetoColors.error
                            : Colors.white38,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      name,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      pkg,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    trailing: Icon(
                      isSelected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: isSelected
                          ? VetoColors.error
                          : Colors.white24,
                      size: 22,
                    ),
                    onTap: () => ref
                        .read(onboardingProvider.notifier)
                        .toggleAppToBlock(pkg),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          GlassButton(
            label: selected.isEmpty ? 'Skip for Now' : 'Continue (${selected.length} selected)',
            icon: Icons.arrow_forward,
            onPressed: onNext,
            isExpanded: true,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Step 4: Permissions ──
class _PermissionsPage extends ConsumerWidget {
  const _PermissionsPage({required this.onComplete});
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          const Icon(Icons.verified_user,
              color: VetoColors.secondary, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Grant Permissions',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Veto needs these permissions to enforce focus rules.\nAll processing stays on-device.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.6),
                height: 1.4),
          ),
          const SizedBox(height: 32),
          _PermissionTile(
            icon: Icons.accessibility_new,
            title: 'Accessibility Service',
            subtitle: 'Detects and blocks distracting app sections',
            isGranted: state.isAccessibilityEnabled,
            onTap: () async {
              await ref
                  .read(onboardingProvider.notifier)
                  .openAccessibilitySettings();
            },
          ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
          const SizedBox(height: 12),
          _PermissionTile(
            icon: Icons.query_stats,
            title: 'Usage Stats Access',
            subtitle: 'Monitors app usage to enforce daily limits',
            isGranted: state.isUsageStatsEnabled,
            onTap: () async {
              await ref
                  .read(onboardingProvider.notifier)
                  .requestUsageStatsPermission();
            },
          ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
          const SizedBox(height: 12),
          _PermissionTile(
            icon: Icons.layers,
            title: 'Display Over Other Apps',
            subtitle: 'Shows block overlay when a distraction opens',
            isGranted: state.isOverlayEnabled,
            onTap: () async {
              await ref
                  .read(onboardingProvider.notifier)
                  .requestOverlayPermission();
            },
          ).animate().fadeIn(delay: 300.ms, duration: 300.ms),
          const Spacer(),
          // Refresh permissions button
          TextButton.icon(
            onPressed: () =>
                ref.read(onboardingProvider.notifier).refreshPermissions(),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Refresh Permission Status'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),
          GlassButton(
            label: 'Launch Veto',
            icon: Icons.rocket_launch,
            onPressed: onComplete,
            isExpanded: true,
            color: state.allPermissionsGranted ? null : null,
          ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isGranted,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isGranted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isGranted ? null : onTap,
      child: GlassPanel(
        borderRadius: 16,
        blurSigma: 24,
        fillOpacity: isGranted ? 0.08 : 0.04,
        borderColor: isGranted
            ? VetoColors.secondary.withValues(alpha: 0.4)
            : VetoColors.glassBorder,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isGranted
                    ? VetoColors.secondary.withValues(alpha: 0.15)
                    : Colors.amber.withValues(alpha: 0.1),
              ),
              child: Icon(
                icon,
                color: isGranted ? VetoColors.secondary : Colors.amber,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.5))),
                ],
              ),
            ),
            Icon(
              isGranted ? Icons.check_circle : Icons.arrow_forward_ios,
              color: isGranted ? VetoColors.secondary : Colors.white30,
              size: isGranted ? 24 : 16,
            ),
          ],
        ),
      ),
    );
  }
}
