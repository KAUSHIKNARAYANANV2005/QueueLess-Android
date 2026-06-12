import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;

  const StatusBadge({super.key, required this.status, this.fontSize = 11});

  @override
  Widget build(BuildContext context) {
    Color bg;
    String label;
    switch (status.toLowerCase()) {
      case 'confirmed':
        bg = AppColors.tealSuccess;
        label = 'Confirmed';
        break;
      case 'pending':
        bg = AppColors.amberWarning;
        label = 'Pending';
        break;
      case 'cancelled':
      case 'canceled':
        bg = AppColors.coralError;
        label = 'Cancelled';
        break;
      case 'active':
        bg = AppColors.primary;
        label = 'Active';
        break;
      case 'served':
        bg = AppColors.textHint;
        label = 'Served';
        break;
      case 'paid':
        bg = AppColors.tealSuccess;
        label = 'Paid';
        break;
      case 'waiting':
        bg = AppColors.amberWarning;
        label = 'Waiting';
        break;
      default:
        bg = AppColors.textHint;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
