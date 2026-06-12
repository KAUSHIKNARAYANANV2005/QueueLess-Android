import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/firebase_service.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../../shared/widgets/error_state_widget.dart';

class AdminSuperPanelScreen extends StatefulWidget {
  const AdminSuperPanelScreen({super.key});
  @override
  State<AdminSuperPanelScreen> createState() => _AdminSuperPanelScreenState();
}

class _AdminSuperPanelScreenState extends State<AdminSuperPanelScreen> {
  Map<String, dynamic>? _analytics;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await FirebaseService.instance.getAdminAnalytics();
      if (mounted) setState(() { _analytics = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: AppColors.primaryDeep,
        foregroundColor: Colors.white,
        leading: IconButton(
          key: const Key('admin_back_btn'),
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () {
            if (context.canPop()) context.pop();
            else context.go('/home');
          },
        ),
        actions: [
          IconButton(
            key: const Key('admin_refresh_btn'),
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? ListView(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: List.generate(5, (_) => LoadingShimmer.shimmerCard()),
            )
          : _error != null
              ? ErrorStateWidget(message: _error!, onRetry: _load)
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final stats = [
      {'label': 'Total Users',     'value': '${_analytics?['totalUsers'] ?? 0}',      'icon': Icons.people_rounded,         'color': AppColors.primary},
      {'label': 'Businesses',      'value': '${_analytics?['totalBusinesses'] ?? 0}',  'icon': Icons.store_rounded,          'color': AppColors.tealSuccess},
      {'label': 'Total Bookings',  'value': '${_analytics?['totalBookings'] ?? 0}',    'icon': Icons.event_rounded,          'color': AppColors.amberWarning},
      {'label': 'Platform Status', 'value': 'Live ✓',                                   'icon': Icons.health_and_safety_rounded, 'color': AppColors.primaryDeep},
    ];

    final actions = [
      {'label': 'User Management',     'icon': Icons.manage_accounts_rounded,  'route': '/home'},
      {'label': 'Business Approvals',  'icon': Icons.business_rounded,         'route': '/home'},
      {'label': 'Reports & Export',    'icon': Icons.download_rounded,         'route': '/reports'},
      {'label': 'Feedback & Support',  'icon': Icons.support_agent_rounded,    'route': '/home'},
      {'label': 'AI Model Config',     'icon': Icons.smart_toy_rounded,        'route': '/home'},
    ];

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: AppGradients.dark,
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              child: const Row(children: [
                Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 36),
                SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Super Admin Panel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                  Text('Manage entire QueueLess platform', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ])),
              ]),
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.5,
              children: stats.map((s) => Container(
                key: Key('stat_${(s['label'] as String).toLowerCase().replaceAll(' ', '_')}'),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: AppShadows.e1),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Row(children: [
                    Icon(s['icon'] as IconData, color: s['color'] as Color, size: 20),
                    const SizedBox(width: 6),
                    Expanded(child: Text(s['value'] as String, style: AppTextStyles.h3, overflow: TextOverflow.ellipsis)),
                  ]),
                  const SizedBox(height: 4),
                  Align(alignment: Alignment.centerLeft, child: Text(s['label'] as String, style: AppTextStyles.caption)),
                ]),
              )).toList(),
            ),
            const SizedBox(height: 20),
            Text('Management', style: AppTextStyles.h3),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: AppShadows.e1),
              child: Column(
                children: actions.map((item) => ListTile(
                  key: Key('admin_nav_${(item['label'] as String).toLowerCase().replaceAll(' ', '_')}'),
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(10)),
                    child: Icon(item['icon'] as IconData, color: Colors.white, size: 20),
                  ),
                  title: Text(item['label'] as String, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                  onTap: () => context.go(item['route'] as String),
                )).toList(),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
