import 'package:flutter/material.dart';
import '../colors.dart';

class GuidanceSection extends StatelessWidget {
  final int selectedCount;

  const GuidanceSection({super.key, required this.selectedCount});

  String get _guidanceText {
    if (selectedCount == 0) return 'Tap symptoms below or use search to begin';
    if (selectedCount < 4) {
      return '$selectedCount symptom${selectedCount > 1 ? "s" : ""} selected • Add ${4 - selectedCount} more for better accuracy';
    }
    return '✓ $selectedCount symptoms selected • Great! Ready to predict';
  }

  Color get _guidanceColor {
    if (selectedCount == 0) return AppColors.guidanceEmpty;
    if (selectedCount < 4) return AppColors.guidanceWarning;
    return AppColors.guidanceGood;
  }

  IconData get _guidanceIcon {
    if (selectedCount == 0) return Icons.touch_app_rounded;
    if (selectedCount < 4) return Icons.add_circle_outline;
    return Icons.check_circle;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _guidanceColor.withOpacity(0.15),
            _guidanceColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _guidanceColor.withOpacity(0.4),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _guidanceColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _guidanceIcon,
              color: _guidanceColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _guidanceText,
              style: TextStyle(
                color: _guidanceColor,
                fontWeight: FontWeight.w600,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
