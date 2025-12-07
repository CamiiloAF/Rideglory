import 'package:flutter/material.dart';

class FabOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const FabOption({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ),
        const SizedBox(width: 12),
        FloatingActionButton.small(
          onPressed: onPressed,
          heroTag: label,
          child: Icon(icon),
        ),
      ],
    );
  }
}
