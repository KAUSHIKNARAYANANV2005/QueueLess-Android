import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/firebase_service.dart';
import '../../../shared/models/business_model.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/animated_card.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/error_state_widget.dart';
import '../../../shared/widgets/status_badge.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen>
    with SingleTickerProviderStateMixin {
  int _navIndex = 0;
  String _selectedCategory = 'All';
  List<BusinessModel> _businesses = [];
  bool _loading = true;
  String? _error;
  StreamSubscription? _businessesSub;
  late AnimationController _heroCtrl;
  late Animation<double> _heroAnim;

  final List<Map<String, dynamic>> _categories = [
    {'label': 'All',        'icon': Icons.apps_rounded,               'color': AppColors.primary},
    {'label': 'Clinic',     'icon': Icons.local_hospital_outlined,    'color': AppColors.coral},
    {'label': 'Salon',      'icon': Icons.content_cut_rounded,        'color': AppColors.amber},
    {'label': 'Government', 'icon': Icons.account_balance_outlined,   'color': AppColors.info},
    {'label': 'Spa',        'icon': Icons.spa_outlined,               'color': AppColors.teal},
    {'label': 'Consultant', 'icon': Icons.business_center_outlined,   'color': AppColors.primaryDeep},
    {'label': 'Bank',       'icon': Icons.account_balance_wallet_outlined, 'color': AppColors.tealLight},
    {'label': 'Lab',        'icon': Icons.science_outlined,           'color': AppColors.primary},
  ];

  // Featured banners for hero carousel
  final List<Map<String, dynamic>> _banners = [
    {'title': 'Skip the Wait', 'subtitle': 'Book your slot in seconds', 'gradient': AppGradients.primary, 'icon': Icons.access_time_rounded},
    {'title': 'Near You', 'subtitle': '120+ services in your area', 'gradient': AppGradients.teal, 'icon': Icons.location_on_rounded},
    {'title': 'AI-Powered', 'subtitle': 'QueueBot helps 24/7', 'gradient': AppGradients.aurora, 'icon': Icons.smart_toy_rounded},
  ];
  int _bannerIndex = 0;

  @override
  void initState() {
    super.initState();
    _heroCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _heroAnim = CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut);
    _heroCtrl.forward();
    _loadBusinesses();
    // Auto-rotate banners
    Future.delayed(const Duration(seconds: 4), _rotateBanner);
  }

  void _rotateBanner() {
    if (!mounted) return;
    setState(() => _bannerIndex = (_bannerIndex + 1) % _banners.length);
    Future.delayed(const Duration(seconds: 4), _rotateBanner);
  }

  @override
  void dispose() {
    _businessesSub?.cancel();
    _heroCtrl.dispose();
    super.dispose();
  }

  void _loadBusinesses() {
    setState(() { _loading = true; _error = null; });
    _businessesSub?.cancel();
    _businessesSub = FirebaseService.instance.getBusinessesStream(
      _selectedCategory == 'All' ? null : _selectedCategory,
    ).listen((data) {
      if (mounted) setState(() { _businesses = data; _loading = false; _error = null; });
    }, onError: (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    });
  }

  void _onNavTap(int i) {
    setState(() => _navIndex = i);
    switch (i) {
      case 0: break;
      case 1: context.go('/search'); break;
      case 2: context.go('/chatbot'); break;
      case 3: context.go('/appointments'); break;
      case 4: context.go('/profile'); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero Header ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.primary,
            actions: const [SizedBox(width: 56)],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: _HeroHeader(
                banners: _banners,
                bannerIndex: _bannerIndex,
                onNotificationTap: () => context.go('/notifications'),
                onSearchTap: () => context.go('/search'),
                onMapTap: () => context.go('/map'),
                heroAnim: _heroAnim,
              ),
            ),
          ),

          // ── Quick Stats ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _heroAnim,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Row(children: [
                  _QuickStat(icon: Icons.people_rounded,   label: 'Active Queues',  value: '12',    color: AppColors.primary),
                  const SizedBox(width: 10),
                  _QuickStat(icon: Icons.access_time_rounded, label: 'Avg Wait',    value: '14 min',color: AppColors.teal),
                  const SizedBox(width: 10),
                  _QuickStat(icon: Icons.store_rounded,    label: 'Near You',       value: '120+',  color: AppColors.amber),
                ]),
              ),
            ),
          ),

          // ── Categories ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 20, top: 24, bottom: 12),
              child: Text('Explore', style: AppTextStyles.h3),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 96,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (ctx, i) {
                  final cat = _categories[i];
                  final isSelected = _selectedCategory == cat['label'];
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedCategory = cat['label'] as String);
                      _loadBusinesses();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 12),
                      width: 70,
                      child: Column(children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 56, height: 56,
                          decoration: BoxDecoration(
                            gradient: isSelected ? AppGradients.primary : null,
                            color: isSelected ? null : AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            boxShadow: isSelected ? AppShadows.glow(cat['color'] as Color) : null,
                          ),
                          child: Icon(
                            cat['icon'] as IconData,
                            color: isSelected ? Colors.white : (cat['color'] as Color),
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          cat['label'] as String,
                          style: AppTextStyles.caption.copyWith(
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Active Queue Banner ───────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: _ActiveQueueCard(onTap: () => context.go('/active-queue')),
            ),
          ),

          // ── Nearby Businesses ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(children: [
                Text('Nearby Services', style: AppTextStyles.h3),
                const Spacer(),
                GestureDetector(
                  onTap: () => context.go('/search'),
                  child: Text('See all', style: AppTextStyles.label.copyWith(color: AppColors.primary)),
                ),
              ]),
            ),
          ),

          if (_loading)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, __) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: LoadingShimmer.shimmerCard(),
                ),
                childCount: 4,
              ),
            )
          else if (_error != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ErrorStateWidget(message: _error!, onRetry: _loadBusinesses),
              ),
            )
          else if (_businesses.isEmpty)
            SliverToBoxAdapter(
              child: EmptyStateWidget(
                icon: Icons.store_outlined,
                title: 'No Services Found',
                message: 'Try changing the category or search in a different area.',
                actionLabel: 'Show All',
                onAction: () {
                  setState(() => _selectedCategory = 'All');
                  _loadBusinesses();
                },
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final biz = _businesses[i];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _BusinessCard(
                      business: biz,
                      onTap: () => context.push('/business/${biz.id}'),
                    ),
                  );
                },
                childCount: _businesses.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: _navIndex, onTap: _onNavTap),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  HERO HEADER
