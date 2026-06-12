import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/premium_button.dart';
import '../../../shared/widgets/glass_container.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _controller = PageController();
  int _currentPage = 0;
  late AnimationController _iconCtrl;
  late Animation<double> _iconAnim;

  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      icon: Icons.queue_rounded,
      emoji: '⚡',
      color: AppColors.primary,
      title: 'Skip the Queue',
      body: 'Book appointments and track your position in real-time. No more waiting in long lines.',
      gradient: AppGradients.primary,
      features: ['Real-time tracking', 'QR token', 'Smart reminders'],
    ),
    _OnboardingPage(
      icon: Icons.smart_toy_rounded,
      emoji: '🤖',
      color: AppColors.teal,
      title: 'AI-Powered Booking',
      body: 'Chat with QueueBot to book appointments naturally. Our AI finds the perfect slot for you.',
      gradient: AppGradients.teal,
      features: ['Natural language chat', '24/7 availability', 'Smart suggestions'],
    ),
    _OnboardingPage(
      icon: Icons.store_rounded,
      emoji: '📈',
      color: AppColors.amber,
      title: 'Grow Your Business',
      body: 'Manage queues digitally, reduce no-shows, and grow your business with smart analytics.',
      gradient: AppGradients.warm,
      features: ['Live queue management', 'Staff controls', 'Revenue analytics'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _iconCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _iconAnim = CurvedAnimation(parent: _iconCtrl, curve: Curves.elasticOut);
    _iconCtrl.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _iconCtrl.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) context.go('/role-selection');
  }

  void _nextPage() {
    _controller.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOutCubic);
    _iconCtrl.reset();
    _iconCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full-screen page view
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) {
              setState(() => _currentPage = i);
              _iconCtrl.reset();
              _iconCtrl.forward();
            },
            itemCount: _pages.length,
            itemBuilder: (ctx, i) => _buildPage(_pages[i]),
          ),

          // Bottom control panel
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).padding.bottom + 24),
              decoration: const BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
                boxShadow: AppShadows.e3,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: i == _currentPage ? 28 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        gradient: i == _currentPage ? AppGradients.primary : null,
                        color: i == _currentPage ? null : AppColors.border,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                    )),
                  ),
                  const SizedBox(height: 20),
                  // Buttons
                  if (_currentPage < _pages.length - 1)
                    Row(children: [
                      TextButton(
                        key: const Key('onboarding_skip_btn'),
                        onPressed: _complete,
                        child: Text('Skip', style: AppTextStyles.body.copyWith(color: AppColors.textHint)),
                      ),
                      const Spacer(),
                      GestureDetector(
                        key: const Key('onboarding_next_btn'),
                        onTap: _nextPage,
                        child: Container(
                          width: 58, height: 58,
                          decoration: BoxDecoration(
                            gradient: _pages[_currentPage].gradient,
                            shape: BoxShape.circle,
                            boxShadow: AppShadows.glow(_pages[_currentPage].color),
                          ),
                          child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 26),
                        ),
                      ),
                    ])
                  else
                    PremiumButton(
                      key: const Key('onboarding_get_started_btn'),
                      label: 'Get Started 🚀',
                      gradient: _pages[_currentPage].gradient,
                      onPressed: _complete,
                    ),
                ],
              ),
            ),
          ),

          // Skip button top-right
          if (_currentPage < _pages.length - 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 16,
              child: SafeArea(
                child: GlassContainer.light(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  borderRadius: AppRadius.full,
                  child: GestureDetector(
                    onTap: _complete,
                    child: const Text('Skip', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    return Stack(
      children: [
        // Gradient background
        Container(decoration: BoxDecoration(gradient: page.gradient)),

        // Decorative circles
        Positioned(top: -40, right: -40,
          child: Container(width: 180, height: 180, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08)))),
        Positioned(top: 100, left: -30,
          child: Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)))),
        Positioned(bottom: 220, right: 20,
          child: Container(width: 60, height: 60, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.1)))),

        // Content
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 60, 28, 220),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Animated icon
                ScaleTransition(
                  scale: _iconAnim,
                  child: GlassContainer.light(
                    padding: const EdgeInsets.all(24),
                    borderRadius: AppRadius.xl,
                    width: 100, height: 100,
                    child: Icon(page.icon, color: Colors.white, size: 48),
                  ),
                ),
                const SizedBox(height: 32),

                // Emoji badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text('${page.emoji}  New Feature', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                ),
                const SizedBox(height: 16),

                // Title
                Text(page.title, style: AppTextStyles.display.copyWith(color: Colors.white, fontSize: 34)),
                const SizedBox(height: 12),

                // Body
                Text(page.body, style: AppTextStyles.bodyLarge.copyWith(color: Colors.white70)),
                const SizedBox(height: 28),

                // Feature chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: page.features.map((f) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(f, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 12)),
                    ]),
                  )).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final String emoji;
  final Color color;
  final String title;
  final String body;
  final LinearGradient gradient;
  final List<String> features;

  const _OnboardingPage({
    required this.icon,
    required this.emoji,
    required this.color,
    required this.title,
    required this.body,
    required this.gradient,
    required this.features,
  });
}
