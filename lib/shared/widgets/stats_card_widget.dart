import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class StatsCardWidget extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final double? trendPercent;
  final bool trendUp;

  const StatsCardWidget({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.trendPercent,
    this.trendUp = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.e2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const Spacer(),
              if (trendPercent != null)
                Row(
                  children: [
                    Icon(
                      trendUp ? Icons.trending_up : Icons.trending_down,
                      size: 14,
                      color: trendUp ? AppColors.tealSuccess : AppColors.coralError,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${trendPercent!.toStringAsFixed(1)}%',
                      style: AppTextStyles.caption.copyWith(
                        color: trendUp ? AppColors.tealSuccess : AppColors.coralError,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: AppTextStyles.h2.copyWith(fontSize: 24)),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
