import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

enum ButtonVariant { primary, secondary, ghost, danger, icon }

class PremiumButton extends StatefulWidget {
  final String? label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool isLoading;
  final Widget? leftIcon;
  final Widget? rightIcon;
  final Widget? iconWidget;
  final double? width;
  final double height;

  const PremiumButton({
    super.key,
    this.label,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.leftIcon,
    this.rightIcon,
    this.iconWidget,
    this.width,
    this.height = 52,
  });

  @override
  State<PremiumButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<PremiumButton> {
  bool _pressed = false;

  void _onTapDown(TapDownDetails _) => setState(() => _pressed = true);
  void _onTapUp(TapUpDetails _) => setState(() => _pressed = false);
  void _onTapCancel() => setState(() => _pressed = false);

  @override
  Widget build(BuildContext context) {
    switch (widget.variant) {
      case ButtonVariant.icon:
        return _buildIconButton();
      case ButtonVariant.secondary:
        return _buildSecondaryButton();
      case ButtonVariant.ghost:
        return _buildGhostButton();
      case ButtonVariant.danger:
        return _buildDangerButton();
      default:
        return _buildPrimaryButton();
    }
  }

  Widget _buildPrimaryButton() {
    return GestureDetector(
      onTapDown: widget.onPressed != null ? _onTapDown : null,
      onTapUp: widget.onPressed != null ? _onTapUp : null,
      onTapCancel: widget.onPressed != null ? _onTapCancel : null,
      onTap: widget.isLoading ? null : widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: widget.onPressed == null
                ? const LinearGradient(colors: [Color(0xFFB0AEE0), Color(0xFFB0AEE0)])
                : AppGradients.primary,
            borderRadius: BorderRadius.circular(AppRadius.full),
            boxShadow: widget.onPressed != null ? AppShadows.e2 : null,
          ),
          alignment: Alignment.center,
          child: widget.isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.leftIcon != null) ...[widget.leftIcon!, const SizedBox(width: 8)],
                    if (widget.label != null)
                      Text(
                        widget.label!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    if (widget.rightIcon != null) ...[const SizedBox(width: 8), widget.rightIcon!],
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton() {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(color: AppColors.primary, width: 1.5),
          ),
          alignment: Alignment.center,
          child: widget.isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.leftIcon != null) ...[widget.leftIcon!, const SizedBox(width: 8)],
                    if (widget.label != null)
                      Text(
                        widget.label!,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (widget.rightIcon != null) ...[const SizedBox(width: 8), widget.rightIcon!],
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildGhostButton() {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            color: const Color(0x146C63FF),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.leftIcon != null) ...[widget.leftIcon!, const SizedBox(width: 8)],
              if (widget.label != null)
                Text(
                  widget.label!,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (widget.rightIcon != null) ...[const SizedBox(width: 8), widget.rightIcon!],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDangerButton() {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B6B), Color(0xFFCC4444)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          alignment: Alignment.center,
          child: widget.isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : Text(
                  widget.label ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildIconButton() {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: AppGradients.primary,
            shape: BoxShape.circle,
            boxShadow: AppShadows.e2,
          ),
          alignment: Alignment.center,
          child: widget.iconWidget ?? const Icon(Icons.arrow_forward, color: Colors.white),
        ),
      ),
    );
  }
}
