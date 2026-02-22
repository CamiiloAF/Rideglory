import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/shared/widgets/container_pull_to_refresh.dart';
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


  /// Icon size (defaults to 80)
  final double iconSize;

  /// Optional callback for pull-to-refresh
  final RefreshCallback? onRefresh;

  /// Whether to show an icon in the action button (defaults to true)
  final bool showButtonIcon;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.actionButtonText,
    this.onActionPressed,
    this.iconSize = 80,
    this.onRefresh,
    this.showButtonIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).colorScheme.primary;
    return ContainerPullToRefresh(
      onRefresh: onRefresh,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: iconSize,
                  color: iconColor,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                title,
                style: context.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
                  icon: showButtonIcon ? Icons.add : null,
                  isFullWidth: false,
                  width: MediaQuery.of(context).size.width * 0.7,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
