import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/fsrs.dart';

class GradeButtons extends StatelessWidget {
  final void Function(FSRSGrade grade) onGrade;

  const GradeButtons({super.key, required this.onGrade});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        _buildButton(
          context,
          label: 'Again',
          color: isDark ? AppColors.danger : AppColors.dangerLight,
          onTap: () => onGrade(FSRSGrade.again),
        ),
        const SizedBox(width: 8),
        _buildButton(
          context,
          label: 'Hard',
          color: isDark ? AppColors.warning : AppColors.warningLight,
          onTap: () => onGrade(FSRSGrade.hard),
        ),
        const SizedBox(width: 8),
        _buildButton(
          context,
          label: 'Good',
          color: isDark ? AppColors.accent : AppColors.accentLightMode,
          onTap: () => onGrade(FSRSGrade.good),
        ),
        const SizedBox(width: 8),
        _buildButton(
          context,
          label: 'Easy',
          color: isDark ? AppColors.success : AppColors.successLight,
          onTap: () => onGrade(FSRSGrade.easy),
        ),
      ],
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
