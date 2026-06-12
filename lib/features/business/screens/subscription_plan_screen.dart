import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/premium_button.dart';

class SubscriptionPlanScreen extends StatefulWidget {
  const SubscriptionPlanScreen({super.key});

  @override
  State<SubscriptionPlanScreen> createState() => _SubscriptionPlanScreenState();
}

class _SubscriptionPlanScreenState extends State<SubscriptionPlanScreen> {
  String _selected = 'pro';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subscription Plans'), leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => context.pop())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(16)),
              child: const Column(children: [
                Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 40),
                SizedBox(height: 8),
                Text('Upgrade your plan', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                Text('Get unlimited features for your business', style: TextStyle(color: Colors.white70, fontSize: 13)),
              ]),
            ),
            const SizedBox(height: 20),
            ...[
              {'id': 'basic', 'label': 'Basic', 'price': '₹499/mo', 'features': ['50 bookings/day', 'Basic analytics', 'Email support'], 'gradient': const LinearGradient(colors: [Color(0xFFB0BEC5), Color(0xFF90A4AE)])},
              {'id': 'pro', 'label': 'Pro', 'price': '₹999/mo', 'features': ['Unlimited bookings', 'Advanced analytics', 'AI queue bot', '24/7 Priority support'], 'gradient': AppGradients.primary},
              {'id': 'enterprise', 'label': 'Enterprise', 'price': 'Custom', 'features': ['Multi-branch', 'White-label', 'API access', 'Dedicated manager'], 'gradient': AppGradients.dark},
            ].map((plan) {
              final isSelected = _selected == plan['id'];
              return GestureDetector(
                onTap: () => setState(() => _selected = plan['id'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: isSelected ? plan['gradient'] as LinearGradient : null,
                    color: isSelected ? null : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isSelected ? AppShadows.e3 : AppShadows.e1,
                    border: isSelected ? null : Border.all(color: AppColors.border),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(plan['label'] as String, style: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 20)),
                      const Spacer(),
                      Text(plan['price'] as String, style: TextStyle(color: isSelected ? Colors.white70 : AppColors.primary, fontSize: 16, fontWeight: FontWeight.w600)),
                      if (isSelected) const SizedBox(width: 8),
                      if (isSelected) Container(width: 22, height: 22, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.check_rounded, color: AppColors.primary, size: 14)),
                    ]),
                    const SizedBox(height: 10),
                    ...(plan['features'] as List<String>).map((f) => Row(children: [
                      Icon(Icons.check_circle_rounded, color: isSelected ? Colors.white70 : AppColors.tealSuccess, size: 14),
                      const SizedBox(width: 6),
                      Text(f, style: TextStyle(color: isSelected ? Colors.white70 : AppColors.textSecondary, fontSize: 13)),
                    ])),
                  ]),
                ),
              );
            }),
            const SizedBox(height: 8),
            PremiumButton(label: 'Get Started - ₹999/mo', onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Redirecting to payment...'))); }),
            const SizedBox(height: 8),
            TextButton(onPressed: () {}, child: const Text('View full comparison', style: TextStyle(color: AppColors.primary))),
          ],
        ),
      ),
    );
  }
}
