import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/nav_helper.dart';
import '../../../shared/widgets/premium_button.dart';
import '../../../shared/widgets/premium_input.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    if (_passCtrl.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Password must be at least 6 characters.'),
        backgroundColor: AppColors.coralError,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ));
      return;
    }
    if (_passCtrl.text != _confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Passwords do not match.'),
        backgroundColor: AppColors.coralError,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ));
      return;
    }
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _loading = false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        contentPadding: const EdgeInsets.all(28),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              width: 72, height: 72,
              decoration: const BoxDecoration(gradient: AppGradients.teal, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
            ),
          ),
          const SizedBox(height: 20),
          Text('Password Updated!', style: AppTextStyles.h3, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Your password has been successfully updated.', style: AppTextStyles.body, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          PremiumButton(
            key: const Key('reset_done_btn'),
            label: 'Sign In Now',
            icon: Icons.login_rounded,
            onPressed: () { Navigator.pop(context); context.go('/login'); },
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        leading: const AppBackButton(fallback: '/login'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const SizedBox(height: 20),
          // Icon with glow
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              shape: BoxShape.circle,
              boxShadow: AppShadows.glow(AppColors.primary),
            ),
            child: const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 42),
          ),
          const SizedBox(height: 24),
          Text('New Password', style: AppTextStyles.h1, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text("Create a strong password you'll remember.", style: AppTextStyles.bodyLarge, textAlign: TextAlign.center),
          const SizedBox(height: 36),
          PremiumInput(
            key: const Key('reset_password_field'),
            controller: _passCtrl,
            label: 'New Password',
            hint: 'Min 6 characters',
            obscureText: true,
            prefixIcon: Icons.lock_outline_rounded,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          PremiumInput(
            key: const Key('reset_confirm_field'),
            controller: _confirmCtrl,
            label: 'Confirm Password',
            hint: 'Re-enter password',
            obscureText: true,
            prefixIcon: Icons.lock_outline_rounded,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _reset(),
          ),
          const SizedBox(height: 32),
          PremiumButton(
            key: const Key('reset_submit_btn'),
            label: 'Update Password',
            isLoading: _loading,
            onPressed: _loading ? null : _reset,
            icon: Icons.security_rounded,
          ),
        ]),
      ),
    );
  }
}
