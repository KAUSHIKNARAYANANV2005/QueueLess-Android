import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/firebase_service.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../../shared/widgets/premium_button.dart';
import '../../../shared/widgets/premium_input.dart';
import '../../../shared/widgets/glass_container.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  UserModel? _user;
  int _bookingCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final user = await FirebaseService.instance.getUserById(uid);
      final bookings = await FirebaseService.instance.getUserBookings(uid);
      if (mounted) {
        setState(() {
          _user = user;
          _bookingCount = bookings.length;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showEditProfileDialog() async {
    final nameCtrl = TextEditingController(text: _user?.name ?? FirebaseAuth.instance.currentUser?.displayName ?? '');
    final phoneCtrl = TextEditingController(text: _user?.phone ?? '');
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Edit Profile', style: AppTextStyles.h3),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PremiumInput(
                    label: 'Name',
                    hint: 'Your full name',
                    controller: nameCtrl,
                    prefixIcon: Icons.person_outline,
                  ),
                  const SizedBox(height: 12),
                  PremiumInput(
                    label: 'Phone',
                    hint: '+91 98765 43210',
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_outlined,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(ctx),
                  child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                SizedBox(
                  width: 100,
                  height: 36,
                  child: PremiumButton(
                    label: 'Save',
                    isLoading: saving,
                    onPressed: saving ? null : () async {
                      setDialogState(() => saving = true);
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid != null) {
                        try {
                          await FirebaseService.instance.updateUser(uid, {
                            'name': nameCtrl.text.trim(),
                            'phone': phoneCtrl.text.trim(),
                          });
                          await FirebaseAuth.instance.currentUser?.updateDisplayName(nameCtrl.text.trim());
                          await _loadProfile();
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: AppColors.tealSuccess),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Update failed: $e'), backgroundColor: AppColors.coralError),
                            );
                          }
                        }
                      }
                      setDialogState(() => saving = false);
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    nameCtrl.dispose();
    phoneCtrl.dispose();
  }

  Future<void> _sendPasswordReset() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;
    try {
      await FirebaseService.instance.sendPasswordResetEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset email sent to $email. Please check your inbox!'),
            backgroundColor: AppColors.tealSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send reset email: $e'),
            backgroundColor: AppColors.coralError,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _user?.name ??
        FirebaseAuth.instance.currentUser?.displayName ??
        'User';
    final displayEmail = _user?.email ??
        FirebaseAuth.instance.currentUser?.email ??
        '';
    final displayPhone = _user?.phone ?? '';

    return Scaffold(
      body: _loading
          ? ListView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                LoadingShimmer.shimmerCard(),
                LoadingShimmer.shimmerListItem(),
                LoadingShimmer.shimmerListItem(),
                LoadingShimmer.shimmerListItem(),
              ],
            )
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 240,
                  pinned: true,
                  backgroundColor: AppColors.primary,
                  leading: IconButton(
                    key: const Key('back_button'),
                    icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/home');
                      }
                    },
                  ),
                  actions: [
                    IconButton(
                      icon:
                          const Icon(Icons.edit_outlined, color: Colors.white),
                      onPressed: _showEditProfileDialog,
                    )
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration:
                          const BoxDecoration(gradient: AppGradients.primary),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 60),
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 44,
                                backgroundColor: Colors.white24,
                                child: Text(
                                  displayName.isNotEmpty
                                      ? displayName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                    gradient: AppGradients.teal,
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.camera_alt_rounded,
                                    color: Colors.white, size: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(displayName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700)),
                          Text(displayEmail,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                          if (displayPhone.isNotEmpty)
                            Text(displayPhone,
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildListDelegate([
                    // Stats
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                              child: _StatCard(
                                  value: '$_bookingCount',
                                  label: 'Bookings')),
                          const SizedBox(width: 8),
                          Expanded(
                              child: _StatCard(
                                  value: _bookingCount > 0
                                      ? '${(_bookingCount * 0.7).round()}'
                                      : '0',
                                  label: 'Visited')),
                          const SizedBox(width: 8),
                          const Expanded(
                              child: _StatCard(value: '4.8', label: 'Avg Rating')),
                        ],
                      ),
                    ),
                    // Menu sections
                     _MenuSection(title: 'Account', items: [
                      _MenuItem(
                          icon: Icons.person_outline_rounded,
                          label: 'Edit Profile',
                          onTap: _showEditProfileDialog),
                      _MenuItem(
                          icon: Icons.phone_outlined,
                          label: 'Update Phone',
                          onTap: _showEditProfileDialog),
                      _MenuItem(
                          icon: Icons.lock_outline_rounded,
                          label: 'Change Password',
                          onTap: _sendPasswordReset),
                    ]),
                    _MenuSection(title: 'My Activity', items: [
                      _MenuItem(
                          icon: Icons.calendar_today_outlined,
                          label: 'My Appointments',
                          onTap: () => context.go('/appointments')),
                      _MenuItem(
                          icon: Icons.account_balance_wallet_outlined,
                          label: 'Wallet & Payments',
                          onTap: () => context.go('/wallet')),
                      _MenuItem(
                          icon: Icons.star_outline_rounded,
                          label: 'My Reviews',
                          onTap: () {}),
                    ]),
                    _MenuSection(title: 'Preferences', items: [
                      _MenuItem(
                          icon: Icons.notifications_outlined,
                          label: 'Notifications',
                          onTap: () =>
                              context.push('/notification-settings')),
                      _MenuItem(
                          icon: Icons.language_outlined,
                          label: 'Language',
                          onTap: () {}),
                      _MenuItem(
                        icon: Icons.dark_mode_outlined,
                        label: 'Dark Mode',
                        onTap: () {},
                        trailing: Switch(
                            value: false,
                            onChanged: (_) {},
                            activeColor: AppColors.primary),
                      ),
                    ]),
                    _MenuSection(title: 'Support', items: [
                       _MenuItem(
                           icon: Icons.help_outline_rounded,
                           label: 'Help & FAQ',
                           onTap: () => context.go('/help')),
                      _MenuItem(
                          icon: Icons.privacy_tip_outlined,
                          label: 'Privacy Policy',
                          onTap: () {}),
                      _MenuItem(
                          icon: Icons.description_outlined,
                          label: 'Terms of Service',
                          onTap: () {}),
                    ]),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: _LogoutButton(),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ]),
                ),
              ],
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppShadows.e1),
      child: Column(children: [
        Text(value,
            style: AppTextStyles.h2.copyWith(color: AppColors.primary)),
        Text(label, style: AppTextStyles.caption),
      ]),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<Widget> items;
  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(title,
              style: AppTextStyles.label
                  .copyWith(color: AppColors.textHint, letterSpacing: 1.2)),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppShadows.e1),
          child: Column(children: items),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  const _MenuItem(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.trailing});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
            color: AppColors.inputBg,
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: AppColors.primary, size: 18),
      ),
      title: Text(label,
          style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary)),
      trailing: trailing ??
          const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
      onTap: onTap,
      dense: true,
    );
  }
}

class _LogoutButton extends StatefulWidget {
  const _LogoutButton();
  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton> {
  bool _loading = false;

  Future<void> _signOut() async {
    setState(() => _loading = true);
    try {
      await FirebaseService.instance.signOut();
      if (mounted) context.go('/role-selection');
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign out failed: $e'), backgroundColor: AppColors.coralError),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      key: const Key('logout_button'),
      onPressed: _loading ? null : _signOut,
      icon: _loading
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.coralError))
          : const Icon(Icons.logout_rounded, color: AppColors.coralError),
      label: Text(
        _loading ? 'Signing out...' : 'Sign Out',
        style: const TextStyle(color: AppColors.coralError, fontWeight: FontWeight.w600, fontSize: 16),
      ),
    );
  }
}
