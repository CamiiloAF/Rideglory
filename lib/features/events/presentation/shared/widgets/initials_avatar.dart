import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/core/theme/app_colors.dart';

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

  static String _buildInitials(String firstName, String lastName) {
    final first = firstName.isNotEmpty ? firstName[0] : '';
    final last = lastName.isNotEmpty ? lastName[0] : '';
    return '${first.toUpperCase()}${last.toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final resolvedBackground = backgroundColor ?? AppColors.primaryDark;
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
        _buildInitials(firstName, lastName),
        style: resolvedTextStyle,
      ),
    );
  }
}

