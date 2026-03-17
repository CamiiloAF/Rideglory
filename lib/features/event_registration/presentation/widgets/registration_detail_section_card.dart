import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/expandable_container.dart';

class RegistrationDetailSectionCard extends StatelessWidget {
  const RegistrationDetailSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.initiallyExpanded = true,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final primary = context.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ExpandableContainer(
          initiallyExpanded: initiallyExpanded,
          trailingColor: primary,
          leading: Icon(icon, color: primary, size: 22),
          title: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: primary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
