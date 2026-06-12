import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/nav_helper.dart';
import '../../../shared/widgets/animated_card.dart';
import '../../../shared/widgets/premium_button.dart';

class WalletPaymentScreen extends StatelessWidget {
  const WalletPaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const balance = 1250.0;
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet & Payments'), leading: const AppBackButton()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Wallet card
            Container(
              height: 160,
              decoration: BoxDecoration(gradient: AppGradients.dark, borderRadius: BorderRadius.circular(20), boxShadow: AppShadows.e3),
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.account_balance_wallet_rounded, color: Colors.white70, size: 18),
                  const SizedBox(width: 6),
                  const Text('QueueLess Wallet', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ]),
                const Spacer(),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: balance),
                  duration: const Duration(milliseconds: 1200),
                  builder: (_, val, __) => Text('₹${val.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: -1)),
                ),
                const SizedBox(height: 12),
                PremiumButton(
                  label: '+ Add Money',
                  gradient: AppGradients.teal,
                  height: 38,
                  onPressed: () {},
                ),
              ]),
            ),
            const SizedBox(height: 20),
            // Quick stats
            Row(children: [
                          Expanded(child: AnimatedCard(padding: const EdgeInsets.all(12), baseShadow: AppShadows.e1, child: _WalletStatCard(icon: Icons.arrow_upward_rounded, color: AppColors.teal, label: 'Total Added', value: '₹5,000'))),
              const SizedBox(width: 8),
              Expanded(child: AnimatedCard(padding: const EdgeInsets.all(12), baseShadow: AppShadows.e1, child: _WalletStatCard(icon: Icons.arrow_downward_rounded, color: AppColors.coral, label: 'Total Spent', value: '₹3,750'))),
              const SizedBox(width: 8),
              Expanded(child: AnimatedCard(padding: const EdgeInsets.all(12), baseShadow: AppShadows.e1, child: _WalletStatCard(icon: Icons.savings_rounded, color: AppColors.amber, label: 'Total Saved', value: '₹450'))),
            ]),
            const SizedBox(height: 20),
            // Payment methods
            AnimatedCard(
              padding: const EdgeInsets.all(16),
              baseShadow: AppShadows.e1,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Payment Methods', style: AppTextStyles.h4),
                const SizedBox(height: 12),
                ...[
                  {'label': 'UPI (user@okaxis)', 'icon': Icons.qr_code_rounded, 'isDefault': true},
                  {'label': 'SBI **** 4521', 'icon': Icons.credit_card_rounded, 'isDefault': false},
                ].map((m) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(width: 40, height: 40, decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(10)), child: Icon(m['icon'] as IconData, color: Colors.white, size: 20)),
                  title: Text(m['label'] as String, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500)),
                  trailing: m['isDefault'] as bool ? Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.full)), child: const Text('Default', style: TextStyle(color: AppColors.teal, fontSize: 11, fontWeight: FontWeight.w600))) : null,
                  dense: true,
                )),
              ]),
            ),
            const SizedBox(height: 20),
            // Transactions
            Align(alignment: Alignment.centerLeft, child: Text('Recent Transactions', style: AppTextStyles.h4)),
            const SizedBox(height: 12),
            ..._mockTransactions().map((t) => AnimatedCard(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              baseShadow: AppShadows.e1,
              child: Row(children: [
                Container(width: 40, height: 40, decoration: BoxDecoration(color: (t['credit'] as bool ? AppColors.teal : AppColors.coral).withValues(alpha: 0.12), shape: BoxShape.circle), child: Icon(t['credit'] as bool ? Icons.add_rounded : Icons.remove_rounded, color: t['credit'] as bool ? AppColors.teal : AppColors.coral)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t['label'] as String, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                  Text(t['date'] as String, style: AppTextStyles.caption),
                ])),
                Text('${t['credit'] as bool ? '+' : '-'}₹${t['amount']}', style: TextStyle(color: t['credit'] as bool ? AppColors.teal : AppColors.coral, fontWeight: FontWeight.w800, fontSize: 15)),
              ]),
            )),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _mockTransactions() => [
    {'label': 'Dr. Sharma Clinic', 'date': 'Apr 5, 2026', 'amount': 354, 'credit': false},
    {'label': 'Added via UPI', 'date': 'Apr 3, 2026', 'amount': 500, 'credit': true},
    {'label': 'Lakme Salon', 'date': 'Mar 28, 2026', 'amount': 800, 'credit': false},
    {'label': 'Refund - Cancellation', 'date': 'Mar 20, 2026', 'amount': 150, 'credit': true},
  ];
}

class _WalletStatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _WalletStatCard({required this.icon, required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(width: 32, height: 32, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 16)),
      const SizedBox(height: 6),
      Text(value, style: AppTextStyles.h4),
      Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
    ]);
  }
}
