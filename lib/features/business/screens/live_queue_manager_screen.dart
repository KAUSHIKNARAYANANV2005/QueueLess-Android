import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/utils/nav_helper.dart';
import '../../../shared/models/queue_model.dart';
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
  int _elapsedSeconds = 0;
  String? _businessId;
  bool _servingLoading = false;
  final _walkInNameCtrl = TextEditingController();
  final _walkInPhoneCtrl = TextEditingController();
  final _walkInServiceCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBusiness();
  }

  @override
  void dispose() {
    _walkInNameCtrl.dispose();
    _walkInPhoneCtrl.dispose();
    _walkInServiceCtrl.dispose();
    super.dispose();
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
    if (mounted) setState(() {}); // Rebuild with null businessId if not found
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Queue Manager'),
        leading: const AppBackButton(fallback: '/dashboard'),
        actions: [
          IconButton(
            key: const Key('refresh_queue_btn'),
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: StreamBuilder<QueueModel>(
        stream: _businessId != null 
          ? FirebaseService.instance.getQueueStream(_businessId!)
          : const Stream.empty(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting && snap.data == null) {
            return ListView(
              physics: const NeverScrollableScrollPhysics(),
              children: List.generate(4, (_) => LoadingShimmer.shimmerCard()),
            );
          }
          final queue = snap.data ?? QueueModel(
            businessId: _businessId ?? 'b1',
            currentServingToken: 'B007',
            totalWaiting: 5,
            avgWaitMinutes: 14,
            items: [
              QueueItem(bookingId: 'bk1', customerName: 'Ravi Kumar', serviceName: 'Consultation', position: 1, status: 'waiting', waitMinutes: 14),
              QueueItem(bookingId: 'bk2', customerName: 'Priya Singh', serviceName: 'Blood Test', position: 2, status: 'waiting', waitMinutes: 22),
              QueueItem(bookingId: 'bk3', customerName: 'Amit Sharma', serviceName: 'ECG', position: 3, status: 'waiting', waitMinutes: 35),
            ],
          );

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
                    Text(queue.currentServingToken, style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
                    const Spacer(),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(queue.currentServingName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                      Text(queue.currentServingService, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('${_elapsedSeconds ~/ 60} min elapsed', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ]),
                  ]),
                  const SizedBox(height: 12),
                    Row(children: [
                     Expanded(child: ElevatedButton(
                      key: const Key('serve_next_btn'),
                      onPressed: _servingLoading ? null : () async {
                        if (_businessId == null) return;
                        setState(() => _servingLoading = true);
                        try {
                          await FirebaseService.instance.serveNext(_businessId!);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Next customer called ✓'), backgroundColor: AppColors.tealSuccess),
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
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {
                        if (_businessId != null && queue.currentServingToken != '-') {
                          FirebaseService.instance.skipCustomer(_businessId!, queue.currentServingToken);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer skipped'), backgroundColor: AppColors.amberWarning));
                        }
                      },
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54), padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full))),
                      child: const Text('Skip'),
                    ),
                  ]),
                ]),
              ),
              // Filter chips
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: ['All', 'Waiting', 'Skipped', 'Served'].map((f) {
                    final isSelected = _filter == f;
                    return GestureDetector(
                      onTap: () => setState(() => _filter = f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: isSelected ? AppGradients.primary : null,
                          color: isSelected ? null : Colors.white,
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
                  Text('${queue.totalWaiting} waiting', style: AppTextStyles.h4),
                  const SizedBox(width: 12),
                  Text('~${queue.avgWaitMinutes} min avg', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                ]),
              ),
              // Queue list
              Expanded(
                       child: queue.items.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.people_outline_rounded,
                        title: 'Queue is Empty',
                        message: 'No one is waiting right now. Add a walk-in customer below.',
                        actionLabel: 'Add Walk-in',
                        onAction: () => _showWalkInDialog(context),
                      )
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: queue.items.length,
                        onReorder: (old, nw) {},
                        itemBuilder: (ctx, i) {
                          final item = queue.items[i];
                          return Dismissible(
                            key: Key('queue_${item.bookingId}'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 16),
                              decoration: BoxDecoration(color: AppColors.coralError, borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                            ),
                            onDismissed: (_) {},
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: AppShadows.e1),
                              child: Row(children: [
                                Container(width: 36, height: 36, decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(8)), alignment: Alignment.center, child: Text('${item.position}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16))),
                                const SizedBox(width: 10),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(item.customerName, style: AppTextStyles.h4),
                                  Text(item.serviceName, style: AppTextStyles.caption),
                                ])),
                                Text('~${item.waitMinutes} min', style: AppTextStyles.caption.copyWith(color: AppColors.tealSuccess, fontWeight: FontWeight.w600)),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.skip_next_rounded, color: AppColors.amberWarning, size: 20),
                                  onPressed: () {
                                    if (_businessId != null) {
                                      FirebaseService.instance.skipCustomer(_businessId!, item.bookingId);
                                    }
                                  },
                                ),
                              ]),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showWalkInDialog(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('Walk-in', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _showWalkInDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Add Walk-in Customer', style: AppTextStyles.h3),
          const SizedBox(height: 16),
          TextField(controller: _walkInNameCtrl, decoration: const InputDecoration(labelText: 'Customer Name', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _walkInPhoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _walkInServiceCtrl, decoration: const InputDecoration(labelText: 'Service', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () { 
              final name = _walkInNameCtrl.text.trim();
              final service = _walkInServiceCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(context); 
              if (_businessId != null) {
                FirebaseService.instance.addToQueue(
                  _businessId!, 
                  'walk_${DateTime.now().millisecondsSinceEpoch}', 
                  name, 
                  service.isEmpty ? 'General' : service
                ); 
              }
              _walkInNameCtrl.clear();
              _walkInPhoneCtrl.clear();
              _walkInServiceCtrl.clear();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
            child: const Text('Add to Queue', style: TextStyle(color: Colors.white)),
          )),
        ]),
      ),
    );
  }
}
