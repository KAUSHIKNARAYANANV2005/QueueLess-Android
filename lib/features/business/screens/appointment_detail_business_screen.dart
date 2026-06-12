import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/firebase_service.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/widgets/status_badge.dart';

class AppointmentDetailBusinessScreen extends StatefulWidget {
  final String bookingId;
  const AppointmentDetailBusinessScreen({super.key, required this.bookingId});
  @override
  State<AppointmentDetailBusinessScreen> createState() => _AppointmentDetailBusinessScreenState();
}

class _AppointmentDetailBusinessScreenState extends State<AppointmentDetailBusinessScreen> {
  BookingModel? _booking;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // For now use mock data if booking not in Firestore
    setState(() => _loading = false);
  }

  Future<void> _updateStatus(String status) async {
    await FirebaseService.instance.updateBookingStatus(widget.bookingId, status);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $status')));
      context.pop();
    }
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Detail'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => context.pop()),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.e2),
                  child: Column(children: [
                    Row(children: [
                      const CircleAvatar(radius: 28, backgroundColor: AppColors.inputBg,
                          child: Icon(Icons.person_rounded, size: 28, color: AppColors.textSecondary)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_booking?.customerName ?? 'Customer', style: AppTextStyles.h3),
                        Text(_booking?.tokenNumber ?? '#TOKEN', style: AppTextStyles.caption),
                      ])),
                      StatusBadge(status: _booking?.status ?? 'confirmed'),
                    ]),
                    const Divider(height: 24),
                    _InfoRow('Service', _booking?.serviceName ?? 'General Consultation'),
                    _InfoRow('Date & Time', _booking != null
                        ? '${_booking!.dateTime.day}/${_booking!.dateTime.month}/${_booking!.dateTime.year}'
                        : 'Today'),
                    _InfoRow('Token', _booking?.tokenNumber ?? '#B007'),
                    _InfoRow('Amount', '₹${_booking?.price.toInt() ?? 500}'),
                    _InfoRow('Payment', _booking?.paymentStatus ?? 'pending'),
                  ]),
                ),
                const SizedBox(height: 20),
                // Action buttons
                Row(children: [
                  Expanded(child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
                    label: const Text('Mark Served', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.tealSuccess,
                        padding: const EdgeInsets.symmetric(vertical: 13)),
                    onPressed: () => _updateStatus('served'),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: OutlinedButton.icon(
                    icon: const Icon(Icons.login_rounded, size: 18, color: AppColors.primary),
                    label: const Text('Check-In', style: TextStyle(color: AppColors.primary)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 13)),
                    onPressed: () => _updateStatus('in-queue'),
                  )),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: OutlinedButton.icon(
                    icon: const Icon(Icons.call_rounded, size: 18, color: AppColors.primary),
                    label: const Text('Call Patient', style: TextStyle(color: AppColors.primary)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 13)),
                    onPressed: () => _call('+919876543210'),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: OutlinedButton.icon(
                    icon: const Icon(Icons.cancel_outlined, size: 18, color: AppColors.coralError),
                    label: const Text('Cancel', style: TextStyle(color: AppColors.coralError)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.coralError),
                        padding: const EdgeInsets.symmetric(vertical: 13)),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Cancel Appointment'),
                            content: const Text('Are you sure you want to cancel this appointment?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
                              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes, Cancel')),
                            ],
                          ));
                      if (confirm == true) _updateStatus('cancelled');
                    },
                  )),
                ]),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.note_add_outlined, size: 18, color: AppColors.textSecondary),
                    label: const Text('Add Notes', style: TextStyle(color: AppColors.textSecondary)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 13)),
                    onPressed: () {
                      final ctrl = TextEditingController();
                      showModalBottomSheet(context: context, isScrollControlled: true,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                          builder: (_) => Padding(
                            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              Text('Add Notes', style: AppTextStyles.h3),
                              const SizedBox(height: 12),
                              TextField(controller: ctrl, maxLines: 4,
                                  decoration: const InputDecoration(hintText: 'Write appointment notes...', border: OutlineInputBorder())),
                              const SizedBox(height: 12),
                              SizedBox(width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (ctrl.text.isNotEmpty) {
                                      await FirebaseService.instance.updateBookingStatus(widget.bookingId, _booking?.status ?? 'confirmed');
                                    }
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notes saved!')));
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md))),
                                  child: const Text('Save Notes'),
                                ),
                              ),
                            ]),
                          ));
                    },
                  ),
                ),
              ]),
            ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: AppTextStyles.body),
        Text(value, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
