import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = _resolve(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'NotoSans',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  static (Color, Color, String) _resolve(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return (AppColors.statusPaidBg, AppColors.statusPaid, 'PAID');
      case 'sent':
        return (AppColors.statusSentBg, AppColors.statusSent, 'SENT');
      case 'overdue':
        return (AppColors.statusOverdueBg, AppColors.statusOverdue, 'OVERDUE');
      case 'draft':
      default:
        return (AppColors.statusDraftBg, AppColors.statusDraft, 'DRAFT');
    }
  }
}
