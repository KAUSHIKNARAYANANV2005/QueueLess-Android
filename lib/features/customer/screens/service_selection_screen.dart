import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/nav_helper.dart';
import '../../../shared/widgets/premium_button.dart';
import '../../../shared/widgets/animated_card.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../../shared/widgets/empty_state_widget.dart';

class ServiceSelectionScreen extends StatefulWidget {
  final String businessId;
  final String businessName;
  const ServiceSelectionScreen({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  @override
  State<ServiceSelectionScreen> createState() => _ServiceSelectionScreenState();
}

class _ServiceSelectionScreenState extends State<ServiceSelectionScreen> {
  String? _selectedServiceId;
  String? _selectedServiceName;
  double? _selectedServicePrice;
  int? _selectedServiceDuration;
  String? _selectedStaffId;
  List<Map<String, dynamic>> _services = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() => _loading = true);
    try {
      final services = await FirebaseService.instance.getServices(widget.businessId);
      if (mounted) setState(() { _services = services; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.businessName),
        leading: const AppBackButton(),
      ),
      body: Stack(
        children: [
          _loading
              ? ListView(
                  padding: const EdgeInsets.all(16),
                  children: List.generate(4, (_) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: LoadingShimmer.shimmerListItem(),
                  )),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Services
                      Text('Select a Service', style: AppTextStyles.h3),
                      const SizedBox(height: 12),
                      if (_services.isEmpty)
                        EmptyStateWidget(
                          icon: Icons.miscellaneous_services_rounded,
                          title: 'No Services Yet',
                          message: 'This business hasn\'t listed services yet.',
                        )
                      else
                        ..._services.map((s) {
                          final isSelected = _selectedServiceId == s['id'];
                          return AnimatedCard(
                            onTap: () => setState(() {
                              _selectedServiceId = s['id'];
                              _selectedServiceName = s['name'];
                              _selectedServicePrice = (s['price'] ?? 0.0).toDouble();
                              _selectedServiceDuration = (s['duration'] ?? 15) as int;
                            }),
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : AppColors.card,
                            border: BorderSide(
                              color: isSelected ? AppColors.primary : AppColors.border,
                              width: isSelected ? 2 : 1,
                            ),
                            baseShadow: isSelected ? AppShadows.glow(AppColors.primary, intensity: 0.15) : AppShadows.e1,
                              child: Row(children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 22, height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? AppColors.primary : AppColors.border, width: 2,
                                    ),
                                    color: isSelected ? AppColors.primary : Colors.transparent,
                                  ),
                                  child: isSelected ? const Icon(Icons.check_rounded, color: Colors.white, size: 14) : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(s['name'] ?? '', style: AppTextStyles.h4),
                                  if (s['description'] != null && (s['description'] as String).isNotEmpty)
                                    Text(s['description'], style: AppTextStyles.caption),
                                ])),
                                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                  Text('₹${((s['price'] ?? 0.0) as num).toInt()}',
                                      style: AppTextStyles.h4.copyWith(color: AppColors.primary)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.inputBg,
                                      borderRadius: BorderRadius.circular(AppRadius.full),
                                    ),
                                    child: Text('${s['duration'] ?? 15} min', style: AppTextStyles.caption),
                                  ),
                                ]),
                              ]),
                            );
                        }),
                      const SizedBox(height: 20),
                      // AI Suggestion card
                      AnimatedCard(
                        padding: const EdgeInsets.all(14),
                        color: AppColors.teal.withValues(alpha: 0.08),
                        border: BorderSide(color: AppColors.teal.withValues(alpha: 0.3)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            const Icon(Icons.auto_awesome_rounded, color: AppColors.teal, size: 18),
                            const SizedBox(width: 6),
                            Text('AI Suggestions', style: AppTextStyles.h4.copyWith(color: AppColors.teal)),
                          ]),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8, runSpacing: 8,
                            children: ['Best time: 2PM', '~15 min wait', 'Weekend slot available'].map((s) =>
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.teal.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(AppRadius.full),
                                ),
                                child: Text(s, style: const TextStyle(color: AppColors.teal, fontSize: 12, fontWeight: FontWeight.w600)),
                              ),
                            ).toList(),
                          ),
                        ]),
                      ),
                    ],
                  ),
                ),
          // Bottom bar
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + MediaQuery.of(context).padding.bottom),
              decoration: const BoxDecoration(color: Colors.white, boxShadow: AppShadows.e3),
              child: PremiumButton(
                label: _selectedServiceId == null ? 'Select a Service' : 'Continue →',
                onPressed: _selectedServiceId == null
                    ? null
                    : () => context.push('/datetime-picker', extra: {
                        'businessId': widget.businessId,
                        'businessName': widget.businessName,
                        'serviceId': _selectedServiceId,
                        'serviceName': _selectedServiceName,
                        'price': _selectedServicePrice,
                        'duration': _selectedServiceDuration,
                        'staffId': _selectedStaffId,
                      }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
