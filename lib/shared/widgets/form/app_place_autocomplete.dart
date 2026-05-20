import 'package:flutter/material.dart';
import 'package:rideglory/shared/widgets/form/app_text_field.dart';

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
    return AppTextField(
      name: name,
      labelText: labelText,
      hintText: 'Próximamente disponible',
      enabled: false,
      suffixIcon: const Icon(Icons.place_outlined),
    );
  }
}
