import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Animated card that lifts on hover/press with smooth shadow transition.
class AnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final Gradient? gradient;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double elevationBase;
  final double elevationHover;
  final List<BoxShadow>? baseShadow;
  final List<BoxShadow>? hoverShadow;
  final double? width;
  final double? height;
  final BorderSide? border;

  const AnimatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.gradient,
    this.borderRadius = AppRadius.lg,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.elevationBase = 0,
    this.elevationHover = 4,
    this.baseShadow,
    this.hoverShadow,
    this.width,
    this.height,
    this.border,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseShadow = widget.baseShadow ?? AppShadows.e1;
    final hoverShadow = widget.hoverShadow ?? AppShadows.e3;

    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => _ctrl.forward() : null,
      onTapUp: widget.onTap != null ? (_) => _ctrl.reverse() : null,
      onTapCancel: widget.onTap != null ? () => _ctrl.reverse() : null,
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.gradient == null ? (widget.color ?? AppColors.card) : null,
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: baseShadow,
            border: widget.border != null ? Border.fromBorderSide(widget.border!) : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// A stat card with icon, value, label, and optional trend indicator.
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? trend;
  final bool trendUp;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
    this.trendUp = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const Spacer(),
            if (trend != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (trendUp ? AppColors.teal : AppColors.coral).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    trendUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                    size: 10,
                    color: trendUp ? AppColors.teal : AppColors.coral,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    trend!,
                    style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: trendUp ? AppColors.teal : AppColors.coral,
                    ),
                  ),
                ]),
              ),
          ]),
          const SizedBox(height: 10),
          Text(value, style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
