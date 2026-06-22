import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/utils/nav_helper.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/models/business_model.dart';
import '../../../shared/models/review_model.dart';
import '../../../shared/widgets/premium_button.dart';
import '../../../shared/widgets/animated_card.dart';
import '../../../shared/widgets/status_badge.dart';

class BusinessProfileScreen extends StatefulWidget {
  final String businessId;
  const BusinessProfileScreen({super.key, required this.businessId});

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFavorite = false;
  final List<String> _tabs = ['Overview', 'Services', 'Reviews', 'About'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BusinessModel?>(
      stream: FirebaseService.instance.getBusinessStream(widget.businessId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final business = snapshot.data;
        if (business == null) {
          return Scaffold(
            appBar: AppBar(leading: const AppBackButton()),
            body: const Center(child: Text('Business not found')),
          );
        }
        return Scaffold(
          body: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (ctx, inner) => [
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                leading: GestureDetector(
                  onTap: () => context.safePop(),
                  child: Container(margin: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.white30, shape: BoxShape.circle), child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 18)),
                ),
                actions: [
                  GestureDetector(
                    onTap: () => setState(() => _isFavorite = !_isFavorite),
                    child: Container(margin: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.white30, shape: BoxShape.circle), padding: const EdgeInsets.all(8), child: Icon(_isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: Colors.white, size: 20)),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Container(margin: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.white30, shape: BoxShape.circle), padding: const EdgeInsets.all(8), child: const Icon(Icons.share_outlined, color: Colors.white, size: 20)),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(decoration: const BoxDecoration(gradient: AppGradients.primary)),
                      const Center(child: Icon(Icons.store_rounded, color: Colors.white24, size: 100)),
                      Positioned(
                        bottom: 0, left: 0, right: 0,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(16, 60, 16, 20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(business.name, style: AppTextStyles.h1.copyWith(color: Colors.white)),
                                    Row(
                                      children: [
                                        const Icon(Icons.star_rounded, color: AppColors.amberWarning, size: 16),
                                        Text(' ${business.rating.toStringAsFixed(1)} · ${business.reviewCount} reviews', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                        const SizedBox(width: 8),
                                        StatusBadge(status: business.isOpen ? 'active' : 'inactive', fontSize: 9),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                bottom: TabBar(
                  controller: _tabController,
                  tabs: _tabs.map((t) => Tab(text: t)).toList(),
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textHint,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 2.5,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(businessId: widget.businessId, business: business),
                _ServicesTab(businessId: widget.businessId),
                _ReviewsTab(businessId: widget.businessId),
                _AboutTab(business: business),
              ],
            ),
          ),
          // Bottom book button
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + MediaQuery.of(context).padding.bottom),
              decoration: const BoxDecoration(color: Colors.white, boxShadow: AppShadows.e3),
              child: PremiumButton(
                label: 'Book Appointment',
                onPressed: () => context.push('/service-selection', extra: {
                  'businessId': widget.businessId,
                  'businessName': business.name,
                }),
                icon: Icons.calendar_today_rounded,
              ),
            ),
          ),
        ],
          ),
        );
      },
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final String businessId;
  final BusinessModel business;
  const _OverviewTab({required this.businessId, required this.business});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // Live queue card
        StreamBuilder<List<BookingModel>>(
          stream: FirebaseService.instance.getLiveQueueStream(businessId),
          builder: (ctx, snap) {
            final list = snap.data ?? [];
            final totalWaiting = list.where((b) => b.status == 'pending' || b.status == 'confirmed').length;
            final avgWait = list.isNotEmpty ? list.first.estimatedWaitMinutes : 0;
            return AnimatedCard(
              gradient: AppGradients.teal,
              padding: const EdgeInsets.all(16),
              baseShadow: AppShadows.e2,
              child: Row(
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  const Text('Live Queue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                  const Spacer(),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('$totalWaiting waiting', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
                    Text('~${avgWait} min wait', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ]),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        // Info cards
        _InfoRow(icon: Icons.location_on_outlined, text: business.address),
        _InfoRow(icon: Icons.phone_outlined, text: business.phone),
        _InfoRow(icon: Icons.schedule_outlined, text: 'Mon–Sat: 9:00 AM – 8:00 PM'),
        _InfoRow(icon: Icons.verified_rounded, text: 'Verified Business', color: AppColors.tealSuccess),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  const _InfoRow({required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppTextStyles.body.copyWith(color: color ?? AppColors.textSecondary))),
        ],
      ),
    );
  }
}

class _ServicesTab extends StatelessWidget {
  final String businessId;
  const _ServicesTab({required this.businessId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirebaseService.instance.getServicesStream(businessId),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final services = snap.data ?? [];
        if (services.isEmpty) return const Center(child: Text('No services found.'));
        
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: services.length,
          itemBuilder: (ctx, i) {
            final s = services[i];
            return AnimatedCard(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              baseShadow: AppShadows.e1,
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: AppColors.primaryGlow, borderRadius: BorderRadius.circular(AppRadius.sm)),
                    child: const Icon(Icons.medical_services_outlined, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s['name']?.toString() ?? '', style: AppTextStyles.h4),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.timer_outlined, size: 14, color: AppColors.textHint),
                      Text(' ${s['duration']} min', style: AppTextStyles.caption),
                    ]),
                  ])),
                  Text('₹${s['price']}', style: AppTextStyles.h3.copyWith(color: AppColors.primary)),
                ],
              ),
            );
          },
        );
      }
    );
  }
}

class _ReviewsTab extends StatelessWidget {
  final String businessId;
  const _ReviewsTab({required this.businessId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ReviewModel>>(
      stream: FirebaseService.instance.getReviewsStream(businessId),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final reviews = snap.data ?? [];
        if (reviews.isEmpty) return const Center(child: Text('No reviews yet.'));
        
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: reviews.length,
          itemBuilder: (ctx, i) {
            final r = reviews[i];
            return AnimatedCard(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              baseShadow: AppShadows.e1,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primaryGlow,
                    child: Text(r.customerName.isNotEmpty ? r.customerName[0].toUpperCase() : 'U', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(r.customerName, style: AppTextStyles.h4),
                    Row(children: List.generate(5, (j) => Icon(Icons.star_rounded, size: 14, color: j < r.rating ? AppColors.amber : AppColors.border))),
                  ])),
                  Text('Recent', style: AppTextStyles.caption),
                ]),
                const SizedBox(height: 10),
                Text(r.text, style: AppTextStyles.body),
              ]),
            );
          }
        );
      }
    );
  }
}

class _AboutTab extends StatelessWidget {
  final BusinessModel business;
  const _AboutTab({required this.business});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Text(business.description.isNotEmpty ? business.description : 'No description available.'),
    );
  }
}
