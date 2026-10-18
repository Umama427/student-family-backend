import 'package:flutter/material.dart';

class GradeBadge extends StatelessWidget {
  final String grade;
  final double fontSize;

  const GradeBadge({super.key, required this.grade, this.fontSize = 12});

  Color _getColor() {
    switch (grade) {
      case 'A+':
        return const Color(0xFF10B981);
      case 'A':
        return const Color(0xFF22C55E);
      case 'B':
        return const Color(0xFF3B82F6);
      case 'C':
        return const Color(0xFFF59E0B);
      case 'D':
        return const Color(0xFFF97316);
      case 'F':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        grade.isEmpty ? '-' : grade,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: fontSize),
      ),
    );
  }
}