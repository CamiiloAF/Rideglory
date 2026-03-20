import 'package:flutter/material.dart';
import 'package:rideglory/core/utils/initials.dart';
import 'package:rideglory/design_system/design_system.dart';

class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.firstName,
    required this.lastName,
    this.radius = 24,
    this.backgroundColor,
    this.textStyle,
  });

  final String firstName;
  final String lastName;
  final double radius;
  final Color? backgroundColor;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final resolvedBackground = backgroundColor ?? context.colorScheme.primary;
    final baseStyle = context.textTheme.titleMedium?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.bold,
    ) ?? const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 16,
    );
    final resolvedTextStyle = textStyle ?? baseStyle.copyWith(
      fontSize: radius * 0.6,
    );

    return CircleAvatar(
      radius: radius,
      backgroundColor: resolvedBackground,
      child: Text(
        Initials.buildInitials(firstName: firstName, lastName: lastName),
        style: resolvedTextStyle,
      ),
    );
  }
}

