import 'package:flutter/material.dart';
import 'package:rideglory/core/data/colombia_cities_data.dart';
import 'package:rideglory/shared/widgets/form/app_autocomplete_field.dart';

/// Shared city autocomplete field using Colombian cities.
/// Use in event form, filters, or any form that needs a city picker.
class AppCityAutocomplete extends StatelessWidget {
  const AppCityAutocomplete({
    super.key,
    required this.name,
    this.labelText,
    this.hintText,
    this.isRequired = false,
    this.validator,
    this.onSelected,
    this.suffixIcon,
    this.focusNode,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  static const String _defaultLabel = 'Ciudad';
  static const String _defaultHint = 'Buscar ciudad y departamento...';
  static const String _defaultRequiredError = 'La ciudad es requerida';

  final String name;
  final String? labelText;
  final String? hintText;
  final bool isRequired;
  final String? Function(String?)? validator;
  final void Function(String)? onSelected;
  final Widget? suffixIcon;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(String? value)? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    final effectiveValidator = validator ??
        (isRequired
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return _defaultRequiredError;
                }
                return null;
              }
            : null);

    return AppAutocompleteField(
      name: name,
      labelText: labelText ?? _defaultLabel,
      hintText: hintText ?? _defaultHint,
      isRequired: isRequired,
      validator: effectiveValidator,
      onSelected: onSelected,
      suffixIcon: suffixIcon ?? const Icon(Icons.search),
      focusNode: focusNode,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      suggestions: ColombiaCitiesData.search,
      suggestionsPrefixIcon: Icons.location_city_outlined,
    );
  }
}
