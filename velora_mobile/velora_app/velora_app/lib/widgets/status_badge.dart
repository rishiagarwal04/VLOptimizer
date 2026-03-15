import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'on_time':
        bgColor = const Color(0xFF10B981).withValues(alpha: 0.15);
        textColor = const Color(0xFF10B981);
        label = 'On Time';
        break;
      case 'within_tolerance':
        bgColor = const Color(0xFFF59E0B).withValues(alpha: 0.15);
        textColor = const Color(0xFFF59E0B);
        label = 'Within Tolerance';
        break;
      case 'violated':
        bgColor = const Color(0xFFEF4444).withValues(alpha: 0.15);
        textColor = const Color(0xFFEF4444);
        label = 'Violated';
        break;
      case 'unassigned':
        bgColor = const Color(0xFF6B7280).withValues(alpha: 0.15);
        textColor = const Color(0xFF6B7280);
        label = 'Unassigned';
        break;
      default:
        bgColor = const Color(0xFF3B82F6).withValues(alpha: 0.15);
        textColor = const Color(0xFF3B82F6);
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
