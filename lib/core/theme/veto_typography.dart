import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Spatial Glass typography scale.
/// All stops use Inter. Hierarchy driven by weight & opacity, not color.
class VetoTypography {
  VetoTypography._();

  static TextTheme get textTheme {
    return TextTheme(
      // display-lg: 48/56, Bold, -0.02em
      displayLarge: GoogleFonts.inter(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        height: 56 / 48,
        letterSpacing: -0.96, // -0.02em * 48
      ),
      // headline-lg: 32/40, SemiBold, -0.01em
      headlineLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        height: 40 / 32,
        letterSpacing: -0.32,
      ),
      // headline-md: 24/32, SemiBold
      headlineMedium: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 32 / 24,
      ),
      // body-lg: 18/28, Regular
      bodyLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 28 / 18,
      ),
      // body-md: 16/24, Regular
      bodyMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
      ),
      // label-md: 14/20, Medium, 0.01em
      labelMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 20 / 14,
        letterSpacing: 0.14,
      ),
      // label-sm: 12/16, Medium, 0.02em
      labelSmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 16 / 12,
        letterSpacing: 0.24,
      ),
    );
  }
}
