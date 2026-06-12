import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/utils/nav_helper.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/loading_shimmer.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  String? _businessId;
  List<Map<String, dynamic>> _staff = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final biz = await FirebaseService.instance.getBusinessByOwner(uid);
      if (mounted && biz != null) {
        _businessId = biz.id;
      }
    }
    if (_businessId == null) _businessId = 'b1';

    final staff = await FirebaseService.instance.getStaff(_businessId!);
    if (mounted) setState(() { _staff = staff; _loading = false; });
  }

  void _showAddStaffSheet([Map<String, dynamic>? existing]) {
    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final roleCtrl = TextEditingController(text: existing?['role'] ?? '');
    final emailCtrl = TextEditingController(text: existing?['email'] ?? '');
    final phoneCtrl = TextEditingController(text: existing?['phone'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Text(existing == null ? 'Add Staff Member' : 'Edit Staff Member', style: AppTextStyles.h3),
            const Spacer(),
            IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
          ]),
          const SizedBox(height: 16),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: roleCtrl, decoration: const InputDecoration(labelText: 'Role (e.g., Doctor, Stylist)', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(
            key: const Key('save_staff_btn'),
            onPressed: () async {
              if (nameCtrl.text.isEmpty || roleCtrl.text.isEmpty) return;
              Navigator.pop(context);
              final data = {
                'name': nameCtrl.text.trim(),
                'role': roleCtrl.text.trim(),
                'email': emailCtrl.text.trim(),
                'phone': phoneCtrl.text.trim(),
                'status': 'active',
                'bookings': existing?['bookings'] ?? 0,
              };
              try {
                await FirebaseService.instance.addStaff(_businessId!, data);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Staff member saved ✓'),
                    backgroundColor: AppColors.tealSuccess,
                  ));
                  _load();
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Error: $e'), backgroundColor: AppColors.coralError,
                ));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
            child: Text(existing == null ? 'Add Staff' : 'Save Changes', style: const TextStyle(color: Colors.white, fontSize: 16)),
          )),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Management'),
        leading: const AppBackButton(fallback: '/dashboard'),
        actions: [IconButton(key: const Key('refresh_staff_btn'), icon: const Icon(Icons.refresh_rounded), onPressed: _load)],
      ),
      body: _loading
        ? ListView(
            physics: const NeverScrollableScrollPhysics(),
            children: List.generate(4, (_) => LoadingShimmer.shimmerListItem()),
          )
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(children: [
                Expanded(child: _StaffStat(label: 'Total Staff', value: '${_staff.length}', icon: Icons.people_rounded, color: AppColors.primary)),
                const SizedBox(width: 8),
                Expanded(child: _StaffStat(label: 'Active', value: '${_staff.where((s) => s['status'] == 'active').length}', icon: Icons.check_circle_rounded, color: AppColors.tealSuccess)),
                const SizedBox(width: 8),
                Expanded(child: _StaffStat(label: "Today's", value: '${_staff.fold<int>(0, (sum, s) => sum + (s['bookings'] as int? ?? 0))}', icon: Icons.event_rounded, color: AppColors.amberWarning)),
              ]),
              const SizedBox(height: 20),
              Text('Staff Members', style: AppTextStyles.h3),
              const SizedBox(height: 12),
              if (_staff.isEmpty)
                EmptyStateWidget(
                  icon: Icons.people_outline_rounded,
                  title: 'No Staff Yet',
                  message: 'Add your first staff member to get started.',
                  actionLabel: 'Add Staff',
                  onAction: () => _showAddStaffSheet(),
                )
              else
                ..._staff.map((s) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: AppShadows.e1),
                  child: Column(children: [
                    Row(children: [
                      CircleAvatar(
                        radius: 24, 
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1), 
                        child: Text(
                          s['name'].toString().isNotEmpty ? s['name'].toString()[0].toUpperCase() : 'U', 
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 18)
                        )
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(s['name'] as String? ?? 'Unknown', style: AppTextStyles.h4),
                        Text(s['role'] as String? ?? 'Staff', style: AppTextStyles.caption),
                      ])),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
                        decoration: BoxDecoration(
                          color: (s['status'] == 'active' ? AppColors.tealSuccess : AppColors.textHint).withValues(alpha: 0.1), 
                          borderRadius: BorderRadius.circular(AppRadius.full)
                        ), 
                        child: Text(
                          s['status'] as String? ?? 'inactive', 
                          style: TextStyle(
                            color: s['status'] == 'active' ? AppColors.tealSuccess : AppColors.textHint, 
                            fontSize: 11, fontWeight: FontWeight.w600
                          )
                        )
                      ),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: Container(padding: const EdgeInsets.symmetric(vertical: 8), decoration: BoxDecoration(color: AppColors.inputBg, borderRadius: BorderRadius.circular(8)), child: Column(children: [
                        Text('${s['bookings'] ?? 0}', style: AppTextStyles.h4.copyWith(color: AppColors.primary)),
                        const Text("Today's", style: TextStyle(fontSize: 10, color: AppColors.textHint)),
                      ]))),
                      const SizedBox(width: 8),
                      Expanded(child: OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary), padding: const EdgeInsets.symmetric(vertical: 8)), child: const Text('Schedule'))),
                      const SizedBox(width: 8),
                      Expanded(child: OutlinedButton(onPressed: () => _showAddStaffSheet(s), style: OutlinedButton.styleFrom(foregroundColor: AppColors.textSecondary, side: const BorderSide(color: AppColors.border), padding: const EdgeInsets.symmetric(vertical: 8)), child: const Text('Edit'))),
                    ]),
                  ]),
                )),
            ],
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddStaffSheet(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('Add Staff', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _StaffStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StaffStat({required this.label, required this.value, required this.icon, required this.color});

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
