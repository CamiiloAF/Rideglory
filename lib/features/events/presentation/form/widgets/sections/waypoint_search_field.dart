import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/shared/widgets/form/app_place_autocomplete.dart';

class WaypointSearchField extends StatelessWidget {
  const WaypointSearchField({super.key, required this.onSelected});

  final void Function(String) onSelected;

  @override
  Widget build(BuildContext context) {
    return AppPlaceAutocompleteField(
      name: 'waypoint_search_${DateTime.now().millisecondsSinceEpoch}',
      labelText: '',
      hintText: context.l10n.route_builder_search_placeholder,
      placeType: PlaceAutocompleteType.establishment,
      onSelected: onSelected,
    );
  }
}
