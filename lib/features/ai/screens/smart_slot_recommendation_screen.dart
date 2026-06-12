import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class SmartSlotRecommendationScreen extends StatelessWidget {
  const SmartSlotRecommendationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final slots = [
      {'time': '10:00 AM', 'score': 95, 'reason': 'Lowest expected wait time'},
      {'time': '2:30 PM', 'score': 88, 'reason': 'Post-lunch lull period'},
      {'time': '4:00 PM', 'score': 82, 'reason': 'Moderate traffic expected'},
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Slot Suggestions'), leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => context.pop())),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(14)),
              child: const Row(children: [
                Icon(Icons.auto_awesome_rounded, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('AI analyzed 1,000+ past appointments to\nfind the best slots for you.', style: TextStyle(color: Colors.white, fontSize: 13))),
              ]),
            ),
            const SizedBox(height: 20),
            Text('Best Slots for Today', style: AppTextStyles.h3),
            const SizedBox(height: 12),
            ...slots.asMap().entries.map((e) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: AppShadows.e1, border: Border.all(color: e.key == 0 ? AppColors.tealSuccess : AppColors.border, width: e.key == 0 ? 1.5 : 1)),
              child: Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: e.key == 0 ? AppColors.tealSuccess : AppColors.inputBg, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text('${e.value['score']}', style: TextStyle(color: e.key == 0 ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w800, fontSize: 14)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e.value['time'] as String, style: AppTextStyles.h4),
                  Text(e.value['reason'] as String, style: AppTextStyles.caption),
                  if (e.key == 0) Padding(padding: const EdgeInsets.only(top: 4), child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.tealSuccess.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.full)), child: const Text('Best Choice', style: TextStyle(color: AppColors.tealSuccess, fontSize: 10, fontWeight: FontWeight.w700)))),
                ])),
                ElevatedButton(onPressed: () => context.go('/booking-confirmation'), style: ElevatedButton.styleFrom(backgroundColor: e.key == 0 ? AppColors.tealSuccess : AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), minimumSize: Size.zero), child: const Text('Pick')),
              ]),
            )),
          ],
        ),
      ),
    );
  }
}
