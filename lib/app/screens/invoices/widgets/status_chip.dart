import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = _resolve(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'NotoSans',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  static (Color, Color, String) _resolve(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return (AppColors.success.withOpacity(0.12), AppColors.success, 'PAID');
      case 'sent':
        return (AppColors.primary.withOpacity(0.12), AppColors.primary, 'SENT');
      case 'overdue':
        return (AppColors.danger.withOpacity(0.12), AppColors.danger, 'OVERDUE');
      case 'pending':
        return (AppColors.warning.withOpacity(0.15), AppColors.warning, 'PENDING');
      case 'draft':
      default:
        return (AppColors.statusDraftBg, AppColors.statusDraft, 'DRAFT');
    }
  }
}
