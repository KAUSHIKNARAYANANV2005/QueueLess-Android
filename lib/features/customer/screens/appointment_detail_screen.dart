import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/nav_helper.dart';
import '../../../shared/widgets/status_badge.dart';

class AppointmentDetailScreen extends StatelessWidget {
  final String bookingId;
  const AppointmentDetailScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details'),
        leading: const AppBackButton(fallback: '/appointments'),
        actions: [
          IconButton(key: const Key('share_appointment_btn'), icon: const Icon(Icons.share_outlined), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // QR Ticket
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppShadows.e4,
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      gradient: AppGradients.primary,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Row(
                      children: [
                        Container(width: 40, height: 40, decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle), child: const Icon(Icons.local_hospital_outlined, color: Colors.white, size: 20)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Dr. Sharma Clinic', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                          const Text('General Consultation', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ])),
                        StatusBadge(status: 'confirmed'),
                      ],
                    ),
                  ),
                  // Dashed divider
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 0),
                    child: CustomPaint(
                      size: Size(MediaQuery.of(context).size.width - 32, 24),
                      painter: _DashedDividerPainter(),
                    ),
                  ),
                  // QR code
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      children: [
                        QrImageView(data: 'QUEUELESS-${bookingId.isEmpty ? 'BK001' : bookingId}', size: 160, backgroundColor: Colors.white),
                        const SizedBox(height: 8),
                        Text('BK-${bookingId.isEmpty ? '001' : bookingId.substring(0, 3).toUpperCase()}', style: AppTextStyles.otpText.copyWith(fontSize: 18)),
                        Text('Show this QR at the clinic', style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Details
            _DetailCard(title: 'Appointment Info', items: [
              {'label': 'Date', 'value': 'April 5, 2026'},
              {'label': 'Time', 'value': '10:00 AM'},
              {'label': 'Doctor', 'value': 'Dr. Sharma'},
              {'label': 'Token', 'value': '#B007'},
            ]),
            const SizedBox(height: 12),
            _DetailCard(title: 'Payment', items: [
              {'label': 'Amount', 'value': '₹354'},
              {'label': 'Method', 'value': 'UPI'},
              {'label': 'Status', 'value': 'Paid'},
            ]),
            const SizedBox(height: 20),
            // Actions
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Reschedule'),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary), padding: const EdgeInsets.symmetric(vertical: 12)),
              )),
              const SizedBox(width: 12),
              Expanded(child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.cancel_outlined, size: 16),
                label: const Text('Cancel'),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.coralError, side: const BorderSide(color: AppColors.coralError), padding: const EdgeInsets.symmetric(vertical: 12)),
              )),
            ]),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: ElevatedButton.icon(
              onPressed: () => context.push('/reviews'),
              icon: const Icon(Icons.star_outline_rounded, size: 16),
              label: const Text('Write a Review'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.amberWarning, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
            )),
          ],
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final List<Map<String, String>> items;
  const _DetailCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.e1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.h4),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(item['label']!, style: AppTextStyles.body),
              Text(item['value']!, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ]),
          )),
        ],
      ),
    );
  }
}

class _DashedDividerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.border..strokeWidth = 1;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, size.height / 2), Offset(x + 8, size.height / 2), paint);
      x += 14;
    }
    // Circle cutouts
    canvas.drawCircle(Offset(-16, size.height / 2), 16, Paint()..color = AppColors.background);
    canvas.drawCircle(Offset(size.width + 16, size.height / 2), 16, Paint()..color = AppColors.background);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
