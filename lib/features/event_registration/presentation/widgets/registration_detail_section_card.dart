import 'package:flutter/material.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/expandable_container.dart';
import 'package:rideglory/design_system/design_system.dart';

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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorderPrimary),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ExpandableContainer(
          initiallyExpanded: initiallyExpanded,
          trailingColor: AppColors.primary,
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primarySubtle,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          title: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textOnDarkPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
