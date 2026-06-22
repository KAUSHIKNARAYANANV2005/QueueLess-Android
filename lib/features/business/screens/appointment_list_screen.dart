import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/firebase_service.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/widgets/status_badge.dart';

class AppointmentListScreen extends StatefulWidget {
  const AppointmentListScreen({super.key});

  @override
  State<AppointmentListScreen> createState() => _AppointmentListScreenState();
}

class _AppointmentListScreenState extends State<AppointmentListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _businessId;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBusiness();
  }

  Future<void> _loadBusiness() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final biz = await FirebaseService.instance.getBusinessByOwner(uid);
      if (mounted && biz != null) {
        setState(() => _businessId = biz.id);
      }
    }
    if (mounted && _businessId == null) {
      setState(() => _businessId = 'b1');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null && mounted) {
      setState(() => _selectedDate = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => context.go('/dashboard')),
        actions: [
          IconButton(icon: const Icon(Icons.calendar_today_rounded), onPressed: _pickDate),
          IconButton(icon: const Icon(Icons.download_rounded), onPressed: () {}),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          indicatorColor: AppColors.primary,
          tabs: const [Tab(text: 'Today'), Tab(text: 'Upcoming'), Tab(text: 'Past')],
        ),
      ),
      body: _businessId == null
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildStream(_selectedDate),
                _buildStream(_selectedDate.add(const Duration(days: 1))),
                _buildStream(_selectedDate.subtract(const Duration(days: 1))),
              ],
            ),
    );
  }

  Widget _buildStream(DateTime date) {
    return StreamBuilder<List<BookingModel>>(
      stream: FirebaseService.instance.getBusinessBookingsStream(_businessId!, date),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final appts = snap.data ?? [];
        if (appts.isEmpty) {
          return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.calendar_today_rounded, size: 64, color: AppColors.textHint),
            SizedBox(height: 12),
            Text('No appointments', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          ]));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: appts.length,
          itemBuilder: (ctx, i) {
            final a = appts[i];
            return GestureDetector(
              onTap: () => context.push('/appointment-detail/${a.id}'),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: AppShadows.e1),
                child: Row(children: [
                  CircleAvatar(
                    radius: 22, 
                    backgroundColor: AppColors.inputBg, 
                    child: Text(a.customerName.isNotEmpty ? a.customerName[0].toUpperCase() : 'U', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(a.customerName.isNotEmpty ? a.customerName : 'Customer', style: AppTextStyles.h4),
                    Text('${a.serviceName} · ${a.dateTime.hour}:${a.dateTime.minute.toString().padLeft(2, '0')}', style: AppTextStyles.caption),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.center, children: [
                    StatusBadge(status: a.status, fontSize: 9),
                    const SizedBox(height: 4),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.full)), child: Text(a.tokenNumber, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12))),
                  ]),
                ]),
              ),
            );
          },
        );
      },
    );
  }
}
