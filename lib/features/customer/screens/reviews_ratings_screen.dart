import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/firebase_service.dart';
import '../../../shared/widgets/premium_button.dart';

class ReviewsRatingsScreen extends StatefulWidget {
  const ReviewsRatingsScreen({super.key});

  @override
  State<ReviewsRatingsScreen> createState() => _ReviewsRatingsScreenState();
}

class _ReviewsRatingsScreenState extends State<ReviewsRatingsScreen> {
  int _rating = 0;
  final _reviewCtrl = TextEditingController();
  bool _loading = false;

  final List<String> _ratingLabels = ['', 'Terrible', 'Bad', 'Okay', 'Good', 'Excellent!'];
  final List<Color> _ratingColors = [Colors.transparent, AppColors.coralError, Colors.orange, AppColors.amberWarning, AppColors.tealSuccess.withValues(alpha: 0.7), AppColors.tealSuccess];

  final List<Map<String, double>> _aspects = [
    {'Cleanliness': 4.5}, {'Wait Time': 3.8}, {'Staff': 4.9}, {'Value': 4.2},
  ];

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rate & Review'), leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => context.pop())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Business card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: AppShadows.e1),
              child: Row(children: [
                Container(width: 44, height: 44, decoration: const BoxDecoration(gradient: AppGradients.primary, shape: BoxShape.circle), child: const Icon(Icons.store_rounded, color: Colors.white, size: 22)),
                const SizedBox(width: 12),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Dr. Sharma Clinic', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  Text('General Consultation · Apr 5', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ])),
              ]),
            ),
            const SizedBox(height: 24),
            Center(child: Column(children: [
              Text('How was your experience?', style: AppTextStyles.h3),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => GestureDetector(
                  onTap: () => setState(() => _rating = i + 1),
                  child: AnimatedScale(
                    scale: _rating >= i + 1 ? 1.15 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.star_rounded, size: 44, color: _rating >= i + 1 ? AppColors.amberWarning : AppColors.border),
                    ),
                  ),
                )),
              ),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _rating > 0 ? _ratingLabels[_rating] : 'Tap to rate',
                  key: ValueKey(_rating),
                  style: TextStyle(color: _rating > 0 ? _ratingColors[_rating] : AppColors.textHint, fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
            ])),
            const SizedBox(height: 24),
            // Aspect ratings
            Text('Rate specific aspects', style: AppTextStyles.h4),
            const SizedBox(height: 12),
            ..._aspects.map((a) {
              final label = a.keys.first;
              final val = a.values.first;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  SizedBox(width: 90, child: Text(label, style: AppTextStyles.body)),
                  Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: val / 5, backgroundColor: AppColors.inputBg, valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary), minHeight: 6))),
                  const SizedBox(width: 8),
                  Text('${val}', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
                ]),
              );
            }),
            const SizedBox(height: 20),
            // Text review
            Text('Write your review (optional)', style: AppTextStyles.h4),
            const SizedBox(height: 8),
            TextField(
              controller: _reviewCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Share your experience with others...',
                filled: true,
                fillColor: AppColors.inputBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
              ),
            ),
            const SizedBox(height: 20),
            PremiumButton(
              label: 'Submit Review',
              isLoading: _loading,
              onPressed: _rating == 0 ? null : () async {
                setState(() => _loading = true);
                try {
                  await FirebaseService.instance.createReview('b1', 'user1', _rating.toDouble(), _reviewCtrl.text);
                  if (mounted) { context.pop(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review submitted! Thank you.'))); }
                } catch (e) {} finally { if (mounted) setState(() => _loading = false); }
              },
            ),
          ],
        ),
      ),
    );
  }
}
