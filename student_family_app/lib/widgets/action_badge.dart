import 'package:flutter/material.dart';

class ActionBadge extends StatelessWidget {
  final String action;

  const ActionBadge({super.key, required this.action});

  Color _getColor() {
    switch (action) {
      case 'CREATE':
        return const Color(0xFF10B981);
      case 'UPDATE':
        return const Color(0xFF3B82F6);
      case 'DELETE':
        return const Color(0xFFEF4444);
      case 'LOGIN':
        return const Color(0xFF8B5CF6);
      case 'LOGOUT':
        return const Color(0xFF6B7280);
      default:
        return Colors.grey;
    }
  }

  IconData _getIcon() {
    switch (action) {
      case 'CREATE':
        return Icons.add_circle_outline;
      case 'UPDATE':
        return Icons.edit_outlined;
      case 'DELETE':
        return Icons.delete_outline;
      case 'LOGIN':
        return Icons.login;
      case 'LOGOUT':
        return Icons.logout;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getIcon(), size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            action,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ],
      ),
    );
  }
}