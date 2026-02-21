import 'package:flutter/material.dart';

class AttendeeActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const AttendeeActionButton({
    super.key,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color.withOpacity(0.15),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        textStyle: Theme.of(context).textTheme.labelSmall,
      ),
      child: Text(label),
    );
  }
}
