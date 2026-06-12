import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/utils/nav_helper.dart';
import '../../../shared/widgets/premium_button.dart';
import '../../../shared/widgets/premium_input.dart';
import '../../../shared/widgets/glass_container.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;
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
    _emailCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_emailCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter your email address.'),
          backgroundColor: AppColors.coralError,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await FirebaseService.instance.sendPasswordResetEmail(_emailCtrl.text.trim());
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.coralError,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
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
      body: Stack(
        children: [
          // Gradient background top portion
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 260,
              decoration: const BoxDecoration(gradient: AppGradients.primary),
            ),
          ),
          // Decorative circles
          Positioned(top: -20, right: -30,
            child: Container(width: 150, height: 150, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08)))),
          Positioned(top: 80, left: -40,
            child: Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)))),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 450),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(anim),
                      child: child,
                    ),
                  ),
                  child: _sent ? _buildSuccessState() : _buildFormState(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormState() {
    return SingleChildScrollView(
      key: const ValueKey('form'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          // Icon with glass
          GlassContainer.light(
            padding: const EdgeInsets.all(22),
            borderRadius: AppRadius.full,
            child: const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 28),
          Text('Forgot Password?', style: AppTextStyles.h1.copyWith(color: Colors.white), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text("No worries! Enter your email and\nwe'll send reset instructions.",
            style: AppTextStyles.body.copyWith(color: Colors.white70), textAlign: TextAlign.center),
          const SizedBox(height: 40),
          // Form card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: AppShadows.e4,
            ),
            child: Column(children: [
              PremiumInput(
                key: const Key('forgot_email_field'),
                controller: _emailCtrl,
                label: 'Email Address',
                hint: 'Enter your email',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _send(),
              ),
              const SizedBox(height: 20),
              PremiumButton(
                key: const Key('forgot_send_btn'),
                label: 'Send Reset Link',
                isLoading: _loading,
                onPressed: _loading ? null : _send,
                icon: Icons.send_rounded,
              ),
            ]),
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            key: const Key('forgot_back_btn'),
            onPressed: () => context.safePop(fallback: '/login'),
            icon: const Icon(Icons.arrow_back_rounded, size: 16, color: AppColors.textSecondary),
            label: Text('Back to Sign In', style: AppTextStyles.body),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return Column(
      key: const ValueKey('success'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 60),
        // Animated success circle
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder: (_, v, child) => Transform.scale(scale: v, child: child),
          child: Container(
            width: 110, height: 110,
            decoration: const BoxDecoration(gradient: AppGradients.teal, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 56),
          ),
        ),
        const SizedBox(height: 28),
        Text('Email Sent! 🎉', style: AppTextStyles.h1.copyWith(color: Colors.white)),
        const SizedBox(height: 12),
        Text(
          "We've sent a password reset link to\n${_emailCtrl.text.trim()}",
          style: AppTextStyles.body.copyWith(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(AppRadius.xl), boxShadow: AppShadows.e3),
          child: Column(children: [
            PremiumButton(
              key: const Key('open_mail_btn'),
              label: 'Open Mail App',
              icon: Icons.mail_outline_rounded,
              gradient: AppGradients.teal,
              onPressed: () {},
            ),
            const SizedBox(height: 12),
            TextButton(
              key: const Key('back_to_signin_btn'),
              onPressed: () => context.go('/login'),
              child: Text('Back to Sign In', style: AppTextStyles.body.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
      ],
    );
  }
}
