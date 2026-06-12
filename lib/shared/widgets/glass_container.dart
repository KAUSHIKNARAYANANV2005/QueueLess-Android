import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// A glassmorphism container with frosted blur effect.
/// Usage:
/// ```dart
/// GlassContainer(child: Text('Hello'));
/// GlassContainer.dark(child: Text('Dark glass'));
/// ```
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final Color? color;
  final Color? borderColor;
  final double borderRadius;
  final double borderWidth;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 12,
    this.color,
    this.borderColor,
    this.borderRadius = AppRadius.lg,
    this.borderWidth = 1.0,
    this.padding = const EdgeInsets.all(16),
    this.width,
    this.height,
    this.boxShadow,
    this.gradient,
  });

  /// Light frosted glass — for use on gradient/image backgrounds
  factory GlassContainer.light({
    Key? key,
    required Widget child,
    double blur = 16,
    double borderRadius = AppRadius.lg,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    double? width,
    double? height,
  }) {
    return GlassContainer(
      key: key,
      blur: blur,
      color: Colors.white.withValues(alpha: 0.15),
      borderColor: Colors.white.withValues(alpha: 0.3),
      borderRadius: borderRadius,
      padding: padding,
      width: width,
      height: height,
      boxShadow: AppShadows.glass,
      child: child,
    );
  }

  /// Dark frosted glass — for use on light/white backgrounds
  factory GlassContainer.dark({
    Key? key,
    required Widget child,
    double blur = 16,
    double borderRadius = AppRadius.lg,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    double? width,
    double? height,
  }) {
    return GlassContainer(
      key: key,
      blur: blur,
      color: const Color(0xFF1A1830).withValues(alpha: 0.5),
      borderColor: Colors.white.withValues(alpha: 0.1),
      borderRadius: borderRadius,
      padding: padding,
      width: width,
      height: height,
      child: child,
    );
  }

  /// Error glass — red tinted for error states
  factory GlassContainer.error({
    Key? key,
    required Widget child,
    double borderRadius = AppRadius.lg,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return GlassContainer(
      key: key,
      color: AppColors.coral.withValues(alpha: 0.1),
      borderColor: AppColors.coral.withValues(alpha: 0.3),
      borderRadius: borderRadius,
      padding: padding,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Colors.white.withValues(alpha: 0.1);
    final effectiveBorderColor = borderColor ?? Colors.white.withValues(alpha: 0.2);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: effectiveColor,
            gradient: gradient,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: effectiveBorderColor, width: borderWidth),
            boxShadow: boxShadow ?? AppShadows.glass,
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
