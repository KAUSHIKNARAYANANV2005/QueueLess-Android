import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/premium_button.dart';

class BusinessSettingsScreen extends StatefulWidget {
  const BusinessSettingsScreen({super.key});

  @override
  State<BusinessSettingsScreen> createState() => _BusinessSettingsScreenState();
}

class _BusinessSettingsScreenState extends State<BusinessSettingsScreen> {
  bool _isOpen = true;
  bool _autoAccept = true;
  bool _notifications = true;
  bool _smsReminders = false;
  int _maxQueueSize = 50;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Business Settings'), leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => context.pop())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Business status toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(gradient: _isOpen ? AppGradients.teal : const LinearGradient(colors: [Color(0xFFB0BEC5), Color(0xFF90A4AE)]), borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.e2),
              child: Row(children: [
                const Icon(Icons.store_rounded, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Business Status', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text(_isOpen ? 'Open for Bookings' : 'Closed', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                ])),
                Switch(value: _isOpen, onChanged: (v) => setState(() => _isOpen = v), activeColor: Colors.white, activeTrackColor: Colors.white38),
              ]),
            ),
            const SizedBox(height: 20),
            _SettingsSection(title: 'Queue Settings', children: [
              _ToggleSetting(label: 'Auto-accept bookings', subtitle: 'Automatically confirm new bookings', value: _autoAccept, onChanged: (v) => setState(() => _autoAccept = v)),
              const Divider(height: 1),
              ListTile(
                title: const Text('Max Queue Size', style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text('Currently $_maxQueueSize people'),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.primary), onPressed: () => setState(() => _maxQueueSize = (_maxQueueSize - 5).clamp(10, 200))),
                  SizedBox(width: 32, child: Text('$_maxQueueSize', style: AppTextStyles.h4, textAlign: TextAlign.center)),
                  IconButton(icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary), onPressed: () => setState(() => _maxQueueSize = (_maxQueueSize + 5).clamp(10, 200))),
                ]),
              ),
              const Divider(height: 1),
              ListTile(title: const Text('Business Hours', style: TextStyle(fontWeight: FontWeight.w500)), trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint), onTap: () {}),
              const Divider(height: 1),
              ListTile(title: const Text('Services & Pricing', style: TextStyle(fontWeight: FontWeight.w500)), trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint), onTap: () => context.push('/staff')),
            ]),
            const SizedBox(height: 12),
            _SettingsSection(title: 'Notifications', children: [
              _ToggleSetting(label: 'Push Notifications', subtitle: 'New bookings and queue updates', value: _notifications, onChanged: (v) => setState(() => _notifications = v)),
              const Divider(height: 1),
              _ToggleSetting(label: 'SMS Reminders', subtitle: 'Send SMS to customers', value: _smsReminders, onChanged: (v) => setState(() => _smsReminders = v)),
              const Divider(height: 1),
              ListTile(title: const Text('Notification Settings', style: TextStyle(fontWeight: FontWeight.w500)), trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint), onTap: () => context.push('/notification-settings')),
            ]),
            const SizedBox(height: 12),
            _SettingsSection(title: 'Account', children: [
              ListTile(title: const Text('Edit Business Profile', style: TextStyle(fontWeight: FontWeight.w500)), trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint), onTap: () {}),
              const Divider(height: 1),
              ListTile(title: const Text('Staff Management', style: TextStyle(fontWeight: FontWeight.w500)), trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint), onTap: () => context.push('/staff')),
              const Divider(height: 1),
              ListTile(title: const Text('Payment Settings', style: TextStyle(fontWeight: FontWeight.w500)), trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint), onTap: () {}),
            ]),
            const SizedBox(height: 12),
            _SettingsSection(title: 'Danger Zone', children: [
              ListTile(title: const Text('Delete Business Account', style: TextStyle(color: AppColors.coralError, fontWeight: FontWeight.w500)), leading: const Icon(Icons.delete_outline_rounded, color: AppColors.coralError), onTap: () {}),
            ]),
            const SizedBox(height: 20),
            PremiumButton(label: 'Save Changes', onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved!'))); }),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(title, style: AppTextStyles.label.copyWith(color: AppColors.textHint, letterSpacing: 1.2))),
        Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: AppShadows.e1), child: Column(children: children)),
      ],
    );
  }
}

class _ToggleSetting extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleSetting({required this.label, required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: AppTextStyles.caption),
      trailing: Switch(value: value, onChanged: onChanged, activeColor: AppColors.primary),
      dense: true,
    );
  }
}
