import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/nav_helper.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/widgets/premium_button.dart';
import '../../../shared/widgets/animated_card.dart';
import '../../../shared/widgets/glass_container.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final Map<String, dynamic> bookingData;
  const BookingConfirmationScreen({super.key, required this.bookingData});

  @override
  State<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  String _paymentMethod = 'cash';
  final _couponCtrl = TextEditingController();
  bool _loading = false;
  bool _couponApplied = false;

  @override
  void dispose() {
    _couponCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmBooking() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to book'), backgroundColor: AppColors.coralError),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final data = widget.bookingData;
      final businessId = data['businessId'] as String? ?? '';
      final businessName = data['businessName'] as String? ?? '';
      final serviceId = data['serviceId'] as String? ?? '';
      final serviceName = data['serviceName'] as String? ?? '';
      final price = (data['price'] ?? 0.0) as double;
      final dateTime = DateTime.tryParse(data['selectedDateTime'] ?? '') ?? DateTime.now();
      final discountAmount = _couponApplied ? 50.0 : 0.0;
      final tax = (price * 0.18);
      final total = price - discountAmount + tax;

      // Generate token number
      final tokenNumber = 'B${DateTime.now().millisecondsSinceEpoch % 1000}'.padLeft(4, '0');

      // Create booking in Firestore
      final booking = BookingModel(
        id: '',
        customerId: user.uid,
        customerName: user.displayName ?? user.email ?? 'Customer',
        businessId: businessId,
        businessName: businessName,
        serviceId: serviceId,
        serviceName: serviceName,
        staffId: data['staffId'] as String?,
        dateTime: dateTime,
        status: 'confirmed',
        queuePosition: 0,
        estimatedWaitMinutes: (data['duration'] ?? 15) as int,
        price: total,
        paymentStatus: _paymentMethod == 'cash' ? 'pending' : 'paid',
        tokenNumber: tokenNumber,
      );

      final bookingId = await FirebaseService.instance.createBooking(booking);

      if (mounted) {
        context.go('/queue', extra: {
          'businessId': businessId,
          'businessName': businessName,
          'bookingId': bookingId,
          'tokenNumber': tokenNumber,
          'serviceName': serviceName,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking failed: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: AppColors.coralError),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.bookingData;
    final serviceName = data['serviceName'] ?? 'Service';
    final businessName = data['businessName'] ?? 'Business';
    final selectedDate = data['selectedDate'] ?? 'Today';
    final selectedTime = data['selectedTime'] ?? '-';
    final price = (data['price'] ?? 0.0) as double;
    final discountAmount = _couponApplied ? 50.0 : 0.0;
    final tax = (price * 0.18);
    final total = price - discountAmount + tax;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Booking'),
        leading: const AppBackButton(),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            child: Column(
              children: [
                // Summary card
                AnimatedCard(
                  padding: const EdgeInsets.all(16),
                  baseShadow: AppShadows.e2,
                  child: Column(children: [
                    Row(children: [
                      Container(
                        width: 48, height: 48,
                        decoration: const BoxDecoration(gradient: AppGradients.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.store_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(businessName, style: AppTextStyles.h4),
                        Text(serviceName, style: AppTextStyles.caption),
                      ])),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(gradient: AppGradients.teal, borderRadius: BorderRadius.circular(AppRadius.full)),
                        child: const Text('Confirmed', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ]),
                    const Divider(height: 24),
                    _SummaryRow(label: 'Date', value: selectedDate),
                    _SummaryRow(label: 'Time', value: selectedTime),
                    _SummaryRow(label: 'Duration', value: '${data['duration'] ?? 15} min'),
                    _SummaryRow(label: 'Payment', value: _paymentMethod == 'cash' ? 'Pay at Venue' : 'Online'),
                  ]),
                ),
                const SizedBox(height: 16),
                // Pricing
                AnimatedCard(
                  padding: const EdgeInsets.all(16),
                  baseShadow: AppShadows.e1,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Price Details', style: AppTextStyles.h4),
                    const SizedBox(height: 12),
                    _SummaryRow(label: 'Service Fee', value: '₹${price.toInt()}'),
                    if (_couponApplied) _SummaryRow(label: 'Coupon Discount', value: '-₹${discountAmount.toInt()}', valueColor: AppColors.teal),
                    _SummaryRow(label: 'Tax (18%)', value: '₹${tax.toInt()}'),
                    const Divider(),
                    _SummaryRow(label: 'Total', value: '₹${total.toInt()}', isBold: true),
                  ]),
                ),
                const SizedBox(height: 16),
                // Payment methods
                AnimatedCard(
                  padding: const EdgeInsets.all(16),
                  baseShadow: AppShadows.e1,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Payment Method', style: AppTextStyles.h4),
                    const SizedBox(height: 8),
                    ...[
                      {'id': 'cash',       'label': 'Pay at Venue',        'icon': Icons.money_rounded},
                      {'id': 'upi',        'label': 'UPI / GPay / PhonePe','icon': Icons.qr_code_rounded},
                      {'id': 'card',       'label': 'Credit / Debit Card', 'icon': Icons.credit_card_rounded},
                      {'id': 'netbanking', 'label': 'Net Banking',         'icon': Icons.account_balance_outlined},
                    ].map((m) => RadioListTile<String>(
                      value: m['id'] as String,
                      groupValue: _paymentMethod,
                      onChanged: (v) => setState(() => _paymentMethod = v ?? 'cash'),
                      title: Text(m['label'] as String, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500)),
                      secondary: Icon(m['icon'] as IconData, color: AppColors.primary),
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    )),
                  ]),
                ),
                const SizedBox(height: 16),
                // Coupon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: AppShadows.e1,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _couponCtrl,
                        style: AppTextStyles.body,
                        decoration: InputDecoration(
                          hintText: 'Coupon code (try QUEUE50)',
                          hintStyle: AppTextStyles.body.copyWith(color: AppColors.textHint),
                          prefixIcon: const Icon(Icons.local_offer_rounded, color: AppColors.primary, size: 20),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    GestureDetector(
                      key: const Key('apply_coupon_btn'),
                      onTap: () {
                        if (_couponCtrl.text.trim().toUpperCase() == 'QUEUE50') {
                          setState(() => _couponApplied = true);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: const Text('Invalid coupon. Try QUEUE50'),
                            backgroundColor: AppColors.amber,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                          ));
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(gradient: AppGradients.teal, borderRadius: BorderRadius.circular(AppRadius.md)),
                        child: const Text('Apply', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ]),
                ),
                if (_couponApplied) Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.tealSuccess, size: 16),
                    const SizedBox(width: 4),
                    Text('Coupon QUEUE50 applied! Saved ₹50', style: AppTextStyles.bodySmall.copyWith(color: AppColors.tealSuccess)),
                  ]),
                ),
                const SizedBox(height: 16),
                // Cancellation policy
                ExpansionTile(
                  title: Text('Cancellation Policy', style: AppTextStyles.h4),
                  tilePadding: EdgeInsets.zero,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('Free cancellation up to 2 hours before your appointment. 50% refund if cancelled within 2 hours.', style: AppTextStyles.body),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + MediaQuery.of(context).padding.bottom),
              decoration: const BoxDecoration(color: Colors.white, boxShadow: AppShadows.e3),
              child: PremiumButton(
                label: 'Confirm & Join Queue  ₹${total.toInt()}',
                isLoading: _loading,
                onPressed: _confirmBooking,
                icon: Icons.queue_rounded,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;
  const _SummaryRow({required this.label, required this.value, this.isBold = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: isBold ? AppTextStyles.h4 : AppTextStyles.body),
          Text(value, style: (isBold ? AppTextStyles.h3 : AppTextStyles.body).copyWith(
            color: valueColor ?? (isBold ? AppColors.primary : null),
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          )),
        ],
      ),
    );
  }
}
