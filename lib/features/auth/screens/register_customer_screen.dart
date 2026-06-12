import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/utils/nav_helper.dart';
import '../../../shared/widgets/premium_button.dart';
import '../../../shared/widgets/premium_input.dart';
import '../../../shared/widgets/glass_container.dart';

class RegisterCustomerScreen extends StatefulWidget {
  const RegisterCustomerScreen({super.key});

  @override
  State<RegisterCustomerScreen> createState() => _RegisterCustomerScreenState();
}

class _RegisterCustomerScreenState extends State<RegisterCustomerScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _acceptedTerms = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  int _passwordStrength(String pass) {
    if (pass.isEmpty) return 0;
    int strength = 0;
    if (pass.length >= 8) strength++;
    if (pass.contains(RegExp(r'[A-Z]'))) strength++;
    if (pass.contains(RegExp(r'[0-9]'))) strength++;
    if (pass.contains(RegExp(r'[!@#$%&*]'))) strength++;
    return strength;
  }

  Color _strengthColor(int s) {
    if (s <= 1) return AppColors.coralError;
    if (s == 2) return AppColors.amberWarning;
    if (s == 3) return AppColors.tealSuccess.withValues(alpha: 0.7);
    return AppColors.tealSuccess;
  }

  Future<void> _register() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your name');
      return;
    }
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your email');
      return;
    }
    if (!_acceptedTerms) {
      setState(() => _error = 'Please accept the terms and conditions');
      return;
    }
    if (_passCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    if (_passCtrl.text.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await FirebaseService.instance.register(
        _nameCtrl.text.trim(),
        _emailCtrl.text.trim(),
        _passCtrl.text,
        'customer',
        phone: _phoneCtrl.text.trim(),
      );
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.contains('email-already-in-use')) {
        errorMsg = 'This email is already registered. Please sign in.';
      } else if (errorMsg.contains('weak-password')) {
        errorMsg = 'Password is too weak. Use at least 6 characters.';
      } else if (errorMsg.contains('invalid-email')) {
        errorMsg = 'Please enter a valid email address.';
      } else {
        errorMsg = errorMsg.replaceAll('Exception: ', '');
      }
      setState(() => _error = errorMsg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strength = _passwordStrength(_passCtrl.text);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const AppBackButton(fallback: '/role-selection'),
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            ClipPath(
              clipper: _WaveClipper(),
              child: Container(
                height: 180,
                decoration: const BoxDecoration(gradient: AppGradients.primary),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Customer Register', style: AppTextStyles.h1.copyWith(color: Colors.white)),
                      Text('Find clinics, salons, spas & skip queues!', style: AppTextStyles.body.copyWith(color: Colors.white70)),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_error != null) ...[
                    GlassContainer.error(
                      padding: const EdgeInsets.all(12),
                      child: Row(children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.coralError, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.coralError))),
                      ]),
                    ),
                    const SizedBox(height: 12),
                  ],
                  PremiumInput(
                    key: const Key('reg_cust_name_field'),
                    label: 'Full Name',
                    hint: 'Enter your full name',
                    controller: _nameCtrl,
                    prefixIcon: Icons.person_outline,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  PremiumInput(
                    key: const Key('reg_cust_email_field'),
                    label: 'Email',
                    hint: 'your@email.com',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  PremiumInput(
                    key: const Key('reg_cust_phone_field'),
                    label: 'Phone',
                    hint: '+91 98765 43210',
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_outlined,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  ValueListenableBuilder(
                    valueListenable: _passCtrl,
                    builder: (_, __, ___) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PremiumInput(
                            key: const Key('reg_cust_password_field'),
                            label: 'Password',
                            hint: 'Min 8 chars, uppercase, number',
                            controller: _passCtrl,
                            obscureText: true,
                            prefixIcon: Icons.lock_outline,
                          ),
                          if (_passCtrl.text.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: List.generate(4, (i) => Expanded(
                                child: Container(
                                  height: 3,
                                  margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                                  decoration: BoxDecoration(
                                    color: i < strength ? _strengthColor(strength) : AppColors.border,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              )),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  PremiumInput(
                    key: const Key('reg_cust_confirm_field'),
                    label: 'Confirm Password',
                    hint: 'Re-enter password',
                    controller: _confirmCtrl,
                    obscureText: true,
                    prefixIcon: Icons.lock_outline,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _register(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _acceptedTerms,
                        onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                        activeColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.border),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
                          child: Text.rich(
                            TextSpan(
                              text: 'I agree to the ',
                              style: AppTextStyles.bodySmall,
                              children: [
                                TextSpan(text: 'Terms of Service', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                                const TextSpan(text: ' and '),
                                TextSpan(text: 'Privacy Policy', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  PremiumButton(
                    key: const Key('register_cust_submit_btn'),
                    label: 'Create Customer Account',
                    isLoading: _loading,
                    onPressed: _loading ? null : _register,
                    icon: Icons.person_add_rounded,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/login?role=customer'),
                      child: Text.rich(
                        TextSpan(
                          text: 'Already have an account? ',
                          style: AppTextStyles.body,
                          children: [
                            TextSpan(
                              text: 'Sign In',
                              style: AppTextStyles.body.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(0, size.height - 40)
      ..quadraticBezierTo(size.width / 4, size.height, size.width / 2, size.height - 20)
      ..quadraticBezierTo(size.width * 3 / 4, size.height - 40, size.width, size.height - 20)
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
