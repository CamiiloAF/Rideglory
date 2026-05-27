import 'package:flutter/material.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/shared/models/address_location.dart';
import 'package:rideglory/shared/widgets/form/app_place_autocomplete.dart';

class RoutePointRow extends StatelessWidget {
  const RoutePointRow({
    super.key,
    required this.dotColor,
    required this.fieldName,
    required this.hintText,
    required this.onPlaceSelected,
  });

  final Color dotColor;
  final String fieldName;
  final String hintText;
  final void Function(String name, AddressLocation? location) onPlaceSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AppPlaceAutocompleteField(
              name: fieldName,
              labelText: '',
              hintText: hintText,
              placeType: PlaceAutocompleteType.establishment,
              isRequired: true,
              showMapPicker: true,
              compact: true,
              resolveCoords: true,
              textInputAction: TextInputAction.next,
              validator: FormBuilderValidators.required(
                errorText: fieldName == EventFormFields.meetingPoint
                    ? context.l10n.event_meetingPointRequired
                    : context.l10n.event_destinationRequired,
              ),
              onPlaceSelected: onPlaceSelected,
            ),
          ),
        ],
      ),
    );
  }
}
