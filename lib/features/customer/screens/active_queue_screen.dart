import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/firebase_service.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/widgets/premium_button.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/animated_card.dart';
import '../../../shared/widgets/queue_position_widget.dart';

class ActiveQueueScreen extends StatelessWidget {
  final String businessId;
  final String businessName;
  final String tokenNumber;
  final String serviceName;
  final String bookingId;

  const ActiveQueueScreen({
    super.key,
    required this.businessId,
    required this.businessName,
    required this.tokenNumber,
    required this.serviceName,
    required this.bookingId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.primary),
        child: SafeArea(
          child: Column(children: [
            // ── App bar ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(children: [
                GlassContainer.light(
                  padding: const EdgeInsets.all(8),
                  borderRadius: AppRadius.full,
                  child: GestureDetector(
                    key: const Key('active_queue_home_btn'),
                    onTap: () => context.go('/home'),
                    child: const Icon(Icons.home_rounded, color: Colors.white, size: 20),
                  ),
                ),
                const Expanded(
                  child: Text('Your Queue', textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                ),
                GlassContainer.light(
                  padding: const EdgeInsets.all(8),
                  borderRadius: AppRadius.full,
                  child: GestureDetector(
                    key: const Key('active_queue_notifications_btn'),
                    onTap: () => context.push('/notifications'),
                    child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 20),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 12),

            // ── Live queue stream ────────────────────────
            Expanded(
              child: StreamBuilder<List<BookingModel>>(
                stream: FirebaseService.instance.getLiveQueueStream(businessId),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  }
                  
                  final list = snap.data ?? [];
                  final myItem = list.where((i) => i.id == bookingId).firstOrNull;
                  final active = list.where((i) => i.status == 'active').firstOrNull;
                  
                  final totalWaiting = list.where((b) => b.status == 'pending' || b.status == 'confirmed').length;
                  final myPosition = myItem?.queuePosition ?? totalWaiting + 1;
                  final myWait = myItem?.estimatedWaitMinutes ?? (totalWaiting * 15);
                  final isMyTurn = myPosition <= 1 && myItem?.status == 'active';

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: Column(children: [

                      // ── Token badge ──────────────────────────
                      GlassContainer.light(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        borderRadius: AppRadius.full,
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.confirmation_number_rounded, color: Colors.white70, size: 16),
                          const SizedBox(width: 8),
                          Text('Token  $tokenNumber',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17, fontFamily: 'monospace', letterSpacing: 2)),
                        ]),
                      ),
                      const SizedBox(height: 20),

                      // ── Position widget ──────────────────────
                      QueuePositionWidget(queueNumber: myPosition),
                      const SizedBox(height: 12),

                      // ── Bottom status bar ────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: AppShadows.e1),
                        child: Row(children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text('Live Status', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                              if (active != null)
                                Text('Serving ${active.tokenNumber.isNotEmpty ? active.tokenNumber : '#B000'}',
                                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 16)),
                            ]),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 20),

                      // ── Stacked avatars of people ahead ──────
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        ...List.generate(
                          totalWaiting > 4 ? 4 : totalWaiting,
                          (i) => Align(
                            widthFactor: i == (math.min(totalWaiting, 4) - 1) ? 1.0 : 0.7,
                            child: Container(
                              width: 34, height: 34,
                              decoration: BoxDecoration(
                                gradient: [AppGradients.primary, AppGradients.teal, AppGradients.warm, AppGradients.aurora][i % 4],
                                shape: BoxShape.circle,
                                border: const Border.fromBorderSide(BorderSide(color: Colors.white, width: 2)),
                              ),
                              child: const Icon(Icons.person_rounded, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text('$totalWaiting in queue',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                      ]),
                      const SizedBox(height: 20),

                      // ── My turn alert ────────────────────────
                      if (isMyTurn)
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.95, end: 1.05),
                          duration: const Duration(seconds: 1),
                          curve: Curves.easeInOut,
                          builder: (context, val, child) => Transform.scale(
                            scale: val,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 24),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(gradient: AppGradients.aurora, borderRadius: BorderRadius.circular(20), boxShadow: AppShadows.e3),
                              child: Column(children: [
                                const Icon(Icons.stars_rounded, color: Colors.white, size: 48),
                                const SizedBox(height: 12),
                                const Text("It's your turn!", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 6),
                                if (active != null)
                                  const Text('Please proceed to the counter or doctor’s room.',
                                    style: TextStyle(color: Colors.white, fontSize: 14), textAlign: TextAlign.center),
                              ]),
                            ),
                          ),
                        ),

                      const SizedBox(height: 20),

                      // ── Business info card ───────────────────
                      AnimatedCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(children: [
                          Container(
                            width: 50, height: 50,
                            decoration: const BoxDecoration(gradient: AppGradients.teal, shape: BoxShape.circle),
                            child: const Icon(Icons.store_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(businessName, style: AppTextStyles.h4),
                            const SizedBox(height: 2),
                            Text('$serviceName · Token $tokenNumber', style: AppTextStyles.caption),
                          ])),
                          if (active != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppRadius.full),
                              ),
                              child: Text('Serving ${active.tokenNumber.isNotEmpty ? active.tokenNumber : '#B000'}',
                                style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700)),
                            ),
                        ]),
                      ),
                      const SizedBox(height: 14),

                      // ── Notification reminder ─────────────────
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.notifications_active_outlined, color: Colors.white70, size: 16),
                        const SizedBox(width: 6),
                        const Text("We'll notify you when you're next!",
                          style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ]),
                      const SizedBox(height: 20),

                      // ── Action buttons ───────────────────────
                      Row(children: [
                        Expanded(child: PremiumButton(
                          key: const Key('queue_chat_btn'),
                          label: 'Chat',
                          gradient: AppGradients.teal,
                          onPressed: () => context.push('/chatbot'),
                          height: 46,
                          icon: Icons.smart_toy_outlined,
                        )),
                        const SizedBox(width: 10),
                        Expanded(child: PremiumButton(
                          key: const Key('queue_appt_btn'),
                          label: 'Bookings',
                          gradient: AppGradients.aurora,
                          onPressed: () => context.push('/appointments'),
                          height: 46,
                          icon: Icons.event_note_rounded,
                        )),
                        const SizedBox(width: 10),
                        Expanded(child: OutlinedButton.icon(
                          key: const Key('queue_cancel_btn'),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: ctx,
                              builder: (_) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
                                title: const Text('Cancel Booking?'),
                                content: const Text('Are you sure you want to leave this queue?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(_, false), child: const Text('No')),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(_, true),
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.coralError),
                                    child: const Text('Yes, Leave', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true && context.mounted) context.go('/home');
                          },
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text('Leave'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
                          ),
                        )),
                      ]),
                    ]),
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
