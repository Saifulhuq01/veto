import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/spatial_glass_theme.dart';
import 'core/theme/veto_colors.dart';
import 'core/widgets/ambient_background.dart';
import 'core/widgets/floating_nav_island.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/directives/presentation/directives_screen.dart';
import 'features/planner/presentation/planner_screen.dart';

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
      home: const VetoShell(),
    );
  }
}

/// Main shell with ambient background, floating top nav, content pages,
/// and floating bottom nav island.
class VetoShell extends StatefulWidget {
  const VetoShell({super.key});

  @override
  State<VetoShell> createState() => _VetoShellState();
}

class _VetoShellState extends State<VetoShell> {
  int _currentIndex = 0;

  static const _pages = [
    DashboardScreen(),
    PlannerScreen(),
    DirectivesScreen(),
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

/// Floating glass top navigation bar — "Veto" brand + menu/settings buttons.
class _FloatingTopNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.symmetric(horizontal: 24),
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
                  // Menu
                  _NavButton(
                    icon: Icons.menu,
                    onTap: () {},
                  ),
                  // Brand
                  const Text(
                    'Veto',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.32,
                    ),
                  ),
                  // Settings
                  _NavButton(
                    icon: Icons.settings,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
  }
}
