import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/utils/nav_helper.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/error_state_widget.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _filter = 'All';
  final List<String> _filters = ['All', 'Bookings', 'Queue', 'Offers'];
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  Color _colorForType(String type) {
    switch (type) {
      case 'queue': return AppColors.primary;
      case 'booking': return AppColors.tealSuccess;
      case 'offer': return AppColors.amberWarning;
      default: return AppColors.primary;
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'queue': return Icons.queue_rounded;
      case 'booking': return Icons.check_circle_outline_rounded;
      case 'offer': return Icons.local_offer_outlined;
      default: return Icons.notifications_outlined;
    }
  }

  Future<void> _deleteNotification(String id) async {
    try {
      await FirebaseService.instance.deleteNotification(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification deleted'),
          backgroundColor: AppColors.tealSuccess,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete: $e'),
          backgroundColor: AppColors.coralError,
        ),
      );
    }
  }

  Future<void> _markRead(String id) async {
    try {
      await FirebaseService.instance.markNotificationRead(id);
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    if (_uid == null) return;
    final uid = _uid;
    try {
      await FirebaseService.instance.markAllNotificationsRead(uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
          backgroundColor: AppColors.tealSuccess,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
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
          title: const Text('Notifications'),
          leading: AppBackButton(fallback: '/home'),
        ),
        body: const Center(child: Text('Please log in to view notifications')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: AppBackButton(fallback: '/home'),
        actions: [
          TextButton(
            key: const Key('mark_all_read_btn'),
            onPressed: _markAllRead,
            child: const Text(
              'Mark All Read',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // ignore: unnecessary_non_null_assertion
        stream: FirebaseService.instance.getNotificationsStream(_uid!),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return ListView(
              physics: const NeverScrollableScrollPhysics(),
              children: List.generate(5, (_) => LoadingShimmer.shimmerListItem()),
            );
          }
          if (snap.hasError) {
            return ErrorStateWidget(
              message: 'Failed to load notifications.',
              onRetry: () => setState(() {}),
            );
          }

          final allNotifs = snap.data ?? [];
          final filtered = _filter == 'All'
              ? allNotifs
              : allNotifs
                  .where(
                    (n) =>
                        (n['type'] as String? ?? '') ==
                        _filter.toLowerCase().replaceAll('s', ''),
                  )
                  .toList();

          return Column(
            children: [
              // Filter chips
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: _filters.map((f) {
                    final isSelected = _filter == f;
                    return Semantics(
                      label: 'Filter by $f',
                      child: GestureDetector(
                        key: Key('filter_${f.toLowerCase()}'),
                        onTap: () => setState(() => _filter = f),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: isSelected ? AppGradients.primary : null,
                            color: isSelected ? null : Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            f,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: filtered.isEmpty
                    ? const EmptyStateWidget(
                        icon: Icons.notifications_none_rounded,
                        title: 'No Notifications',
                        message: "You're all caught up!",
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) {
                          final n = filtered[i];
                          final id = n['id'] as String? ?? '';
                          final isRead = n['isRead'] as bool? ?? false;
                          final type = n['type'] as String? ?? '';
                          final title = n['title'] as String? ?? '';
                          final body = n['body'] as String? ?? '';
                          final color = _colorForType(type);
                          final icon = _iconForType(type);

                          return Dismissible(
                            key: Key('notif_$id'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 16),
                              decoration: BoxDecoration(
                                color: AppColors.coralError,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.white,
                              ),
                            ),
                            onDismissed: (_) => _deleteNotification(id),
                            child: GestureDetector(
                              onTap: () {
                                if (!isRead) _markRead(id);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isRead
                                      ? Colors.white
                                      : AppColors.primary.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isRead
                                        ? AppColors.border
                                        : AppColors.primary.withValues(alpha: 0.2),
                                  ),
                                  boxShadow: AppShadows.e1,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(icon, color: color, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: AppTextStyles.h4.copyWith(
                                              fontWeight: isRead
                                                  ? FontWeight.w500
                                                  : FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            body,
                                            style: AppTextStyles.caption
                                                .copyWith(height: 1.4),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        margin:
                                            const EdgeInsets.only(left: 8),
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
