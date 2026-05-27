import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/route_type_tab.dart';

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
                  RouteTypeTab(
                    label: context.l10n.route_simpleLabel,
                    icon: Icons.linear_scale_rounded,
                    isSelected: selected == RouteType.simple,
                    onTap: () {
                      field.didChange(RouteType.simple);
                      onChanged(RouteType.simple);
                    },
                  ),
                  RouteTypeTab(
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
