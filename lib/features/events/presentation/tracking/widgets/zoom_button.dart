import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class ZoomButton extends StatelessWidget {
  const ZoomButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 48,
        height: 48,
        child: Icon(
          icon,
          color: isEnabled ? context.colorScheme.primary : context.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

