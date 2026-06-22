import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/utils/nav_helper.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LiveQueueManagerScreen extends StatefulWidget {
  const LiveQueueManagerScreen({super.key});

  @override
  State<LiveQueueManagerScreen> createState() => _LiveQueueManagerScreenState();
}

class _LiveQueueManagerScreenState extends State<LiveQueueManagerScreen> {
  String _filter = 'All';
  String? _businessId;
  bool _servingLoading = false;
  BookingModel? _selectedBooking;

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
        });
      }
    }
    if (mounted) setState(() {});
  }

  List<BookingModel> _filterBookings(List<BookingModel> bookings) {
    var filtered = bookings;
    if (_filter == 'Waiting') {
      filtered = bookings.where((b) => b.status == 'pending' || b.status == 'confirmed').toList();
    } else if (_filter == 'Active') {
      filtered = bookings.where((b) => b.status == 'active').toList();
    }
    filtered.sort((a, b) => a.queuePosition.compareTo(b.queuePosition));
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Queue Manager'),
        leading: const AppBackButton(fallback: '/dashboard'),
      ),
      body: _businessId == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<BookingModel>>(
              // Custom method to be implemented in FirebaseService
              stream: FirebaseService.instance.getLiveQueueStream(_businessId!),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return ListView(
                    physics: const NeverScrollableScrollPhysics(),
                    children: List.generate(4, (_) => LoadingShimmer.shimmerCard()),
                  );
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }

                final allBookings = snap.data ?? [];
                final displayBookings = _filterBookings(allBookings);
                
                final activeBooking = allBookings.where((b) => b.status == 'active').firstOrNull;
                final waitingCount = allBookings.where((b) => b.status == 'pending' || b.status == 'confirmed').length;

                Widget queueList = _buildQueueList(displayBookings, activeBooking, waitingCount);
                Widget detailsPanel = _buildDetailsPanel();

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 1, child: queueList),
                      Container(width: 1, color: AppColors.border),
                      Expanded(flex: 1, child: detailsPanel),
                    ],
                  );
                }

                // Mobile view: if selected, show details, else list
                return Stack(
                  children: [
                    queueList,
                    if (_selectedBooking != null)
                      Positioned.fill(
                        child: Container(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          child: Column(
                            children: [
                              AppBar(
                                title: const Text('Booking Details'),
                                leading: IconButton(
                                  icon: const Icon(Icons.arrow_back),
                                  onPressed: () => setState(() => _selectedBooking = null),
                                ),
                              ),
                              Expanded(child: detailsPanel),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildQueueList(List<BookingModel> bookings, BookingModel? activeBooking, int waitingCount) {
    return Column(
      children: [
        // Current serving
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(gradient: AppGradients.teal, borderRadius: BorderRadius.circular(20), boxShadow: AppShadows.e3),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('NOW SERVING', style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1.5)),
            const SizedBox(height: 4),
            Row(children: [
              Text(activeBooking?.tokenNumber ?? '--', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
              const Spacer(),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(activeBooking?.customerName ?? 'None', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                Text(activeBooking?.serviceName ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ]),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ElevatedButton(
                onPressed: _servingLoading || activeBooking == null ? null : () async {
                  setState(() => _servingLoading = true);
                  try {
                    await FirebaseService.instance.serveCustomer(_businessId!, activeBooking.id);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Customer served ✓'), backgroundColor: AppColors.tealSuccess),
                    );
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.coralError),
                    );
                  } finally {
                    if (mounted) setState(() => _servingLoading = false);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.tealSuccess, padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full))),
                child: _servingLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('✓ Mark Served', style: TextStyle(fontWeight: FontWeight.w700)),
              )),
            ]),
          ]),
        ),
        // Filter chips
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: ['All', 'Active', 'Waiting'].map((f) {
              final isSelected = _filter == f;
              return GestureDetector(
                onTap: () => setState(() => _filter = f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppGradients.primary : null,
                    color: isSelected ? null : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                  ),
                  child: Text(f, style: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                ),
              );
            }).toList(),
          ),
        ),
        // Summary bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Text('$waitingCount waiting', style: AppTextStyles.h4),
          ]),
        ),
        // Queue list
        Expanded(
          child: bookings.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.people_outline_rounded,
                  title: 'No Bookings',
                  message: 'Queue is clear.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: bookings.length,
                  itemBuilder: (ctx, i) {
                    final item = bookings[i];
                    final isSelected = _selectedBooking?.id == item.id;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedBooking = item),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryLight.withValues(alpha: 0.1) : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12), 
                          border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent),
                          boxShadow: AppShadows.e1,
                        ),
                        child: Row(children: [
                          Container(width: 36, height: 36, decoration: BoxDecoration(gradient: item.status == 'active' ? AppGradients.teal : AppGradients.primary, borderRadius: BorderRadius.circular(8)), alignment: Alignment.center, child: Text(item.tokenNumber.isNotEmpty ? item.tokenNumber : '${item.queuePosition}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16))),
                          const SizedBox(width: 10),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(item.customerName, style: AppTextStyles.h4),
                            Text(item.serviceName, style: AppTextStyles.caption),
                          ])),
                          if (item.status != 'active')
                            Text('~${item.estimatedWaitMinutes} min', style: AppTextStyles.caption.copyWith(color: AppColors.tealSuccess, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDetailsPanel() {
    if (_selectedBooking == null) {
      return Center(
        child: Text('Select a booking to view details', style: AppTextStyles.body.copyWith(color: AppColors.textHint)),
      );
    }
    
    final b = _selectedBooking!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primaryLight,
                child: Text(b.customerName[0].toUpperCase(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.customerName, style: AppTextStyles.h2),
                    Text(b.serviceName, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: b.status == 'active' ? AppColors.tealSuccess : AppColors.primaryLight, borderRadius: BorderRadius.circular(16)),
                child: Text(b.status.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              )
            ],
          ),
          const SizedBox(height: 32),
          Text('Booking Info', style: AppTextStyles.h3),
          const SizedBox(height: 16),
          _InfoRow(label: 'Token', value: b.tokenNumber),
          const Divider(),
          _InfoRow(label: 'Queue Position', value: '${b.queuePosition}'),
          const Divider(),
          _InfoRow(label: 'Est. Wait Time', value: '${b.estimatedWaitMinutes} mins'),
          const Divider(),
          _InfoRow(label: 'Date & Time', value: '${b.dateTime.toLocal()}'.substring(0, 16)),
          const SizedBox(height: 32),
          Text('Actions', style: AppTextStyles.h3),
          const SizedBox(height: 16),
          if (b.status == 'pending' || b.status == 'confirmed')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await FirebaseService.instance.activateCustomer(_businessId!, b.id);
                    setState(() => _selectedBooking = null);
                  } catch (e) {
                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Call Next (Make Active)'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ),
          const SizedBox(height: 12),
          if (b.status == 'active')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await FirebaseService.instance.serveCustomer(_businessId!, b.id);
                    setState(() => _selectedBooking = null);
                  } catch (e) {
                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Mark Served'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.tealSuccess, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      await FirebaseService.instance.skipCustomer(_businessId!, b.id);
                      setState(() => _selectedBooking = null);
                    } catch (e) {
                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                  icon: const Icon(Icons.skip_next_rounded),
                  label: const Text('Skip'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      await FirebaseService.instance.cancelBooking(b.id);
                      setState(() => _selectedBooking = null);
                    } catch (e) {
                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.coralError, side: const BorderSide(color: AppColors.coralError), padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
          Text(value, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
