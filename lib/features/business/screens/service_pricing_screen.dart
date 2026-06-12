import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/utils/nav_helper.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/loading_shimmer.dart';

class ServicePricingScreen extends StatefulWidget {
  const ServicePricingScreen({super.key});
  @override
  State<ServicePricingScreen> createState() => _ServicePricingScreenState();
}

class _ServicePricingScreenState extends State<ServicePricingScreen> {
  List<Map<String, dynamic>> _services = [];
  bool _loading = true;
  String? _businessId;

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
      _businessId = biz?.id ?? 'b1';
    } else {
      _businessId = 'b1';
    }
    final services = await FirebaseService.instance.getServices(_businessId!);
    if (mounted) setState(() { _services = services; _loading = false; });
  }

  void _showAddServiceSheet([Map<String, dynamic>? existing]) {
    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final priceCtrl = TextEditingController(text: existing?['price']?.toString() ?? '');
    final descCtrl = TextEditingController(text: existing?['description'] ?? '');
    int duration = existing?['duration'] ?? 30;
    bool isFree = existing?['price'] == 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(existing == null ? 'Add Service' : 'Edit Service', style: AppTextStyles.h3),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
              ]),
              const SizedBox(height: 12),
              TextField(controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Service Name', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description (optional)', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              Row(children: [
                const Text('Duration: ', style: TextStyle(fontWeight: FontWeight.w500)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.remove_circle_outline), color: AppColors.primary,
                    onPressed: () => setModal(() => duration = (duration - 15).clamp(15, 180))),
                Text('$duration min', style: AppTextStyles.h4.copyWith(color: AppColors.primary)),
                IconButton(icon: const Icon(Icons.add_circle_outline), color: AppColors.primary,
                    onPressed: () => setModal(() => duration = (duration + 15).clamp(15, 180))),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(controller: priceCtrl, enabled: !isFree,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Price (₹)', border: const OutlineInputBorder(),
                        prefixText: isFree ? '' : '₹'))),
                const SizedBox(width: 12),
                Column(children: [
                  const Text('Free', style: TextStyle(fontSize: 12)),
                  Switch(value: isFree, activeColor: AppColors.primary,
                      onChanged: (v) => setModal(() { isFree = v; if (v) priceCtrl.clear(); })),
                ]),
              ]),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.isEmpty) return;
                    Navigator.pop(ctx);
                    final data = {
                      'name': nameCtrl.text.trim(),
                      'description': descCtrl.text.trim(),
                      'duration': duration,
                      'price': isFree ? 0.0 : double.tryParse(priceCtrl.text) ?? 0.0,
                      'isActive': true,
                    };
              try {
                    if (existing != null && existing['id'] != null) {
                      await FirebaseService.instance.updateService(_businessId!, existing['id'], data);
                    } else {
                      await FirebaseService.instance.createService(_businessId!, data);
                    }
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Service saved ✓'),
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
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md))),
                  child: Text(existing == null ? 'Add Service' : 'Save Changes',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Services & Pricing'),
        leading: const AppBackButton(fallback: '/dashboard'),
        actions: [IconButton(key: const Key('refresh_services_btn'), icon: const Icon(Icons.refresh_rounded), onPressed: _load)],
      ),
      body: _loading
          ? ListView(
              physics: const NeverScrollableScrollPhysics(),
              children: List.generate(4, (_) => LoadingShimmer.shimmerListItem()),
            )
          : _services.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.medical_services_outlined,
                  title: 'No Services Yet',
                  message: 'Add your first service to start accepting bookings.',
                  actionLabel: 'Add Service',
                  onAction: () => _showAddServiceSheet(),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _services.length,
                  itemBuilder: (ctx, i) {
                    final s = _services[i];
                    final price = (s['price'] ?? 0.0) as num;
                    final isActive = s['isActive'] as bool? ?? true;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: AppShadows.e1),
                      child: ListTile(
                        leading: Container(width: 44, height: 44,
                            decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.medical_services_outlined, color: Colors.white, size: 20)),
                        title: Text(s['name'] ?? '', style: AppTextStyles.h4),
                        subtitle: Text('${s['duration'] ?? 30} min', style: AppTextStyles.caption),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(price == 0 ? 'Free' : '₹${price.toInt()}',
                              style: AppTextStyles.h4.copyWith(color: AppColors.primary)),
                          const SizedBox(width: 8),
                          Switch(
                            value: isActive,
                            activeColor: AppColors.primary,
                            onChanged: (v) async {
                              await FirebaseService.instance.updateService(_businessId!, s['id'] ?? '', {'isActive': v});
                              setState(() => _services[i]['isActive'] = v);
                            },
                          ),
                          IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textHint),
                              onPressed: () => _showAddServiceSheet(s)),
                        ]),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddServiceSheet(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Service', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
