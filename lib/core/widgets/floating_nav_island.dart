import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/veto_colors.dart';

/// Floating navigation island — bottom pill nav per DESIGN.md.
/// Glass material with three icon tabs.
class FloatingNavIsland extends StatelessWidget {
  const FloatingNavIsland({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _icons = [
    Icons.timer_outlined,
    Icons.calendar_today_outlined,
    Icons.shield_outlined,
    Icons.bar_chart_outlined,
  ];

  static const _iconsFilled = [
    Icons.timer,
    Icons.calendar_today,
    Icons.shield,
    Icons.bar_chart,
  ];

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24,
      left: 0,
      right: 0,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 48, sigmaY: 48),
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: VetoColors.glassWhite10,
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
                    blurRadius: 24,
                    spreadRadius: 0,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(4, (index) {
                  final isActive = index == currentIndex;
                  return Padding(
                    padding: EdgeInsets.only(
                      left: index == 0 ? 0 : 24,
                    ),
                    child: GestureDetector(
                      onTap: () => onTap(index),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedScale(
                        scale: isActive ? 1.1 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isActive
                                  ? _iconsFilled[index]
                                  : _icons[index],
                              color: isActive
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.4),
                              size: 24,
                            ),
                            if (isActive)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
