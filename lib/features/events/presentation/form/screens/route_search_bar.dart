import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/waypoint_search_field.dart';
import 'package:rideglory/shared/models/address_location.dart';

class RouteSearchBar extends StatelessWidget {
  const RouteSearchBar({
    super.key,
    required this.atLimit,
    required this.onPlaceSelected,
  });

  final bool atLimit;
  final void Function(String name, AddressLocation? location) onPlaceSelected;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: atLimit ? 0.6 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: atLimit ? AppColors.darkTertiary : AppColors.darkBgSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.darkBorderPrimary),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            const Icon(
              Icons.search,
              size: 16,
              color: AppColors.textOnDarkTertiary,
            ),
            const SizedBox(width: 10),
            if (atLimit)
              Expanded(
                child: Text(
                  context.l10n.route_builder_search_placeholder_disabled,
                  style: const TextStyle(
                    fontFamily: 'Space Grotesk',
                    color: AppColors.textOnDarkTertiary,
                    fontSize: 14,
                  ),
                ),
              )
            else
              Expanded(
                child: WaypointSearchField(
                  onPlaceSelected: onPlaceSelected,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
