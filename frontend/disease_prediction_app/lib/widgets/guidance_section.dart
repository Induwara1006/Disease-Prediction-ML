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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _guidanceColor.withOpacity(0.85),
            _guidanceColor.withOpacity(0.65),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _guidanceColor.withOpacity(0.8),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _guidanceColor.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
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
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
                height: 1.4,
                letterSpacing: 0.3,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
