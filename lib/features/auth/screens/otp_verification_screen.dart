import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/utils/nav_helper.dart';
import '../../../shared/widgets/premium_button.dart';
import '../../../shared/widgets/otp_input_widget.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String verificationId;
  final String phone;

  const OTPVerificationScreen({
    super.key, 
    required this.verificationId,
    required this.phone,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen>
    with SingleTickerProviderStateMixin {
  String _otp = '';
  bool _loading = false;
  int _countdown = 60;
  Timer? _timer;
  late AnimationController _successController;
  bool _showSuccess = false;
  late String _vId;

  @override
  void initState() {
    super.initState();
    _vId = widget.verificationId;
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _countdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 0) t.cancel();
      if (mounted) setState(() => _countdown--);
    });
  }

  Future<void> _resendOTP() async {
    setState(() => _loading = true);
    try {
      await FirebaseService.instance.signInWithPhone(
        widget.phone,
        (vId, resendToken) {
          setState(() {
            _vId = vId;
            _loading = false;
          });
          _startCountdown();
        },
        (error) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error.message ?? 'Failed to resend OTP')));
          setState(() => _loading = false);
        },
      );
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _verify() async {
    if (_otp.length < 6) return;
    setState(() => _loading = true);
    try {
      await FirebaseService.instance.verifyOTP(_vId, _otp);
      
      setState(() => _showSuccess = true);
      _successController.forward();
      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted) context.go('/home');
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Invalid OTP. Try again.')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _successController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(fallback: '/phone-login'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      gradient: AppGradients.teal,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.sms_outlined, color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 24),
                  Text('OTP Verification', style: AppTextStyles.h1),
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(
                      text: 'Enter the 6-digit code sent to ',
                      style: AppTextStyles.body,
                      children: [
                        TextSpan(
                          text: widget.phone,
                          style: AppTextStyles.body.copyWith(
                              color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: Text('Change number',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.primary)),
                  ),
                  const SizedBox(height: 24),
                  OTPInputWidget(onCompleted: (otp) {
                    setState(() => _otp = otp);
                    if (otp.length == 6) _verify();
                  }),
                  const SizedBox(height: 32),
                  PremiumButton(label: 'Verify', isLoading: _loading, onPressed: _verify),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Didn't receive the code? ", style: AppTextStyles.body),
                      _countdown > 0
                          ? Text(
                              'Resend in ${_countdown}s',
                              style: AppTextStyles.body.copyWith(color: AppColors.textHint),
                            )
                          : TextButton(
                              onPressed: _resendOTP,
                              child: Text('Resend',
                                  style: AppTextStyles.body.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600)),
                            ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_showSuccess)
            AnimatedBuilder(
              animation: _successController,
              builder: (_, __) => Opacity(
                opacity: _successController.value,
                child: Container(
                  color: Colors.white.withValues(alpha: 0.9),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                              gradient: AppGradients.teal, shape: BoxShape.circle),
                          child: const Icon(Icons.check_rounded,
                              color: Colors.white, size: 40),
                        ),
                        const SizedBox(height: 16),
                        Text('Verified!', style: AppTextStyles.h2.copyWith(color: AppColors.tealSuccess)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