// ─────────────────────────────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  final List<Map<String, dynamic>> banners;
  final int bannerIndex;
  final VoidCallback onNotificationTap;
  final VoidCallback onSearchTap;
  final VoidCallback onMapTap;
  final Animation<double> heroAnim;

  const _HeroHeader({
    required this.banners,
    required this.bannerIndex,
    required this.onNotificationTap,
    required this.onSearchTap,
    required this.onMapTap,
    required this.heroAnim,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final initial = (user?.displayName?.isNotEmpty == true)
        ? user!.displayName![0].toUpperCase()
        : (user?.email?.isNotEmpty == true ? user!.email![0].toUpperCase() : 'U');
    final name = user?.displayName?.split(' ').first ?? 'there';
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning ☀️' : hour < 17 ? 'Good Afternoon 🌤️' : 'Good Evening 🌙';
    final banner = banners[bannerIndex];

    return Stack(
      children: [
        // Gradient background
        Container(decoration: BoxDecoration(gradient: banner['gradient'] as LinearGradient)),

        // Decorative circles
        Positioned(top: -30, right: -30, child: _DecorCircle(size: 140, opacity: 0.08)),
        Positioned(bottom: 60, left: -20, child: _DecorCircle(size: 100, opacity: 0.06)),
        Positioned(top: 60, right: 80, child: _DecorCircle(size: 60, opacity: 0.1)),

        SafeArea(
          child: FadeTransition(
            opacity: heroAnim,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row — avatar + name + bell
                  Row(children: [
                    GestureDetector(
                      onTap: () => context.go('/profile'),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white24,
                        child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(greeting, style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                      Text('Hi, $name! 👋', style: AppTextStyles.h3.copyWith(color: Colors.white)),
                    ])),
                    // Map button
                    GestureDetector(
                      key: const Key('home_map_btn'),
                      onTap: onMapTap,
                      child: GlassContainer.light(
                        padding: const EdgeInsets.all(8),
                        borderRadius: AppRadius.full,
                        child: const Icon(Icons.map_outlined, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Notification bell
                    GestureDetector(
                      key: const Key('home_notification_btn'),
                      onTap: onNotificationTap,
                      child: GlassContainer.light(
                        padding: const EdgeInsets.all(8),
                        borderRadius: AppRadius.full,
                        child: Stack(clipBehavior: Clip.none, children: [
                          const Icon(Icons.notifications_outlined, color: Colors.white, size: 20),
                          Positioned(
                            top: -2, right: -2,
                            child: Container(
                              width: 8, height: 8,
                              decoration: const BoxDecoration(color: AppColors.coral, shape: BoxShape.circle),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ]),

                  const SizedBox(height: 20),

                  // Animated banner text
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(anim),
                      child: child,
                    )),
                    child: Column(
                      key: ValueKey(bannerIndex),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(banner['title'] as String, style: AppTextStyles.h2.copyWith(color: Colors.white)),
                        Text(banner['subtitle'] as String, style: AppTextStyles.body.copyWith(color: Colors.white70)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Glassmorphic search bar
                  GestureDetector(
                    key: const Key('home_search_bar'),
                    onTap: onSearchTap,
                    child: GlassContainer.light(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      borderRadius: AppRadius.full,
                      child: Row(children: [
                        const Icon(Icons.search_rounded, color: Colors.white70, size: 20),
                        const SizedBox(width: 10),
                        Expanded(child: Text('Search clinics, salons, govt...', style: AppTextStyles.body.copyWith(color: Colors.white60))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.full)),
                          child: const Text('Near Me', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  ACTIVE QUEUE CARD
// ─────────────────────────────────────────────────────────────
class _ActiveQueueCard extends StatelessWidget {
  final VoidCallback onTap;
  const _ActiveQueueCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      onTap: onTap,
      gradient: AppGradients.teal,
      borderRadius: AppRadius.lg,
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(AppRadius.sm)),
          child: const Icon(Icons.queue_rounded, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Active Queue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          const Text('Token #B007 • Dr. Sharma Clinic', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Row(children: [
            Container(
              width: 6, height: 6,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            const Text('3 ahead · ~14 min', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
          ]),
        ])),
        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  BUSINESS CARD
// ─────────────────────────────────────────────────────────────
class _BusinessCard extends StatelessWidget {
  final BusinessModel business;
  final VoidCallback onTap;

  const _BusinessCard({required this.business, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      baseShadow: AppShadows.card,
      child: Row(children: [
        // Icon / avatar
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(AppRadius.md)),
          child: Icon(
            business.category == 'Clinic' ? Icons.local_hospital_rounded
                : business.category == 'Salon' ? Icons.content_cut_rounded
                : business.category == 'Bank' ? Icons.account_balance_rounded
                : Icons.store_rounded,
            color: Colors.white, size: 26,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(business.name, style: AppTextStyles.h4, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(business.address, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Row(children: [
            // Rating stars
            const Icon(Icons.star_rounded, color: AppColors.amber, size: 14),
            const SizedBox(width: 2),
            Text(business.rating.toStringAsFixed(1), style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            StatusBadge(status: business.isOpen ? 'active' : 'inactive'),
            const SizedBox(width: 8),
            // Queue length
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppColors.primaryGlow, borderRadius: BorderRadius.circular(AppRadius.full)),
              child: Text('${business.currentQueue} waiting', style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
          ]),
        ])),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${(business.distance / 1000).toStringAsFixed(1)} km', style: AppTextStyles.caption.copyWith(color: AppColors.textHint)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(AppRadius.full)),
            child: const Text('Book', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  QUICK STAT CHIP
// ─────────────────────────────────────────────────────────────
class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _QuickStat({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(AppRadius.md), boxShadow: AppShadows.e1),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 6),
        Text(value, style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary)),
        Text(label, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    ));
  }
}

// ─────────────────────────────────────────────────────────────
//  DECORATIVE CIRCLE
// ─────────────────────────────────────────────────────────────
class _DecorCircle extends StatelessWidget {
  final double size;
  final double opacity;
  const _DecorCircle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  WAVE CLIPPER (kept for backward compat if referenced)
// ─────────────────────────────────────────────────────────────
class _HomeWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(size.width * 0.25, size.height, size.width * 0.5, size.height - 20);
    path.quadraticBezierTo(size.width * 0.75, size.height - 40, size.width, size.height - 20);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> old) => false;
}
