import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _queueUpdates = true;
  bool _bookingConfirmations = true;
  bool _reminders = true;
  bool _offerAlerts = false;
  bool _appUpdates = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings'), leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => context.pop())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Icon header
            Container(
              height: 100,
              decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(16)),
              child: const Center(child: Icon(Icons.notifications_active_rounded, color: Colors.white, size: 44)),
            ),
            const SizedBox(height: 20),
            _settingsSection('Queue & Bookings', [
              _ToggleRow(icon: Icons.queue_rounded, label: 'Queue Updates', subtitle: 'When your position changes', value: _queueUpdates, onChanged: (v) => setState(() => _queueUpdates = v)),
              const Divider(height: 1),
              _ToggleRow(icon: Icons.check_circle_outline_rounded, label: 'Booking Confirmations', subtitle: 'When a booking is confirmed', value: _bookingConfirmations, onChanged: (v) => setState(() => _bookingConfirmations = v)),
              const Divider(height: 1),
              _ToggleRow(icon: Icons.alarm_rounded, label: 'Appointment Reminders', subtitle: '30 min before your appointment', value: _reminders, onChanged: (v) => setState(() => _reminders = v)),
            ]),
            const SizedBox(height: 12),
            _settingsSection('Promotions', [
              _ToggleRow(icon: Icons.local_offer_outlined, label: 'Offers & Discounts', subtitle: 'Special deals and coupons', value: _offerAlerts, onChanged: (v) => setState(() => _offerAlerts = v)),
              const Divider(height: 1),
              _ToggleRow(icon: Icons.system_update_alt_rounded, label: 'App Updates', subtitle: 'New features and improvements', value: _appUpdates, onChanged: (v) => setState(() => _appUpdates = v)),
            ]),
            const SizedBox(height: 12),
            _settingsSection('Channels', [
              _ToggleRow(icon: Icons.email_outlined, label: 'Email Notifications', subtitle: 'Receive emails from QueueLess', value: _emailNotifications, onChanged: (v) => setState(() => _emailNotifications = v)),
              const Divider(height: 1),
              _ToggleRow(icon: Icons.sms_outlined, label: 'SMS Notifications', subtitle: 'Receive SMS alerts', value: _smsNotifications, onChanged: (v) => setState(() => _smsNotifications = v)),
            ]),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification preferences saved!'))); },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md))),
              child: const Text('Save Preferences', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            )),
          ],
        ),
      ),
    );
  }

  Widget _settingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(title, style: AppTextStyles.label.copyWith(color: AppColors.textHint, letterSpacing: 1.2))),
        Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: AppShadows.e1), child: Column(children: children)),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({required this.icon, required this.label, required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.inputBg, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: AppColors.primary, size: 18)),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: AppTextStyles.caption),
      trailing: Switch(value: value, onChanged: onChanged, activeColor: AppColors.primary),
      dense: true,
    );
  }
}
