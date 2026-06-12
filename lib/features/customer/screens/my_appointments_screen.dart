import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/utils/nav_helper.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/error_state_widget.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<BookingModel> _activeBookings(List<BookingModel> bookings) =>
      bookings.where((b) => b.status == 'confirmed' || b.status == 'active').toList();

  List<BookingModel> _upcomingBookings(List<BookingModel> bookings) =>
      bookings.where((b) => b.status == 'pending').toList();

  List<BookingModel> _pastBookings(List<BookingModel> bookings) => bookings
      .where((b) => b.status == 'served' || b.status == 'cancelled')
      .toList();

  Future<void> _cancelBooking(BuildContext ctx, String bookingId) async {
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text(
          'Are you sure you want to cancel this appointment?',
        ),
        actions: [
          TextButton(
            key: const Key('cancel_dialog_no'),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          TextButton(
            key: const Key('cancel_dialog_yes'),
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.coralError),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await FirebaseService.instance.cancelBooking(bookingId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment cancelled'),
          backgroundColor: AppColors.tealSuccess,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel: $e'),
          backgroundColor: AppColors.coralError,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Appointments'),
          leading: AppBackButton(fallback: '/home'),
        ),
        body: const Center(child: Text('Please log in to view appointments')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
        leading: AppBackButton(fallback: '/home'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: StreamBuilder<List<BookingModel>>(
        // ignore: unnecessary_non_null_assertion
        stream: FirebaseService.instance.getUserBookingsStream(_uid!),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return ListView(
              physics: const NeverScrollableScrollPhysics(),
              children: List.generate(5, (_) => LoadingShimmer.shimmerCard()),
            );
          }
          if (snap.hasError) {
            return ErrorStateWidget(
              message: 'Failed to load appointments. Please try again.',
              onRetry: () => setState(() {}),
            );
          }
          final allBookings = snap.data ?? [];
          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildList(_activeBookings(allBookings)),
                _buildList(_upcomingBookings(allBookings)),
                _buildList(_pastBookings(allBookings)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildList(List<BookingModel> bookings) {
    if (bookings.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.calendar_today_rounded,
        title: 'No Appointments',
        message: 'You have no appointments here yet.',
        actionLabel: 'Book Now',
        onAction: () => context.go('/home'),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (ctx, i) {
        final b = bookings[i];
        final dateStr =
            DateFormat('MMM d, yyyy · h:mm a').format(b.dateTime);
        return Semantics(
          label: 'Appointment at ${b.businessName} on $dateStr',
          child: GestureDetector(
            key: Key('appointment_item_${b.id}'),
            onTap: () => context.push('/appointment/${b.id}'),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppShadows.e1,
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: AppGradients.primary,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(14),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        gradient: AppGradients.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.store_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.businessName,
                            style: AppTextStyles.h4,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(b.serviceName, style: AppTextStyles.caption),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                size: 12,
                                color: AppColors.textHint,
                              ),
                              const SizedBox(width: 3),
                              Text(dateStr, style: AppTextStyles.caption),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        StatusBadge(status: b.status, fontSize: 9),
                        const SizedBox(height: 4),
                        Text(
                          '₹${b.price.toStringAsFixed(0)}',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        if (b.status == 'confirmed' || b.status == 'pending')
                          GestureDetector(
                            key: Key('cancel_btn_${b.id}'),
                            onTap: () => _cancelBooking(context, b.id),
                            child: const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: AppColors.coralError,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
