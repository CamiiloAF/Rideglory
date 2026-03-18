import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class RegistrationFormSectionCard extends StatelessWidget {
  const RegistrationFormSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final primary = context.colorScheme.primary;
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primary, size: 22),
              AppSpacing.hGapSm,
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trailing != null) ...[
                AppSpacing.hGapSm,
                trailing!,
              ],
            ],
          ),
          AppSpacing.gapLg,
          child,
        ],
      ),
    );
  }
}
