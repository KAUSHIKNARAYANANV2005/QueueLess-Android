import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/firebase_service.dart';
import '../../../shared/models/review_model.dart';

class ReviewManagementScreen extends StatefulWidget {
  const ReviewManagementScreen({super.key});
  @override
  State<ReviewManagementScreen> createState() => _ReviewManagementScreenState();
}

class _ReviewManagementScreenState extends State<ReviewManagementScreen> {
  List<ReviewModel> _reviews = [];
  bool _loading = true;
  String? _businessId;
  String _filter = 'All';
  final Map<String, TextEditingController> _replyCtrl = {};
  final Map<String, bool> _replyVisible = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _replyCtrl.values) c.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final biz = await FirebaseService.instance.getBusinessByOwner(uid);
      _businessId = biz?.id ?? 'b1';
    } else {
      _businessId = 'b1';
    }
    final reviews = await FirebaseService.instance.getReviews(_businessId!);
    if (mounted) setState(() { _reviews = reviews; _loading = false; });
  }

  List<ReviewModel> get _filtered {
    if (_filter == 'All') return _reviews;
    if (_filter == 'No Reply') return _reviews.where((r) => r.reply == null || r.reply!.isEmpty).toList();
    final stars = int.tryParse(_filter[0]);
    if (stars != null) return _reviews.where((r) => r.rating.round() == stars).toList();
    return _reviews;
  }

  double get _avgRating => _reviews.isEmpty ? 0.0
      : _reviews.map((r) => r.rating).reduce((a, b) => a + b) / _reviews.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Management'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => context.pop()),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load)],
      ),
      body: Column(children: [
        // Summary
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(child: _ReviewStat(value: _avgRating.toStringAsFixed(1),
                label: 'Avg Rating', icon: Icons.star_rounded, color: AppColors.amberWarning)),
            const SizedBox(width: 8),
            Expanded(child: _ReviewStat(value: '${_reviews.length}',
                label: 'Total', icon: Icons.reviews_rounded, color: AppColors.primary)),
            const SizedBox(width: 8),
            Expanded(child: _ReviewStat(
                value: '${_reviews.where((r) => r.rating >= 4).length}',
                label: 'Positive', icon: Icons.thumb_up_rounded, color: AppColors.tealSuccess)),
          ]),
        ),
        // Filter chips
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: ['All', '5 Stars', '4 Stars', '3 Stars', 'No Reply'].map((f) {
              final sel = _filter == f;
              return GestureDetector(
                onTap: () => setState(() => _filter = f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: sel ? AppGradients.primary : null,
                    color: sel ? null : Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(color: sel ? AppColors.primary : AppColors.border),
                  ),
                  child: Text(f, style: TextStyle(color: sel ? Colors.white : AppColors.textSecondary,
                      fontSize: 12, fontWeight: FontWeight.w500)),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.reviews_rounded, size: 64, color: AppColors.textHint),
                      const SizedBox(height: 12),
                      Text('No reviews yet', style: AppTextStyles.h3),
                    ]))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filtered.length,
                      itemBuilder: (ctx, i) {
                        final r = _filtered[i];
                        _replyCtrl.putIfAbsent(r.id, () => TextEditingController(text: r.reply ?? ''));
                        _replyVisible.putIfAbsent(r.id, () => false);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: AppShadows.e1),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              CircleAvatar(radius: 18, backgroundColor: AppColors.inputBg,
                                  child: Text(r.customerName.isNotEmpty ? r.customerName[0].toUpperCase() : 'U',
                                      style: AppTextStyles.h4.copyWith(color: AppColors.primary))),
                              const SizedBox(width: 10),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(r.customerName.isNotEmpty ? r.customerName : 'Anonymous', style: AppTextStyles.h4),
                                Row(children: List.generate(5, (j) =>
                                    Icon(Icons.star_rounded, size: 13,
                                        color: j < r.rating.round() ? AppColors.amberWarning : AppColors.border))),
                              ])),
                              if (r.reply?.isNotEmpty == true)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: AppColors.tealSuccess.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(AppRadius.full)),
                                  child: const Text('Replied', style: TextStyle(color: AppColors.tealSuccess, fontSize: 10, fontWeight: FontWeight.w600)),
                                ),
                            ]),
                            const SizedBox(height: 8),
                            Text(r.text, style: AppTextStyles.body),
                            if (r.reply?.isNotEmpty == true) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: AppColors.inputBg, borderRadius: BorderRadius.circular(8)),
                                child: Row(children: [
                                  const Icon(Icons.reply_rounded, size: 14, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Expanded(child: Text('Your reply: ${r.reply}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary))),
                                ]),
                              ),
                            ],
                            const SizedBox(height: 4),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 200),
                              child: _replyVisible[r.id] == true
                                  ? Column(children: [
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: _replyCtrl[r.id],
                                        maxLines: 3,
                                        decoration: InputDecoration(
                                          hintText: 'Write a reply...',
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(children: [
                                        TextButton(onPressed: () => setState(() => _replyVisible[r.id] = false),
                                            child: const Text('Cancel')),
                                        const Spacer(),
                                        ElevatedButton(
                                          onPressed: () async {
                                            final reply = _replyCtrl[r.id]?.text.trim() ?? '';
                                            if (reply.isEmpty) return;
                                            await FirebaseService.instance.replyToReview(r.id, reply);
                                            setState(() => _replyVisible[r.id] = false);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Reply posted!')));
                                            _load();
                                          },
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                          child: const Text('Post Reply'),
                                        ),
                                      ]),
                                    ])
                                  : TextButton.icon(
                                      onPressed: () => setState(() => _replyVisible[r.id] = true),
                                      icon: const Icon(Icons.reply_rounded, size: 16),
                                      label: Text(r.reply?.isNotEmpty == true ? 'Edit Reply' : 'Reply'),
                                      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                                    ),
                            ),
                          ]),
                        );
                      },
                    ),
        ),
      ]),
    );
  }
}

class _ReviewStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _ReviewStat({required this.value, required this.label, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: AppShadows.e1),
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.h3.copyWith(color: color)),
        Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
      ]),
    );
  }
}
