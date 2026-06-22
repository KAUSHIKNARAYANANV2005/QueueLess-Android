import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/firebase_service.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/premium_button.dart';
import '../../../shared/widgets/premium_input.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../core/theme/theme_provider.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _saving = false;
  bool _initialized = false;
  
  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateProfile(String uid) async {
    setState(() => _saving = true);
    try {
      await FirebaseService.instance.updateUser(uid, {
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      });
      await FirebaseAuth.instance.currentUser?.updateDisplayName(_nameCtrl.text.trim());
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
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseService.instance.signOut();
      if (mounted) context.go('/role-selection');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign out failed: $e'), backgroundColor: AppColors.coralError),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: const Center(child: Text('Not logged in')),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppGradients.bgDark : AppGradients.bgLight,
        ),
        child: StreamBuilder<UserModel?>(
          stream: FirebaseService.instance.getUserStream(uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !_initialized) {
              return const Center(child: CircularProgressIndicator());
            }
            final user = snapshot.data;
            if (user != null && !_initialized) {
              _nameCtrl.text = user.name;
              _phoneCtrl.text = user.phone;
              _initialized = true;
            }

            final displayName = user?.name ?? FirebaseAuth.instance.currentUser?.displayName ?? 'User';
            final email = user?.email ?? FirebaseAuth.instance.currentUser?.email ?? '';

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 240,
                  pinned: true,
                  backgroundColor: AppColors.primary,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                    onPressed: () {
                      if (context.canPop()) context.pop();
                      else context.go('/home');
                    },
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(gradient: AppGradients.primary),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 60),
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 46,
                                backgroundColor: Colors.white24,
                                backgroundImage: user?.profileImage != null ? NetworkImage(user!.profileImage!) : null,
                                child: user?.profileImage == null
                                    ? Text(
                                        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                                        style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700),
                                      )
                                    : null,
                              ),
                              Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(gradient: AppGradients.teal, shape: BoxShape.circle),
                                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text('Member since ${user?.createdAt.year ?? DateTime.now().year}', 
                              style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Personal Information', style: AppTextStyles.h2),
                        const SizedBox(height: 16),
                        isDark 
                          ? GlassContainer.dark(child: _buildForm(email, uid))
                          : GlassContainer.light(child: _buildForm(email, uid)),
                        const SizedBox(height: 32),
                        Text('App Preferences', style: AppTextStyles.h2),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: AppShadows.e1,
                          ),
                          child: Row(
                            children: [
                              Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: AppColors.primary, size: 24),
                              const SizedBox(width: 12),
                              Expanded(child: Text('Dark Mode', style: AppTextStyles.h4)),
                              Switch(
                                value: isDark,
                                onChanged: (v) {
                                  themeNotifier.value = v ? ThemeMode.dark : ThemeMode.light;
                                },
                                activeColor: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        Center(
                          child: TextButton.icon(
                            onPressed: _signOut,
                            icon: const Icon(Icons.logout_rounded, color: AppColors.coralError),
                            label: const Text('Sign Out', style: TextStyle(color: AppColors.coralError, fontWeight: FontWeight.w600, fontSize: 16)),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildForm(String email, String uid) {
    return Column(
      children: [
        PremiumInput(
          label: 'Full Name',
          hint: 'Enter your full name',
          controller: _nameCtrl,
          prefixIcon: Icons.person_outline,
        ),
        const SizedBox(height: 16),
        PremiumInput(
          label: 'Phone Number',
          hint: '10-digit number',
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          prefixIcon: Icons.phone_outlined,
        ),
        const SizedBox(height: 16),
        PremiumInput(
          label: 'Email Address',
          hint: 'Email',
          controller: TextEditingController(text: email),
          readOnly: true,
          prefixIcon: Icons.email_outlined,
        ),
        const SizedBox(height: 24),
        PremiumButton(
          label: 'Save Changes',
          isLoading: _saving,
          onPressed: () => _updateProfile(uid),
        ),
      ],
    );
  }
}
