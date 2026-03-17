import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';

class RegistrationDetailCancelBar extends StatelessWidget {
  const RegistrationDetailCancelBar({
    super.key,
    required this.onCancel,
  });

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onCancel,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.error, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                EventStrings.cancelRegistration,
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

