import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'bridge/veto_method_channel.dart';
import 'core/theme/spatial_glass_theme.dart';
import 'core/theme/veto_colors.dart';
import 'core/widgets/ambient_background.dart';
import 'core/widgets/floating_nav_island.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/dashboard/providers/timer_provider.dart';
import 'features/directives/presentation/directives_screen.dart';
import 'features/planner/presentation/planner_screen.dart';
import 'features/dashboard/providers/streak_provider.dart';
import 'features/dashboard/providers/subscription_provider.dart';
import 'features/directives/providers/accessibility_provider.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
import 'features/onboarding/providers/onboarding_provider.dart';
import 'core/widgets/glass_panel.dart';
import 'core/widgets/glass_button.dart';
import 'core/widgets/animated_streak_flame.dart';
import 'features/analytics/presentation/analytics_screen.dart';
import 'features/rewards/presentation/rewards_sheet.dart';
import 'features/bedtime/presentation/bedtime_settings.dart';
import 'features/sounds/presentation/ambient_sound_panel.dart';
import 'features/settings/providers/backup_provider.dart';
import 'features/directives/presentation/widgets/block_screen_customizer.dart';
import 'package:rive/rive.dart' hide RadialGradient;


/// Veto app shell — MaterialApp with spatial glass theme,
/// ambient background, floating nav island, and page switching.
class VetoApp extends StatelessWidget {
  const VetoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Veto',
      debugShowCheckedModeBanner: false,
      theme: SpatialGlassTheme.darkTheme,
      home: const _VetoEntryPoint(),
    );
  }
}

/// Entry point that routes to Onboarding or VetoShell based on first-launch status.
class _VetoEntryPoint extends ConsumerWidget {
  const _VetoEntryPoint();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboarding = ref.watch(onboardingProvider);

    if (onboarding.isLoading) {
      return const Scaffold(
        backgroundColor: VetoColors.canvasBase,
        body: Center(
          child: CircularProgressIndicator(color: VetoColors.secondary),
        ),
      );
    }

    if (onboarding.isCompleted) {
      return const VetoShell();
    }

    return OnboardingScreen(
      onComplete: () {
        // Force rebuild to show VetoShell
        ref.invalidate(onboardingProvider);
      },
    );
  }
}

/// Main shell with ambient background, floating top nav, content pages,
/// and floating bottom nav island.
class VetoShell extends ConsumerStatefulWidget {
  const VetoShell({super.key});

  @override
  ConsumerState<VetoShell> createState() => _VetoShellState();
}

class _VetoShellState extends ConsumerState<VetoShell> {
  int _currentIndex = 0;

  static const _pages = [
    DashboardScreen(),
    PlannerScreen(),
    DirectivesScreen(),
    AnalyticsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Set immersive system UI
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: VetoColors.canvasBase,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Register native trigger lockdown callback
    VetoMethodChannel().registerTriggerCallback(() {
      ref.read(timerProvider.notifier).start();
      // Snap to Dashboard (index 0) if not there
      if (mounted && _currentIndex != 0) {
        setState(() => _currentIndex = 0);
      }
    });

    // Restore timer state after process death — if a lockdown was active
    // when Android killed the process, resume the countdown from the
    // persisted end-time.
    ref.read(timerProvider.notifier).restoreIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ── Ambient background (RepaintBoundary isolated) ──
          const Positioned.fill(
            child: AmbientBackground(),
          ),

          // ── Page content ──
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: KeyedSubtree(
                key: ValueKey(_currentIndex),
                child: _pages[_currentIndex],
              ),
            ),
          ),

          // ── Floating top nav bar ──
          _FloatingTopNav(),

          // ── Floating bottom nav island ──
          FloatingNavIsland(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
          ),
        ],
      ),
    );
  }
}

