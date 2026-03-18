import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';

class LoginFieldLabel extends StatelessWidget {
  final String label;

  const LoginFieldLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: context.textTheme.labelSmall?.copyWith(
        color: context.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
