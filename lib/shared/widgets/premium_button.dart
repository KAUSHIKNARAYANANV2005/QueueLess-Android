import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Premium animated button with gradient, shimmer press effect, and loading state.
class PremiumButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Gradient? gradient;
  final Color? color;
  final Color? foregroundColor;
  final double height;
  final double? width;
  final double borderRadius;
  final TextStyle? textStyle;

  const PremiumButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.gradient,
    this.color,
    this.foregroundColor,
    this.height = 52,
    this.width,
    this.borderRadius = AppRadius.full,
    this.textStyle,
  });

  const PremiumButton.secondary({
    Key? key,
    required String label,
    VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
  }) : this(
          key: key,
          label: label,
          onPressed: onPressed,
          isLoading: isLoading,
          icon: icon,
          gradient: null,
          color: Colors.transparent,
          foregroundColor: AppColors.primary,
        );

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) {
    if (widget.onPressed != null && !widget.isLoading) _pressCtrl.forward();
  }

  void _onTapUp(_) => _pressCtrl.reverse();
  void _onTapCancel() => _pressCtrl.reverse();

  @override
  Widget build(BuildContext context) {
    final gradient = widget.gradient ?? AppGradients.primary;
    final isPrimary = widget.color == null || widget.color == AppColors.primary;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: (widget.onPressed != null && !widget.isLoading) ? widget.onPressed : null,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: isPrimary ? gradient : null,
            color: isPrimary ? null : widget.color,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: isPrimary
                ? null
                : Border.all(color: AppColors.primary, width: 1.5),
            boxShadow: (widget.onPressed != null && !widget.isLoading && isPrimary)
                ? AppShadows.glow(AppColors.primary, intensity: 0.25)
                : null,
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: isPrimary
                          ? Colors.white
                          : (widget.foregroundColor ?? AppColors.primary),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          size: 20,
                          color: isPrimary
                              ? Colors.white
                              : (widget.foregroundColor ?? AppColors.primary),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: widget.textStyle ??
                            AppTextStyles.button.copyWith(
                              color: isPrimary
                                  ? Colors.white
                                  : (widget.foregroundColor ?? AppColors.primary),
                            ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
