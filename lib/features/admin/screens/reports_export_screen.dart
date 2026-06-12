import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/premium_button.dart';

class ReportsExportScreen extends StatefulWidget {
  const ReportsExportScreen({super.key});

  @override
  State<ReportsExportScreen> createState() => _ReportsExportScreenState();
}

class _ReportsExportScreenState extends State<ReportsExportScreen> {
  String _format = 'CSV';
  String _period = 'This Month';
  bool _loading = false;
  final List<String> _formats = ['CSV', 'PDF', 'Excel'];
  final List<String> _periods = ['Today', 'This Week', 'This Month', 'Last 3 Months', 'Custom'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports & Export'), leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => context.pop())),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Report Type', style: AppTextStyles.h3),
            const SizedBox(height: 12),
            ...[
              {'icon': Icons.people_rounded, 'label': 'User Report', 'desc': 'Total users, new signups'},
              {'icon': Icons.event_rounded, 'label': 'Bookings Report', 'desc': 'All bookings summary'},
              {'icon': Icons.attach_money_rounded, 'label': 'Revenue Report', 'desc': 'Revenue breakdown'},
              {'icon': Icons.store_rounded, 'label': 'Business Report', 'desc': 'Business performance'},
            ].map((r) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: AppShadows.e1),
              child: Row(children: [
                Container(width: 40, height: 40, decoration: const BoxDecoration(gradient: AppGradients.primary, shape: BoxShape.circle), child: Icon(r['icon'] as IconData, color: Colors.white, size: 20)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r['label'] as String, style: AppTextStyles.h4),
                  Text(r['desc'] as String, style: AppTextStyles.caption),
                ])),
                Checkbox(value: false, onChanged: (_) {}, activeColor: AppColors.primary),
              ]),
            )),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Format', style: AppTextStyles.label.copyWith(color: AppColors.textHint)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(value: _format, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), items: _formats.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(), onChanged: (v) => setState(() => _format = v ?? 'CSV')),
              ])),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Period', style: AppTextStyles.label.copyWith(color: AppColors.textHint)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(value: _period, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), items: _periods.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(), onChanged: (v) => setState(() => _period = v ?? 'This Month')),
              ])),
            ]),
            const Spacer(),
            PremiumButton(
              label: 'Generate & Download $_format',
              isLoading: _loading,
              onPressed: () async {
                setState(() => _loading = true);
                await Future.delayed(const Duration(seconds: 2));
                if (mounted) { setState(() => _loading = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$_period $_format report downloaded!'))); }
              },
              icon: Icons.download_rounded,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
