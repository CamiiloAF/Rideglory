import 'package:flutter/material.dart';

class EventCardExpandToggle extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onTap;

  const EventCardExpandToggle({
    super.key,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: AnimatedRotation(
          turns: isExpanded ? 0.5 : 0.0,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
          child: Icon(
            Icons.keyboard_arrow_up_rounded,
            size: 20,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
