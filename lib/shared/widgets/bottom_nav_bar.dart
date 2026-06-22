import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isBusiness;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.isBusiness = false,
  });

  @override
  Widget build(BuildContext context) {
    final items = isBusiness
        ? _businessItems()
        : _customerItems();

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 72 + MediaQuery.of(context).padding.bottom,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            border: const Border(top: BorderSide(color: AppColors.border, width: 1)),
          ),
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isActive = index == currentIndex;
              final isCenterFab = !isBusiness && index == 2;

              if (isCenterFab) {
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(index),
                    child: Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: AppGradients.primary,
                          shape: BoxShape.circle,
                          boxShadow: AppShadows.e3,
                        ),
                        child: Icon(item['icon'] as IconData, color: Colors.white, size: 26),
                      ),
                    ),
                  ),
                );
              }

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0x1A6C63FF) : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Icon(
                          isActive ? item['activeIcon'] as IconData : item['icon'] as IconData,
                          color: isActive ? AppColors.primary : AppColors.textHint,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['label'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                          color: isActive ? AppColors.primary : AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _customerItems() => [
        {'icon': Icons.home_outlined, 'activeIcon': Icons.home_rounded, 'label': 'Home'},
        {'icon': Icons.search_outlined, 'activeIcon': Icons.search_rounded, 'label': 'Search'},
        {'icon': Icons.auto_awesome_outlined, 'activeIcon': Icons.auto_awesome, 'label': 'AI'},
        {'icon': Icons.calendar_today_outlined, 'activeIcon': Icons.calendar_today_rounded, 'label': 'Bookings'},
        {'icon': Icons.person_outline_rounded, 'activeIcon': Icons.person_rounded, 'label': 'Profile'},
      ];

  List<Map<String, dynamic>> _businessItems() => [
        {'icon': Icons.dashboard_outlined, 'activeIcon': Icons.dashboard_rounded, 'label': 'Dashboard'},
        {'icon': Icons.queue_outlined, 'activeIcon': Icons.queue_rounded, 'label': 'Queue'},
        {'icon': Icons.calendar_month_outlined, 'activeIcon': Icons.calendar_month_rounded, 'label': 'Bookings'},
        {'icon': Icons.medical_services_outlined, 'activeIcon': Icons.medical_services_rounded, 'label': 'Services'},
        {'icon': Icons.settings_outlined, 'activeIcon': Icons.settings_rounded, 'label': 'Settings'},
      ];
}
