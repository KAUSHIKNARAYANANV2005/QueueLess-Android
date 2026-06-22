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
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<BookingModel> _filterBookings(List<BookingModel> bookings, String tab) {
    switch (tab) {
      case 'Active':
        return bookings.where((b) => b.status == 'pending' || b.status == 'active').toList();
      case 'Upcoming':
        return bookings.where((b) => b.status == 'confirmed').toList();
      case 'Completed':
        return bookings.where((b) => b.status == 'served').toList();
      case 'Cancelled':
        return bookings.where((b) => b.status == 'cancelled').toList();
      default:
        return [];
    }
  }

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
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          TextButton(
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
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: StreamBuilder<List<BookingModel>>(
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
                _buildList(_filterBookings(allBookings, 'Active')),
                _buildList(_filterBookings(allBookings, 'Upcoming')),
                _buildList(_filterBookings(allBookings, 'Completed')),
                _buildList(_filterBookings(allBookings, 'Cancelled')),
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
        final dateStr = DateFormat('MMM d, yyyy · h:mm a').format(b.dateTime);
        final bool isActive = b.status == 'pending' || b.status == 'active';
        final bool isCompleted = b.status == 'served';
        final bool isUpcoming = b.status == 'confirmed';

        return Semantics(
          label: 'Appointment at ${b.businessName} on $dateStr',
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadows.e1,
            ),
            child: Column(
              children: [
                // Top header: Status and Token
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      StatusBadge(status: b.status, fontSize: 11),
                      Text(
                        'Token #${b.tokenNumber.isEmpty ? '???' : b.tokenNumber}',
                        style: AppTextStyles.h4.copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                // Body: Venue, Service, Time
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.store_rounded, color: AppColors.primary),
                  ),
                  title: Text(b.businessName, style: AppTextStyles.h3),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(b.serviceName, style: AppTextStyles.body),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.schedule_rounded, size: 14, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          Text(dateStr, style: AppTextStyles.caption.copyWith(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₹${b.price.toStringAsFixed(0)}', style: AppTextStyles.h3),
                      Text(b.paymentStatus.toUpperCase(), style: AppTextStyles.caption.copyWith(
                        color: b.paymentStatus == 'paid' ? AppColors.tealSuccess : AppColors.textHint,
                      )),
                    ],
                  ),
                  onTap: () => context.push('/appointment/${b.id}'),
                ),
                // Actions
                if (isActive || isCompleted || isUpcoming)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isActive) ...[
                          OutlinedButton.icon(
                            onPressed: () => context.push('/smart-route/${b.id}'),
                            icon: const Icon(Icons.map_rounded, size: 16),
                            label: const Text('Smart Route'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 36),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => context.push('/queue'),
                            icon: const Icon(Icons.visibility_rounded, size: 16),
                            label: const Text('View Queue'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 36),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ),
                        ],
                        if (isCompleted) ...[
                          OutlinedButton.icon(
                            onPressed: () {}, // Write Review
                            icon: const Icon(Icons.star_outline_rounded, size: 16),
                            label: const Text('Review'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 36),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => context.push('/business/${b.businessId}'),
                            icon: const Icon(Icons.replay_rounded, size: 16),
                            label: const Text('Book Again'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 36),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ),
                        ],
                        if (isUpcoming) ...[
                          OutlinedButton.icon(
                            onPressed: () => _cancelBooking(context, b.id),
                            icon: const Icon(Icons.cancel_outlined, size: 16),
                            label: const Text('Cancel Booking'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.coralError,
                              side: const BorderSide(color: AppColors.coralError),
                              minimumSize: const Size(0, 36),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
