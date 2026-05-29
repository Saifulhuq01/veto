import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/veto_colors.dart';

/// Reusable glass panel — the foundational container of the Spatial Glass system.
///
/// Uses `ClipRRect` + `BackdropFilter` + inner glow border.
/// Wrap in `RepaintBoundary` at call site when the child does NOT animate.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
    this.blurSigma = 24.0,
    this.fillOpacity = 0.05,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.isCircle = false,
    this.borderColor,
  });

  final Widget child;
  final double borderRadius;
  final double blurSigma;
  final double fillOpacity;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final bool isCircle;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final shape = isCircle
        ? BoxShape.circle
        : BoxShape.rectangle;

    final radius = isCircle ? null : BorderRadius.circular(borderRadius);

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        shape: shape,
        borderRadius: radius,
      ),
      child: ClipRRect(
        borderRadius: isCircle
            ? BorderRadius.circular(width != null ? width! / 2 : 999)
            : BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blurSigma,
            sigmaY: blurSigma,
          ),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              shape: shape,
              borderRadius: radius,
              color: Colors.white.withValues(alpha: fillOpacity),
              border: Border.all(
                color: borderColor ?? VetoColors.glassBorder,
                width: 1,
              ),
              boxShadow: const [
                // Inner glow — top edge light simulation
                BoxShadow(
                  color: VetoColors.glassInnerGlow,
                  blurRadius: 1,
                  spreadRadius: 0,
                  offset: Offset(0, 1),
                  blurStyle: BlurStyle.inner,
                ),
                // Depth shadow
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 32,
                  spreadRadius: 0,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
