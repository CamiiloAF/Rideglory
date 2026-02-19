import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/shared/widgets/form/app_button.dart';

/// A reusable empty state widget that can be used across features
/// to show when lists or data are empty.
class EmptyStateWidget extends StatelessWidget {
  /// The icon to display in the empty state
  final IconData icon;

  /// The title/heading text
  final String title;

  /// Optional description text
  final String? description;

  /// Optional action button text
  final String? actionButtonText;

  /// Callback when action button is pressed
  final VoidCallback? onActionPressed;

  /// Icon color (defaults to grey)
  final Color? iconColor;

  /// Icon size (defaults to 80)
  final double iconSize;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.actionButtonText,
    this.onActionPressed,
    this.iconColor,
    this.iconSize = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (iconColor ?? Colors.grey[400])?.withValues(alpha: .1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: iconColor ?? Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              title,
              style: context.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            // Description (if provided)
            if (description != null) ...[
              const SizedBox(height: 12),
              Text(
                description!,
                style: context.bodyMedium?.copyWith(height: 1.5),
                textAlign: TextAlign.center,
              ),
            ],

            if (actionButtonText != null && onActionPressed != null) ...[
              const SizedBox(height: 32),
              AppButton(
                label: actionButtonText!,
                onPressed: onActionPressed,
                icon: Icons.add,
                isFullWidth: false,
                width: MediaQuery.of(context).size.width * 0.7,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
