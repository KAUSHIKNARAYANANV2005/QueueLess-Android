import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/premium_button.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String _selectedRole = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Gradient header - Fixed height or proportional
          ClipPath(
            clipper: _WaveClipper(),
            child: Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.35,
              decoration: const BoxDecoration(gradient: AppGradients.primary),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.people_alt_rounded,
                        color: Colors.white, size: 56),
                    const SizedBox(height: 12),
                    Text(
                      'Who are you?',
                      style: AppTextStyles.h1.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose your role to continue',
                      style: AppTextStyles.body
                          .copyWith(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Cards and Buttons
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildRoleCard(
                          'Customer',
                          Icons.person_rounded,
                          'Book appointments & track queues',
                          AppColors.primary,
                          'customer',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildRoleCard(
                          'Business',
                          Icons.store_rounded,
                          'Manage your queue & bookings',
                          AppColors.tealSuccess,
                          'business',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  PremiumButton(
                    key: const Key('role_continue_btn'),
                    label: 'Continue',
                    onPressed: _selectedRole.isEmpty
                        ? null
                        : () => context.go('/register/$_selectedRole'),
                    icon: Icons.arrow_forward_rounded,
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () {
                      if (_selectedRole.isNotEmpty) {
                        context.go('/login?role=$_selectedRole');
                      } else {
                        context.go('/login');
                      }
                    },
                    child: Text.rich(
                      TextSpan(
                        text: 'Already have an account? ',
                        style: AppTextStyles.body,
                        children: [
                          TextSpan(
                            text: 'Sign In',
                            style: AppTextStyles.body.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard(String title, IconData icon, String desc, Color color,
      String role) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      key: Key('role_card_$role'),
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: isSelected
            ? AppShadows.glow(color, intensity: 0.2)
            : AppShadows.e1,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isSelected ? color : color.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? Colors.white : color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyles.h4.copyWith(
                color: isSelected ? color : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              desc,
              style: AppTextStyles.caption.copyWith(
                height: 1.3,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(
        size.width / 4, size.height, size.width / 2, size.height - 25);
    path.quadraticBezierTo(
        size.width * 3 / 4, size.height - 50, size.width, size.height - 25);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
