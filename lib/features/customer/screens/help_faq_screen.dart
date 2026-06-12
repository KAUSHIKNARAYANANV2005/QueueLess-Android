import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class HelpFAQScreen extends StatelessWidget {
  const HelpFAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      {'q': 'How do I book an appointment?', 'a': 'Search for a business, select service and time slot, then pay to confirm your booking.'},
      {'q': 'Can I cancel my booking?', 'a': 'Yes, you can cancel up to 2 hours before your appointment for a full refund.'},
      {'q': 'How does the queue system work?', 'a': 'When you book, you get a token number. Track your position in real-time on the queue screen.'},
      {'q': 'What payment methods are accepted?', 'a': 'We accept UPI, credit/debit cards, net banking, and wallet payments via Razorpay.'},
      {'q': 'How accurate is the wait time?', 'a': 'Our AI predicts wait times with 90%+ accuracy based on historical data and current queue.'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Help & FAQ'), leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => context.pop())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // AI banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(gradient: AppGradients.teal, borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('QueueBot is here to help!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                  Text('Chat with our AI for instant answers', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ])),
                ElevatedButton(
                  onPressed: () => context.push('/chatbot'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.tealSuccess, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), minimumSize: Size.zero),
                  child: const Text('Chat', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            // Search
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint),
                hintText: 'Search FAQ...',
                filled: true,
                fillColor: AppColors.inputBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.full), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            // Popular topics
            Align(alignment: Alignment.centerLeft, child: Text('Popular Topics', style: AppTextStyles.h3)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 2.5,
              children: [
                {'icon': Icons.book_online_rounded, 'label': 'Booking Issues'},
                {'icon': Icons.payment_rounded, 'label': 'Payments'},
                {'icon': Icons.queue_rounded, 'label': 'Queue Status'},
                {'icon': Icons.cancel_rounded, 'label': 'Cancellations'},
              ].map((t) => Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: AppShadows.e1),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(children: [
                  Icon(t['icon'] as IconData, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(t['label'] as String, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500, fontSize: 13)),
                ]),
              )).toList(),
            ),
            const SizedBox(height: 24),
            Align(alignment: Alignment.centerLeft, child: Text('Frequently Asked Questions', style: AppTextStyles.h3)),
            const SizedBox(height: 12),
            ...faqs.map((faq) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: AppShadows.e1),
              child: ExpansionTile(
                title: Text(faq['q']!, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                iconColor: AppColors.primary,
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                children: [Text(faq['a']!, style: AppTextStyles.body)],
              ),
            )),
            const SizedBox(height: 24),
            // Contact
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: AppShadows.e1),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Still need help?', style: AppTextStyles.h4),
                const SizedBox(height: 12),
                ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.email_outlined, color: AppColors.primary), title: const Text('support@queueless.app'), dense: true),
                ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.phone_outlined, color: AppColors.primary), title: const Text('+91 80 1234 5678'), dense: true),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
