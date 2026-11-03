import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';

class NumpadWidget extends StatelessWidget {
  final ValueChanged<String> onDigitPressed;
  final VoidCallback onDeletePressed;
  final VoidCallback? onQuickSubmit;

  const NumpadWidget({
    super.key,
    required this.onDigitPressed,
    required this.onDeletePressed,
    this.onQuickSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRow(['1', '2', '3'], isDark),
          const SizedBox(height: 8),
          _buildRow(['4', '5', '6'], isDark),
          const SizedBox(height: 8),
          _buildRow(['7', '8', '9'], isDark),
          const SizedBox(height: 8),
          _buildBottomRow(isDark),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> values, bool isDark) {
    return Row(
      children: values.map((val) => Expanded(child: _buildNumberButton(val, isDark))).toList(),
    );
  }

  Widget _buildBottomRow(bool isDark) {
    return Row(
      children: [
        Expanded(child: _buildNumberButton('00', isDark)),
        Expanded(child: _buildNumberButton('0', isDark)),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Material(
              color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  HapticFeedback.lightImpact();
                  onDeletePressed();
                },
                child: const SizedBox(
                  height: 56,
                  child: Center(
                    child: Icon(LucideIcons.delete, size: 22),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberButton(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.lightImpact();
            onDigitPressed(text);
          },
          child: SizedBox(
            height: 56,
            child: Center(
              child: Text(
                text,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
