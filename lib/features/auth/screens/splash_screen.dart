import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _loadingController;
  late AnimationController _dotsController;
  late Animation<double> _logoFade;
  late Animation<Offset> _logoSlide;
  late Animation<double> _loadingAnim;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );
    _logoSlide =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutCubic),
    );

    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _loadingAnim =
        Tween<double>(begin: 0, end: 1).animate(_loadingController);

    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _loadingController.forward();
    });

    Timer(const Duration(milliseconds: 2800), () async {
      if (!mounted) return;
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // User is logged in — check their role in Firestore
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          final role = doc.data()?['role'] as String? ?? 'customer';
          if (!mounted) return;
          if (role == 'business' || role == 'admin') {
            context.go('/dashboard');
          } else {
            context.go('/home');
          }
        } else {
          // User is not logged in — check onboarding state
          final prefs = await SharedPreferences.getInstance();
          final onboardingDone = prefs.getBool('onboarding_completed') ?? false;
          if (!mounted) return;
          if (onboardingDone) {
            context.go('/role-selection');
          } else {
            context.go('/onboarding');
          }
        }
      } catch (_) {
        if (mounted) context.go('/onboarding');
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _loadingController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.dark),
        child: Stack(
          children: [
            // Floating dots
            ...List.generate(5, (i) => _buildDot(i)),
            // Main content
            Center(
              child: FadeTransition(
                opacity: _logoFade,
                child: SlideTransition(
                  position: _logoSlide,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLogo(),
                      const SizedBox(height: 20),
                      Text(
                        'QueueLess',
                        style: AppTextStyles.display.copyWith(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Skip the Wait. Book Smart.',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.primaryLight,
                          fontSize: 15,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Loading bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 80,
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _loadingAnim,
                    builder: (_, __) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: _loadingAnim.value,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primary),
                          minHeight: 3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Powered by AI',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.4),
                      letterSpacing: 2,
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

  Widget _buildLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(alpha: 0.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 40,
            spreadRadius: 10,
          )
        ],
      ),
      child: CustomPaint(size: const Size(120, 120), painter: _LogoPainter()),
    );
  }

  Widget _buildDot(int index) {
    final size = math.Random(index).nextDouble() * 8 + 4;
    final x = math.Random(index * 7).nextDouble();
    final y = math.Random(index * 11).nextDouble();
    return AnimatedBuilder(
      animation: _dotsController,
      builder: (_, __) {
        final offset = math.sin((_dotsController.value + index * 0.2) * 2 * math.pi) * 12;
        return Positioned(
          left: MediaQuery.of(context).size.width * x,
          top: MediaQuery.of(context).size.height * y + offset,
          child: Opacity(
            opacity: 0.15 + 0.1 * math.sin((_dotsController.value + index * 0.3) * math.pi),
            child: Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Q circle
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 8;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2 - 8), 28, paint);

    // Q tail
    final path = Path()
      ..moveTo(size.width / 2 + 14, size.height / 2 + 10)
      ..lineTo(size.width / 2 + 30, size.height / 2 + 28);
    paint.style = PaintingStyle.stroke;
    paint.strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint);

    // Wave lines
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3;
    paint.color = AppColors.primaryLight;
    for (int i = 0; i < 3; i++) {
      final y = size.height / 2 + 32 + i * 10;
      final wavePath = Path();
      wavePath.moveTo(20, y);
      for (double x = 20; x < size.width - 20; x += 8) {
        wavePath.quadraticBezierTo(x + 4, y - 5, x + 8, y);
      }
      canvas.drawPath(wavePath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
