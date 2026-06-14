import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/utils/nav_helper.dart';
import '../../../shared/widgets/premium_button.dart';
import '../../../shared/widgets/premium_input.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/animated_card.dart';

class LoginScreen extends StatefulWidget {
  final String? initialRole;
  const LoginScreen({super.key, this.initialRole});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _navigateByRole() async {
    final uid = FirebaseService.instance.getCurrentUser()?.uid;
    if (uid == null) { context.go('/home'); return; }
    
    if (widget.initialRole != null) {
      await FirebaseService.instance.updateUser(uid, {'role': widget.initialRole!});
    }

    final user = await FirebaseService.instance.getUserById(uid);
    if (mounted) {
      if (user?.role == 'business') {
        final biz = await FirebaseService.instance.getBusinessByOwner(uid);
        if (mounted) {
          if (biz != null) {
            context.go('/dashboard');
          } else {
            context.go('/business-register');
          }
        }
      } else {
        context.go('/home');
      }
    }
  }

  Future<void> _signIn() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _error = 'Please enter both email and password.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await FirebaseService.instance.signInWithEmail(
        _emailCtrl.text.trim(), _passCtrl.text);
      if (mounted) await _navigateByRole();
    } catch (e) {
      print('Login error: $e');
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() { _loading = true; _error = null; });
    try {
      final cred = await FirebaseService.instance.signInWithGoogle(role: widget.initialRole ?? 'customer');
      if (cred != null && mounted) await _navigateByRole();
    } catch (e) {
      setState(() => _error = 'Google Sign-In failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: AppBackButton(fallback: '/role-selection'),
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            ClipPath(
              clipper: _WaveClipper(),
              child: Container(
                height: 240,
                decoration: const BoxDecoration(gradient: AppGradients.primary),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_rounded, color: Colors.white, size: 40),
                      const SizedBox(height: 12),
                      Text('Welcome Back',
                          style: AppTextStyles.h1.copyWith(color: Colors.white)),
                      Text('Sign in to continue',
                          style: AppTextStyles.body.copyWith(color: Colors.white70)),
                    ],
                  ),
                ),
              ),
            ),
            // Form
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_error != null)
                    GlassContainer.error(
                      padding: const EdgeInsets.all(12),
                      child: Row(children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.coralError, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.coralError))),
                      ]),
                    ),
                  if (_error != null) const SizedBox(height: 16),
                  PremiumInput(
                    key: const Key('login_email_field'),
                    controller: _emailCtrl,
                    label: 'Email',
                    hint: 'Enter your email',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  PremiumInput(
                    key: const Key('login_password_field'),
                    controller: _passCtrl,
                    label: 'Password',
                    hint: 'Enter your password',
                    obscureText: true,
                    prefixIcon: Icons.lock_outline_rounded,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _signIn(),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push('/forgot-password'),
                      child: Text('Forgot Password?',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  PremiumButton(
                    key: const Key('login_submit_btn'),
                    label: 'Sign In',
                    isLoading: _loading,
                    onPressed: _loading ? null : _signIn,
                    icon: Icons.login_rounded,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('or continue with',
                            style: AppTextStyles.caption.copyWith(color: AppColors.textHint)),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(children: [
                    Expanded(
                      child: AnimatedCard(
                        key: const Key('phone_login_btn'),
                        onTap: () => context.push('/phone-login'),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        border: const BorderSide(color: AppColors.border, width: 1.5),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.phone_android_rounded, size: 22, color: AppColors.textPrimary),
                          const SizedBox(width: 8),
                          Text('Phone', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AnimatedCard(
                        key: const Key('google_login_btn'),
                        onTap: _loading ? null : _signInWithGoogle,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        border: const BorderSide(color: AppColors.border, width: 1.5),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.g_mobiledata_rounded, size: 26, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text('Google', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 32),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        if (widget.initialRole != null) {
                          context.go('/register?role=${widget.initialRole}');
                        } else {
                          context.go('/register');
                        }
                      },
                      child: Text.rich(
                        TextSpan(
                          text: "Don't have an account? ",
                          style: AppTextStyles.body,
                          children: [
                            TextSpan(
                              text: 'Register',
                              style: AppTextStyles.body.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600),
                            )
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

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SocialButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: AppColors.textPrimary),
            const SizedBox(width: 10),
            Text(label, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
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
