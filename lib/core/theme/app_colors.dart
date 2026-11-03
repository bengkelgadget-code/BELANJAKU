import 'package:flutter/material.dart';

class AppColors {
  // Brand / Primary
  static const Color primaryLight = Color(0xFF059669); // Emerald 600
  static const Color primaryDark = Color(0xFF34D399); // Emerald 400
  static const Color primaryTeal = Color(0xFF0D9488); // Teal 600

  // Income & Expense
  static const Color incomeLight = Color(0xFF16A34A); // Green 600
  static const Color incomeDark = Color(0xFF4ADE80); // Green 400
  static const Color expenseLight = Color(0xFFF97316); // Orange 500 (soft)
  static const Color expenseDark = Color(0xFFFB923C); // Orange 400
  static const Color danger = Color(0xFFE11D48); // Rose 600
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color info = Color(0xFF2563EB); // Blue 600

  // Background & Surfaces
  static const Color backgroundLight = Color(0xFFF6F7F9);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF0F1115);
  static const Color surfaceDark = Color(0xFF1C1E22);
  static const Color surfaceElevatedDark = Color(0xFF25282E);

  // Text
  static const Color textPrimaryLight = Color(0xFF111827);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textTertiaryLight = Color(0xFF9CA3AF);
  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);
  static const Color textTertiaryDark = Color(0xFF6B7280);

  // Borders & Dividers
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color borderDark = Color(0xFF2E3238);

  // Category Pastel Backgrounds (Light)
  static const Map<String, Color> categoryPastelsLight = {
    'EXP_MAKAN': Color(0xFFFEF3C7),
    'EXP_SEMBAKO': Color(0xFFDCFCE7),
    'EXP_TRANSPORT': Color(0xFFDBEAFE),
    'EXP_TAGIHAN': Color(0xFFEDE9FE),
    'EXP_RUMAH': Color(0xFFFCE7F3),
    'EXP_KESEHATAN': Color(0xFFFEE2E2),
    'EXP_PENDIDIKAN': Color(0xFFCCFBF1),
    'EXP_PAKAIAN': Color(0xFFE0E7FF),
    'EXP_HIBURAN': Color(0xFFFEF9C3),
    'EXP_SOSIAL': Color(0xFFFFEDD5),
    'EXP_KEUANGAN': Color(0xFFE0E7FF),
    'EXP_KERJA': Color(0xFFD1FAE5),
    'EXP_PELIHARAAN': Color(0xFFFEE2E2),
    'EXP_LAIN': Color(0xFFF3F4F6),
    // Income
    'INC_GAJI': Color(0xFFDCFCE7),
    'INC_USAHA': Color(0xFFCCFBF1),
    'INC_FREELANCE': Color(0xFFDBEAFE),
    'INC_INVESTASI': Color(0xFFEDE9FE),
    'INC_HADIAH': Color(0xFFFEF3C7),
    'INC_LAIN': Color(0xFFF3F4F6),
  };

  // Helper for Category color
  static Color getCategoryPastel(String code, {bool isDark = false}) {
    final lightColor = categoryPastelsLight[code] ?? const Color(0xFFF3F4F6);
    if (!isDark) return lightColor;
    return lightColor.withValues(alpha: 0.18);
  }

  // Linear gradient for total balance card
  static const LinearGradient balanceGradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF059669), Color(0xFF0D9488)],
  );

  static const LinearGradient balanceGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF065F46), Color(0xFF0F766E)],
  );
}
