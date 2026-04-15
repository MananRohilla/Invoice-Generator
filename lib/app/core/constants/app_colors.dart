import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const primary = Color(0xFF7C3AED);
  static const primaryDark = Color(0xFF5B21B6);
  static const primaryLight = Color(0xFFF5F3FF);
  static const accent = Color(0xFF00BFA5);
  static const accentLight = Color(0xFFE0F7FA);

  static const success = Color(0xFF34A853);
  static const successLight = Color(0xFFE6F4EA);
  static const warning = Color(0xFFFBBC04);
  static const warningLight = Color(0xFFFEF7E0);
  static const danger = Color(0xFFEA4335);
  static const dangerLight = Color(0xFFFCE8E6);

  static const background = Color(0xFFF8F9FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF1F3F4);

  static const textPrimary = Color(0xFF202124);
  static const textSecondary = Color(0xFF5F6368);
  static const textHint = Color(0xFF9AA0A6);

  static const divider = Color(0xFFE0E0E0);
  static const border = Color(0xFFDADCE0);
  static const cardShadow = Color(0x14000000);

  // Status chip colors
  static const statusPaid = success;
  static const statusPaidBg = successLight;
  static const statusSent = primary;
  static const statusSentBg = primaryLight;
  static const statusDraft = Color(0xFF9AA0A6);
  static const statusDraftBg = Color(0xFFF1F3F4);
  static const statusOverdue = danger;
  static const statusOverdueBg = dangerLight;
  static const statusPending = warning;
  static const statusPendingBg = warningLight;

  // Gradients
  static const List<Color> splashGradient = [Color(0xFF7C3AED), Colors.white];
  static const List<Color> cardGradientBlue = [Color(0xFF9333EA), Color(0xFF7C3AED)];
  static const List<Color> cardGradientTeal = [Color(0xFF00BFA5), Color(0xFF00897B)];
  static const List<Color> cardGradientGreen = [Color(0xFF34A853), Color(0xFF1E8E3E)];
  static const List<Color> cardGradientOrange = [Color(0xFFF9AB00), Color(0xFFE37400)];
  static const List<Color> cardGradientRed = [Color(0xFFEA4335), Color(0xFFC62828)];
}
