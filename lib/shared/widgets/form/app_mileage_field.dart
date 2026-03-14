import 'package:flutter/material.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/core/constants/app_strings.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/shared/widgets/form/app_text_field.dart';


class AppMileageField extends StatelessWidget {
  const AppMileageField({
    super.key,
    required this.name,
    required this.labelText,
    this.initialValue,
    this.isRequired = true,
    this.validators,
    this.hintText,
    this.textInputAction = TextInputAction.next,
    this.autovalidateMode,
  });

  final String name;
  final String labelText;
  final int? initialValue;
  final bool isRequired;
  final List<String? Function(String?)>? validators;
  final String? hintText;
  final TextInputAction textInputAction;
  final AutovalidateMode? autovalidateMode;

  /// Default validators for required current mileage (required, numeric, min 0).
  static List<String? Function(String?)> defaultCurrentMileageValidators() =>
      [
        FormBuilderValidators.required(errorText: AppStrings.required),
        FormBuilderValidators.numeric(errorText: AppStrings.mustBeNumber),
        FormBuilderValidators.min(
          0,
          errorText: AppStrings.mustBeGreaterThanZero,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final effectiveValidators = validators ??
        (isRequired ? defaultCurrentMileageValidators() : <String? Function(String?)>[]);

    return AppTextField(
      name: name,
      labelText: labelText,
      isRequired: isRequired,
      initialValue: initialValue?.toString(),
      hintText: hintText ?? labelText,
      prefixIcon: Icons.speed,
      suffixText: 'KM',
      suffixStyle: context.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: context.colorScheme.onSurfaceVariant,
      ),
      keyboardType: TextInputType.number,
      textInputAction: textInputAction,
      autovalidateMode: autovalidateMode,
      validator: effectiveValidators.isEmpty
          ? null
          : FormBuilderValidators.compose(effectiveValidators),
    );
  }
}
