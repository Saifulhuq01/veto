import 'dart:ui';

import 'package:flutter/material.dart';

/// Spatial Glass design system color palette.
/// Derived from DESIGN.md — obsidian dark-mode with atmospheric light physics.
class VetoColors {
  VetoColors._();

  // ── Canvas ──
  static const Color canvasBase = Color(0xFF05050A);

  // ── Surface hierarchy ──
  static const Color surface = Color(0xFF131319);
  static const Color surfaceDim = Color(0xFF131319);
  static const Color surfaceBright = Color(0xFF393840);
  static const Color surfaceContainerLowest = Color(0xFF0E0E14);
  static const Color surfaceContainerLow = Color(0xFF1B1B22);
  static const Color surfaceContainer = Color(0xFF1F1F26);
  static const Color surfaceContainerHigh = Color(0xFF2A2930);
  static const Color surfaceContainerHighest = Color(0xFF35343B);
  static const Color surfaceVariant = Color(0xFF35343B);

  // ── On-surface ──
  static const Color onSurface = Color(0xFFE4E1EA);
  static const Color onSurfaceVariant = Color(0xFFC4C7C8);
  static const Color inverseSurface = Color(0xFFE4E1EA);
  static const Color inverseOnSurface = Color(0xFF303037);

  // ── Primary ──
  static const Color primary = Color(0xFFFFFFFF);
  static const Color onPrimary = Color(0xFF2F3131);
  static const Color primaryContainer = Color(0xFFE2E2E2);
  static const Color onPrimaryContainer = Color(0xFF636565);
  static const Color inversePrimary = Color(0xFF5D5F5F);
  static const Color primaryFixed = Color(0xFFE2E2E2);
  static const Color primaryFixedDim = Color(0xFFC6C6C7);

  // ── Secondary (Emerald) ──
  static const Color secondary = Color(0xFF4EDEA3);
  static const Color onSecondary = Color(0xFF003824);
  static const Color secondaryContainer = Color(0xFF00A572);
  static const Color onSecondaryContainer = Color(0xFF00311F);
  static const Color secondaryFixed = Color(0xFF6FFBBE);
  static const Color secondaryFixedDim = Color(0xFF4EDEA3);

  // ── Tertiary ──
  static const Color tertiary = Color(0xFFFFFFFF);
  static const Color onTertiary = Color(0xFF1000A9);
  static const Color tertiaryContainer = Color(0xFFE1E0FF);
  static const Color onTertiaryContainer = Color(0xFF4F51DD);
  static const Color tertiaryFixed = Color(0xFFE1E0FF);
  static const Color tertiaryFixedDim = Color(0xFFC0C1FF);

  // ── Error ──
  static const Color error = Color(0xFFFFB4AB);
  static const Color onError = Color(0xFF690005);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onErrorContainer = Color(0xFFFFDAD6);

  // ── Outline ──
  static const Color outline = Color(0xFF8E9192);
  static const Color outlineVariant = Color(0xFF444748);

  // ── Atmospheric orbs ──
  static const Color orbIndigo = Color(0xFF4F46E5);
  static const Color orbFuchsia = Color(0xFFD946EF);

  // ── Glass surfaces ──
  static const Color glassWhite5 = Color(0x0DFFFFFF);   // 5% white
  static const Color glassWhite10 = Color(0x1AFFFFFF);  // 10% white
  static const Color glassWhite15 = Color(0x26FFFFFF);  // 15% white
  static const Color glassWhite20 = Color(0x33FFFFFF);  // 20% white
  static const Color glassBorder = Color(0x1AFFFFFF);   // 10% white border
  static const Color glassInnerGlow = Color(0x26FFFFFF); // 15% white inset

  // ── Functional ──
  static const Color emeraldActive = Color(0xCC10B981); // emerald-500 @ 80%
  static const Color fuchsiaTag = Color(0x33D946EF);    // fuchsia @ 20%
  static const Color fuchsiaTagText = Color(0xFFF0ABFC);
  static const Color emeraldTag = Color(0x1A10B981);
  static const Color emeraldTagText = Color(0xFF6EE7B7);
}
