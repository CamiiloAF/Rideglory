import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';

class EventRouteTypeSelector extends StatelessWidget {
  const EventRouteTypeSelector({
    super.key,
    required this.onChanged,
  });

  final void Function(RouteType?) onChanged;

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<RouteType>(
      name: EventFormFields.routeType,
      builder: (field) {
        final selected = field.value ?? RouteType.simple;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.route_typeLabel.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: AppColors.textOnDarkTertiary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.darkBorderPrimary),
              ),
              child: Row(
                children: [
                  _RouteTypeTab(
                    label: context.l10n.route_simpleLabel,
                    icon: Icons.linear_scale_rounded,
                    isSelected: selected == RouteType.simple,
                    onTap: () {
                      field.didChange(RouteType.simple);
                      onChanged(RouteType.simple);
                    },
                  ),
                  _RouteTypeTab(
                    label: context.l10n.route_customLabel,
                    icon: Icons.route_outlined,
                    isSelected: selected == RouteType.custom,
                    onTap: () {
                      field.didChange(RouteType.custom);
                      onChanged(RouteType.custom);
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RouteTypeTab extends StatelessWidget {
  const _RouteTypeTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primarySubtle : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(color: AppColors.primary, width: 1.5)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textOnDarkTertiary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textOnDarkTertiary,
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
