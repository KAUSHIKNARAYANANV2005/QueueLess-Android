import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/firebase_service.dart';
import '../../../shared/models/queue_model.dart';
import '../../../shared/models/business_model.dart';
import '../../../shared/widgets/premium_button.dart';
import '../../../shared/widgets/animated_card.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../../shared/widgets/stats_card_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BusinessDashboardScreen extends StatefulWidget {
  const BusinessDashboardScreen({super.key});

  @override
  State<BusinessDashboardScreen> createState() => _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState extends State<BusinessDashboardScreen> {
  int _navIndex = 0;
  String? _businessId;
  BusinessModel? _business;

  @override
  void initState() {
    super.initState();
    _loadBusiness();
  }

  Future<void> _loadBusiness() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final biz = await FirebaseService.instance.getBusinessByOwner(uid);
      if (mounted && biz != null) {
        setState(() {
          _businessId = biz.id;
          _business = biz;
        });
      }
    }
    if (mounted) setState(() {}); // Trigger rebuild even if no business found
  }

  void _onNavTap(int i) {
    setState(() => _navIndex = i);
    switch (i) {
      case 0: break;
      case 1: context.go('/queue-manager'); break;
      case 2: context.go('/appointment-list'); break;
      case 3: context.go('/analytics'); break;
      case 4: context.go('/settings'); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';

    return Scaffold(
      body: _businessId == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(gradient: AppGradients.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.store_rounded, color: Colors.white, size: 48),
                  ),
                  const SizedBox(height: 20),
                  Text('No Business Found', style: AppTextStyles.h2),
                  const SizedBox(height: 8),
                  Text('Set up your business to start accepting customers and managing your queue.',
                      style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  PremiumButton(
                    label: 'Create Your Business',
                    icon: Icons.add_business_rounded,
                    onPressed: () => context.go('/business-register'),
                  ),
                ]),
              ),
            )
          : RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadBusiness,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 16, 16, 32),
                decoration: const BoxDecoration(gradient: AppGradients.primary),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(greeting + ' 👋', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                            Text(_business?.name ?? 'Dr. Sharma Clinic', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                          ]),
                        ),
                        GestureDetector(
                          onTap: () => context.push('/notifications'),
                          child: Stack(children: [
                            const Icon(Icons.notifications_outlined, color: Colors.white, size: 26),
                            Positioned(top: 0, right: 0, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.coralError, shape: BoxShape.circle))),
                          ]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Live queue card
                    StreamBuilder<QueueModel>(
                      stream: _businessId != null 
                        ? FirebaseService.instance.getQueueStream(_businessId!)
                        : const Stream.empty(),
                      builder: (ctx, snap) {
                        final q = snap.data ?? QueueModel(businessId: 'b1', currentServingToken: 'B004', totalWaiting: 7, avgWaitMinutes: 14, items: []);
                        return GlassContainer.light(
                          borderRadius: AppRadius.lg,
                          padding: const EdgeInsets.all(16),
                          child: Row(children: [
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text('Now Serving', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                              Text(q.currentServingToken, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, fontFamily: 'monospace', letterSpacing: -1)),
                            ]),
                            const Spacer(),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text('${q.totalWaiting} in queue', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              const SizedBox(height: 2),
                              Text('~${q.avgWaitMinutes} min wait', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                            ]),
                            const SizedBox(width: 12),
                            GestureDetector(
                              key: const Key('serve_next_btn_dashboard'),
                              onTap: () {
                                if (_businessId != null) FirebaseService.instance.serveNext(_businessId!);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.full), boxShadow: AppShadows.e2),
                                child: const Text('Next ▶', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                              ),
                            ),
                          ]),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Stats
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.6,
                  children: [
                    StatsCardWidget(icon: Icons.event_available_rounded, iconColor: AppColors.primary, value: '24', label: "Today's Bookings", trendPercent: 12.5, trendUp: true),
                    StatsCardWidget(icon: Icons.attach_money_rounded, iconColor: AppColors.tealSuccess, value: '₹8,240', label: "Today's Revenue", trendPercent: 8.3, trendUp: true),
                    StatsCardWidget(icon: Icons.timer_outlined, iconColor: AppColors.amberWarning, value: '14 min', label: 'Avg Wait Time', trendPercent: 5.2, trendUp: false),
                    StatsCardWidget(icon: Icons.star_rounded, iconColor: Colors.orange, value: '4.8', label: 'Rating', trendPercent: 0.2, trendUp: true),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Quick actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Quick Actions', style: AppTextStyles.h3),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _QuickActionCard(icon: Icons.queue_rounded, label: 'Manage Queue', color: AppColors.primary, onTap: () => context.go('/queue-manager'))),
                    const SizedBox(width: 10),
                    Expanded(child: _QuickActionCard(icon: Icons.people_rounded, label: 'Staff', color: AppColors.tealSuccess, onTap: () => context.go('/staff'))),
                    const SizedBox(width: 10),
                    Expanded(child: _QuickActionCard(icon: Icons.bar_chart_rounded, label: 'Analytics', color: AppColors.amberWarning, onTap: () => context.go('/analytics'))),
                    const SizedBox(width: 10),
                    Expanded(child: _QuickActionCard(icon: Icons.settings_rounded, label: 'Settings', color: AppColors.primaryDeep, onTap: () => context.go('/settings'))),
                  ]),
                ]),
              ),
              const SizedBox(height: 20),
              // Upcoming appointments
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text("Today's Appointments", style: AppTextStyles.h3),
                    TextButton(onPressed: () => context.go('/appointment-list'), child: const Text('See All', style: TextStyle(color: AppColors.primary))),
                  ]),
                  const SizedBox(height: 8),
                  ...List.generate(3, (i) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: AppShadows.e1),
                    child: Row(children: [
                      const CircleAvatar(radius: 20, backgroundColor: AppColors.inputBg, child: Icon(Icons.person_rounded, color: AppColors.textSecondary, size: 20)),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Patient ${i + 1}', style: AppTextStyles.h4),
                        Text('General Consultation · ${9 + i}:00 AM', style: AppTextStyles.caption),
                      ])),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.tealSuccess.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.full)), child: Text('#B00${i + 1}', style: const TextStyle(color: AppColors.tealSuccess, fontWeight: FontWeight.w700, fontSize: 12))),
                    ]),
                  )),
                ]),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: _navIndex, onTap: _onNavTap, isBusiness: true),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: color.withValues(alpha: 0.1),
      border: BorderSide(color: color.withValues(alpha: 0.2)),
      child: Column(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(AppRadius.sm)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11), textAlign: TextAlign.center),
      ]),
    );
  }
}
