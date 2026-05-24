import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'veto_colors.dart';
import 'veto_typography.dart';

/// Spatial Glass ThemeData — full Material 3 override for the Veto design system.
class SpatialGlassTheme {
  SpatialGlassTheme._();

  static ThemeData get darkTheme {
    final textTheme = VetoTypography.textTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: VetoColors.canvasBase,
      colorScheme: const ColorScheme.dark(
        surface: VetoColors.surface,
        onSurface: VetoColors.onSurface,
        surfaceContainerLowest: VetoColors.surfaceContainerLowest,
        surfaceContainerLow: VetoColors.surfaceContainerLow,
        surfaceContainer: VetoColors.surfaceContainer,
        surfaceContainerHigh: VetoColors.surfaceContainerHigh,
        surfaceContainerHighest: VetoColors.surfaceContainerHighest,
        primary: VetoColors.primary,
        onPrimary: VetoColors.onPrimary,
        primaryContainer: VetoColors.primaryContainer,
        onPrimaryContainer: VetoColors.onPrimaryContainer,
        inversePrimary: VetoColors.inversePrimary,
        secondary: VetoColors.secondary,
        onSecondary: VetoColors.onSecondary,
        secondaryContainer: VetoColors.secondaryContainer,
        onSecondaryContainer: VetoColors.onSecondaryContainer,
        tertiary: VetoColors.tertiary,
        onTertiary: VetoColors.onTertiary,
        tertiaryContainer: VetoColors.tertiaryContainer,
        onTertiaryContainer: VetoColors.onTertiaryContainer,
        error: VetoColors.error,
        onError: VetoColors.onError,
        errorContainer: VetoColors.errorContainer,
        onErrorContainer: VetoColors.onErrorContainer,
        outline: VetoColors.outline,
        outlineVariant: VetoColors.outlineVariant,
        inverseSurface: VetoColors.inverseSurface,
        onInverseSurface: VetoColors.inverseOnSurface,
      ),
      textTheme: textTheme.apply(
        bodyColor: VetoColors.onSurface,
        displayColor: VetoColors.onSurface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: VetoColors.canvasBase,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        indicatorColor: Colors.transparent,
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }
}
