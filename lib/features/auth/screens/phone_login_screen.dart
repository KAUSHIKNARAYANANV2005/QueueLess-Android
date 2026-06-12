import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/firebase_service.dart';
import '../../../shared/widgets/premium_button.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/animated_card.dart';
import '../../../core/utils/nav_helper.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen>
    with SingleTickerProviderStateMixin {
  final _phoneCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty || !phone.startsWith('+')) {
      setState(() => _error = 'Enter your phone with country code (e.g. +91 98765 43210)');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await FirebaseService.instance.signInWithPhone(
        phone,
        (verificationId, resendToken) {
          if (mounted) {
            context.push('/otp', extra: {'verificationId': verificationId, 'phone': phone});
          }
        },
        (error) {
          if (mounted) setState(() {
            _error = error.message ?? 'Verification failed. Try again.';
            _loading = false;
          });
        },
      );
    } catch (e) {
      if (mounted) setState(() {
        _error = 'An error occurred. Please try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const AppBackButton(fallback: '/login'),
      ),
      body: Stack(children: [
        // Gradient top
        Positioned(top: 0, left: 0, right: 0,
          child: Container(height: 280, decoration: const BoxDecoration(gradient: AppGradients.primary))),
        Positioned(top: -30, right: -30,
          child: Container(width: 160, height: 160, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08)))),
        Positioned(top: 80, left: -40,
          child: Container(width: 110, height: 110, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)))),

        SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                const SizedBox(height: 36),

                // Icon
                GlassContainer.light(
                  padding: const EdgeInsets.all(22),
                  borderRadius: AppRadius.full,
                  child: const Icon(Icons.phone_android_rounded, color: Colors.white, size: 38),
                ),
                const SizedBox(height: 24),
                Text('Phone Login', style: AppTextStyles.h1.copyWith(color: Colors.white)),
                const SizedBox(height: 6),
                Text('We\'ll send a one-time code to verify you',
                    style: AppTextStyles.body.copyWith(color: Colors.white70), textAlign: TextAlign.center),

                const SizedBox(height: 36),

                // Form card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    boxShadow: AppShadows.e4,
                  ),
                  child: Column(children: [
                    // Country code quick selector
                    Row(children: [
                      AnimatedCard(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        border: const BorderSide(color: AppColors.border),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Text('🇮🇳', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 6),
                          Text('+91', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_drop_down_rounded, size: 18, color: AppColors.textSecondary),
                        ]),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: TextField(
                        key: const Key('phone_number_field'),
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        style: AppTextStyles.body,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _sendOTP(),
                        decoration: InputDecoration(
                          hintText: '98765 43210',
                          hintStyle: AppTextStyles.body.copyWith(color: AppColors.textHint),
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.border)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.border)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          errorText: null,
                        ),
                      )),
                    ]),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Row(children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.coralError, size: 15),
                        const SizedBox(width: 6),
                        Expanded(child: Text(_error!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.coralError))),
                      ]),
                    ],
                    const SizedBox(height: 20),
                    PremiumButton(
                      key: const Key('send_otp_btn'),
                      label: 'Send OTP',
                      isLoading: _loading,
                      onPressed: _loading ? null : _sendOTP,
                      icon: Icons.sms_rounded,
                    ),
                  ]),
                ),
                const SizedBox(height: 24),

                // Info note
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.textHint),
                  const SizedBox(width: 6),
                  Text('Your number is safe and private', style: AppTextStyles.caption),
                ]),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}