/// Floating glass top navigation bar — "Veto" brand + achievements/settings buttons.
class _FloatingTopNav extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 0,
      right: 0,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 48, sigmaY: 48),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              constraints: const BoxConstraints(maxWidth: 448),
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
                  BoxShadow(
                    color: Color(0x4D000000),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Achievements Trophy
                  _NavButton(
                    icon: Icons.emoji_events_outlined,
                    tooltip: 'Achievements',
                    onTap: () => _showAchievementsSheet(context, ref),
                  ),
                  // Brand
                  const Text(
                    'Veto',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.32,
                    ),
                  ),
                  // Settings Control Panel
                  _NavButton(
                    icon: Icons.settings_outlined,
                    tooltip: 'Control Panel',
                    onTap: () => _showSettingsSheet(context, ref),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAchievementsSheet(BuildContext context, WidgetRef ref) {
    final streak = ref.read(streakProvider);
    final streakCount = streak.streakCount;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFA05050A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: VetoColors.glassBorder, width: 1.5),
            ),
          ),
          padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
          child: _CelebrationOverlay(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
              const Center(
                child: Icon(
                  Icons.emoji_events,
                  color: VetoColors.secondary,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'FOCUS ACHIEVEMENTS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Engage lockdown daily to unlock badges and protect your streak.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.6),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Badges Grid
              _BadgeRow(
                icon: Icons.star_border,
                title: 'Focus Apprentice',
                subtitle: 'Maintain a 3-day focus streak',
                isUnlocked: streakCount >= 3,
                requiredDays: 3,
                currentCount: streakCount,
              ),
              const SizedBox(height: 12),
              _BadgeRow(
                icon: Icons.bolt,
                title: 'Flow State Master',
                subtitle: 'Maintain a 7-day focus streak',
                isUnlocked: streakCount >= 7,
                requiredDays: 7,
                currentCount: streakCount,
              ),
              const SizedBox(height: 12),
              _BadgeRow(
                icon: Icons.shield_outlined,
                title: 'Distraction Exorcist',
                subtitle: 'Maintain a 14-day focus streak',
                isUnlocked: streakCount >= 14,
                requiredDays: 14,
                currentCount: streakCount,
              ),
              const SizedBox(height: 12),
              _BadgeRow(
                icon: Icons.spa_outlined,
                title: 'Productivity Zen',
                subtitle: 'Maintain a 30-day focus streak',
                isUnlocked: streakCount >= 30,
                requiredDays: 30,
                currentCount: streakCount,
              ),
              const SizedBox(height: 24),
              GlassButton(
                label: 'Awesome',
                onPressed: () => Navigator.pop(context),
                isExpanded: true,
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  void _showSettingsSheet(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(subscriptionProvider);
    final accessibility = ref.watch(accessibilityProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFA05050A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: VetoColors.glassBorder, width: 1.5),
            ),
          ),
          padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              const Center(
                child: Icon(
                  Icons.tune,
                  color: VetoColors.secondary,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'VETO CONTROL PANEL',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 24),

              // ── Pro Subscription Switcher ──
              GlassPanel(
                borderRadius: 16,
                blurSigma: 16,
                padding: const EdgeInsets.all(16),
                borderColor: isPro ? VetoColors.secondary.withValues(alpha: 0.3) : VetoColors.glassBorder,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isPro ? VetoColors.secondary.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
                      ),
                      child: Icon(
                        isPro ? Icons.workspace_premium : Icons.person_outline,
                        color: isPro ? VetoColors.secondary : Colors.white60,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPro ? 'Veto Pro Active' : 'Veto Free Tier',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isPro ? 'Unlimited profiles & deep blocking rules active.' : 'Upgrade to unlock all focus profiles & schedules.',
                            style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5)),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isPro,
                      activeColor: VetoColors.secondary,
                      onChanged: (val) async {
                        await ref.read(subscriptionProvider.notifier).setPro(val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'DIAGNOSTICS & SYSTEM',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: VetoColors.onSurfaceVariant, letterSpacing: 1.5),
              ),
              const SizedBox(height: 12),

              GlassPanel(
                borderRadius: 16,
                blurSigma: 16,
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    ListTile(
                      dense: true,
                      leading: Icon(
                        Icons.accessibility_new,
                        color: accessibility.isEnabled ? VetoColors.secondary : Colors.amber,
                        size: 20,
                      ),
                      title: const Text('Accessibility Permission', style: TextStyle(color: Colors.white)),
                      subtitle: Text(
                        accessibility.isEnabled ? 'Service active' : 'Service disabled',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
                      ),
                      trailing: Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.3)),
                      onTap: () => ref.read(accessibilityProvider.notifier).openSettings(),
                    ),
                    Divider(color: Colors.white.withValues(alpha: 0.05), height: 1, indent: 48),
                    ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.lock_open,
                        color: VetoColors.secondary,
                        size: 20,
                      ),
                      title: const Text('App Overlay Permission', style: TextStyle(color: Colors.white)),
                      subtitle: const Text(
                        'Required to draw block page overlays',
                        style: TextStyle(color: Colors.white24, fontSize: 11),
                      ),
                      trailing: Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.3)),
                      onTap: () async {
                        await VetoMethodChannel().requestOverlayPermission();
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'FEATURES',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: VetoColors.onSurfaceVariant, letterSpacing: 1.5),
              ),
              const SizedBox(height: 12),

              GlassPanel(
                borderRadius: 16,
                blurSigma: 16,
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 20),
                      title: const Text('Focus Coins & Rewards', style: TextStyle(color: Colors.white)),
                      subtitle: Text('Earn coins for focus sessions', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
                      trailing: Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.3)),
                      onTap: () {
                        Navigator.pop(context);
                        RewardsSheet.show(context);
                      },
                    ),
                    Divider(color: Colors.white.withValues(alpha: 0.05), height: 1, indent: 48),
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.bedtime, color: VetoColors.orbIndigo, size: 20),
                      title: const Text('Bedtime Mode', style: TextStyle(color: Colors.white)),
                      subtitle: Text('Auto-block at night', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
                      trailing: Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.3)),
                      onTap: () {
                        Navigator.pop(context);
                        BedtimeSettingsPanel.show(context);
                      },
                    ),
                    Divider(color: Colors.white.withValues(alpha: 0.05), height: 1, indent: 48),
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.music_note, color: VetoColors.orbFuchsia, size: 20),
                      title: const Text('Ambient Sounds', style: TextStyle(color: Colors.white)),
                      subtitle: Text('Background sounds for focus', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
                      trailing: Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.3)),
                      onTap: () {
                        Navigator.pop(context);
                        AmbientSoundPanel.show(context);
                      },
                    ),
                    Divider(color: Colors.white.withValues(alpha: 0.05), height: 1, indent: 48),
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.palette, color: VetoColors.secondary, size: 20),
                      title: const Text('Block Screen Style', style: TextStyle(color: Colors.white)),
                      subtitle: Text('Customize what blocked apps show', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
                      trailing: Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.3)),
                      onTap: () {
                        Navigator.pop(context);
                        BlockScreenCustomizer.show(context);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'DATA & PRIVACY',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: VetoColors.onSurfaceVariant, letterSpacing: 1.5),
              ),
              const SizedBox(height: 12),

              GlassPanel(
                borderRadius: 16,
                blurSigma: 16,
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.download, color: VetoColors.secondary, size: 20),
                      title: const Text('Export Backup', style: TextStyle(color: Colors.white)),
                      subtitle: Text('Save all settings as JSON', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
                      trailing: Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.3)),
                      onTap: () async {
                        Navigator.pop(context);
                        final success = await ref.read(backupProvider.notifier).exportData();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success ? 'Backup exported!' : 'Export failed'),
                              backgroundColor: success ? VetoColors.emeraldActive : VetoColors.error,
                            ),
                          );
                        }
                      },
                    ),
                    Divider(color: Colors.white.withValues(alpha: 0.05), height: 1, indent: 48),
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.upload, color: Colors.amber, size: 20),
                      title: const Text('Import Backup', style: TextStyle(color: Colors.white)),
                      subtitle: Text('Restore from JSON file', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
                      trailing: Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.3)),
                      onTap: () async {
                        Navigator.pop(context);
                        final success = await ref.read(backupProvider.notifier).importData();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success ? 'Backup restored! Restart app.' : 'Import failed'),
                              backgroundColor: success ? VetoColors.emeraldActive : VetoColors.error,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Privacy & Policy Details ──
              GlassButton(
                label: 'Privacy Policy & Disclosures',
                variant: GlassButtonVariant.secondary,
                onPressed: () => _showPrivacyPolicyDialog(context),
                isExpanded: true,
              ),
              const SizedBox(height: 12),
              GlassButton(
                label: 'Close',
                onPressed: () => Navigator.pop(context),
                isExpanded: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: AlertDialog(
          backgroundColor: const Color(0xFA131319),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: VetoColors.glassBorder),
          ),
          title: const Row(
            children: [
              Icon(Icons.privacy_tip, color: VetoColors.secondary),
              SizedBox(width: 12),
              Text(
                'Disclosures & Policy',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Veto strictly respects your privacy. All processing runs entirely on-device; no data is ever uploaded or transmitted over the internet.',
                    style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '1. Scoped Accessibility Service',
                    style: TextStyle(color: VetoColors.secondary, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'The Accessibility Service is used solely to detect when a blacklisted application or distracting node is active, blocking target settings edits to ensure lockdown rules remain strictly enforced.',
                    style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                  ),
                  SizedBox(height: 12),
                  Text(
                    '2. Local VPN Blocking Service',
                    style: TextStyle(color: VetoColors.secondary, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'The local VPN runs a lightweight DNS proxy on 127.0.0.1 to intercept domain lookups, redirecting distracting websites (e.g. social media) to NXDOMAIN. No actual device traffic is sent through external proxies.',
                    style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                  ),
                  SizedBox(height: 12),
                  Text(
                    '3. Foreground Service & UsageStats',
                    style: TextStyle(color: VetoColors.secondary, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'UsageStatsManager checks daily foreground active durations. When a configured app exceeds its daily limit, a system overlay locks interaction and guides the user back to the home launcher.',
                    style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('I Understand', style: TextStyle(color: VetoColors.secondary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.onTap, this.tooltip});
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

class _BadgeRow extends StatefulWidget {
  const _BadgeRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isUnlocked,
    required this.requiredDays,
    required this.currentCount,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isUnlocked;
  final int requiredDays;
  final int currentCount;

  @override
  State<_BadgeRow> createState() => _BadgeRowState();
}

class _BadgeRowState extends State<_BadgeRow> with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.isUnlocked) {
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _BadgeRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isUnlocked && !_glowController.isAnimating) {
      _glowController.repeat(reverse: true);
    } else if (!widget.isUnlocked && _glowController.isAnimating) {
      _glowController.stop();
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final glowValue = _glowController.value;
        final scale = 1.0 + (widget.isUnlocked ? 0.02 * glowValue : 0.0);
        final glowRadius = widget.isUnlocked ? 4.0 + 8.0 * glowValue : 0.0;

        return Transform.scale(
          scale: scale,
          child: GlassPanel(
            borderRadius: 14,
            blurSigma: 16,
            fillOpacity: widget.isUnlocked ? 0.08 : 0.02,
            borderColor: widget.isUnlocked
                ? VetoColors.secondary.withValues(alpha: 0.3 + 0.3 * glowValue)
                : VetoColors.glassBorder,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.isUnlocked
                            ? VetoColors.secondary.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.05),
                        border: Border.all(
                          color: widget.isUnlocked
                              ? VetoColors.secondary.withValues(alpha: 0.3 + 0.3 * glowValue)
                              : Colors.white.withValues(alpha: 0.1),
                        ),
                        boxShadow: widget.isUnlocked
                            ? [
                                BoxShadow(
                                  color: VetoColors.secondary.withValues(alpha: 0.3 * glowValue),
                                  blurRadius: glowRadius,
                                  spreadRadius: 1,
                                )
                              ]
                            : null,
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.isUnlocked ? VetoColors.secondary : Colors.white30,
                        size: 22,
                      ),
                    ),
                    if (widget.isUnlocked)
                      Positioned(
                        bottom: -4,
                        right: -4,
                        child: AnimatedStreakFlame(
                          size: 14,
                          streakCount: widget.requiredDays,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: widget.isUnlocked ? Colors.white : Colors.white38,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: widget.isUnlocked ? VetoColors.onSurfaceVariant : Colors.white24,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.isUnlocked)
                  const Icon(Icons.check_circle, color: VetoColors.secondary, size: 20)
                else ...[
                  Text(
                    '${widget.currentCount}/${widget.requiredDays} d',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Dynamic GPU-bound Rive celebration animation wrapper.
/// Plays full-screen celebration particles if 'assets/animations/celebration.riv' exists.
class _CelebrationOverlay extends StatefulWidget {
  const _CelebrationOverlay({required this.child});
  final Widget child;

  @override
  State<_CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<_CelebrationOverlay> {
  bool _useRive = false;

  @override
  void initState() {
    super.initState();
    _checkCelebrationAsset();
  }

  Future<void> _checkCelebrationAsset() async {
    try {
      await rootBundle.load('assets/animations/celebration.riv');
      if (mounted) {
        setState(() => _useRive = true);
      }
    } catch (_) {
      // Ignored: keep fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_useRive) return widget.child;

    return Stack(
      children: [
        const Positioned.fill(
          child: IgnorePointer(
            child: RiveAnimation.asset(
              'assets/animations/celebration.riv',
              fit: BoxFit.cover,
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

