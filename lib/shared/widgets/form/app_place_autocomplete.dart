import 'package:flutter/material.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/services/place_service.dart';
import 'package:rideglory/shared/widgets/form/app_autocomplete_field.dart';

enum PlaceAutocompleteType {
  cities('cities'),
  establishment('establishment');

  const PlaceAutocompleteType(this.value);
  final String value;
}

class AppPlaceAutocompleteField extends StatelessWidget {
  const AppPlaceAutocompleteField({
    super.key,
    required this.name,
    required this.labelText,
    required this.hintText,
    required this.placeType,
    this.isRequired = false,
    this.validator,
    this.onSelected,
    this.focusNode,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  final String name;
  final String labelText;
  final String hintText;
  final PlaceAutocompleteType placeType;
  final bool isRequired;
  final String? Function(String?)? validator;
  final void Function(String)? onSelected;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(String? value)? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    final placeService = getIt<PlaceService>();
    return AppAutocompleteField(
      name: name,
      labelText: labelText,
      hintText: hintText,
      isRequired: isRequired,
      validator: validator,
      onSelected: onSelected,
      focusNode: focusNode,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      suggestions: (_) => const <String>[],
      remoteSuggestions: (query) async {
        if (query.trim().length < 2) {
          return const <String>[];
        }
        return placeService.autocomplete(query.trim(), placeType.value);
      },
      suggestionsPrefixIcon: placeType == PlaceAutocompleteType.cities
          ? Icons.location_city_outlined
          : Icons.place_outlined,
      suffixIcon: const Icon(Icons.search),
    );
  }
}
