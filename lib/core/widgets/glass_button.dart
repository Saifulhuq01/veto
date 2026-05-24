import 'package:flutter/material.dart';
import '../theme/veto_colors.dart';

enum GlassButtonVariant { primary, secondary, tertiary }

/// Spatial Glass button system.
/// - Primary: solid white, black text (high-contrast anchor)
/// - Secondary: glass material with white text
/// - Tertiary: transparent, border on hover
class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = GlassButtonVariant.primary,
    this.icon,
    this.isExpanded = false,
    this.height = 56,
  });

  final String label;
  final VoidCallback onPressed;
  final GlassButtonVariant variant;
  final IconData? icon;
  final bool isExpanded;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isExpanded ? double.infinity : null,
      height: height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(9999),
          splashFactory: InkSparkle.splashFactory,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 32),
            decoration: _buildDecoration(),
            child: Row(
              mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: _textColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildDecoration() {
    switch (variant) {
      case GlassButtonVariant.primary:
        return BoxDecoration(
          color: VetoColors.primary,
          borderRadius: BorderRadius.circular(9999),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1AFFFFFF),
              blurRadius: 40,
              spreadRadius: 0,
            ),
          ],
        );
      case GlassButtonVariant.secondary:
        return BoxDecoration(
          color: VetoColors.glassWhite10,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(color: VetoColors.glassBorder, width: 1),
          boxShadow: const [
            BoxShadow(
              color: VetoColors.glassInnerGlow,
              blurRadius: 1,
              offset: Offset(0, 1),
              blurStyle: BlurStyle.inner,
            ),
          ],
        );
      case GlassButtonVariant.tertiary:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(9999),
        );
    }
  }

  Color get _textColor {
    switch (variant) {
      case GlassButtonVariant.primary:
        return VetoColors.onPrimary;
      case GlassButtonVariant.secondary:
      case GlassButtonVariant.tertiary:
        return Colors.white;
    }
  }
}
