import 'package:flutter/material.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/shared/widgets/form/app_text_field.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

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
    this.onChanged,
  });

  final String name;
  final String labelText;
  final int? initialValue;
  final bool isRequired;
  final List<String? Function(String?)>? validators;
  final String? hintText;
  final TextInputAction textInputAction;
  final AutovalidateMode? autovalidateMode;
  final void Function(String?)? onChanged;

  /// Default validators for required current mileage (required, numeric, min 0).
  static List<String? Function(String?)> defaultCurrentMileageValidators(
    BuildContext context,
  ) => [
    FormBuilderValidators.required(
      errorText: context.l10n.appfields_mileageRequired,
    ),
    FormBuilderValidators.numeric(errorText: context.l10n.mustBeNumber),
    FormBuilderValidators.min(0, errorText: context.l10n.mustBeGreaterThanZero),
  ];

  @override
  Widget build(BuildContext context) {
    final effectiveValidators =
        validators ??
        (isRequired
            ? defaultCurrentMileageValidators(context)
            : <String? Function(String?)>[]);

    return AppTextField(
      name: name,
      labelText: labelText,
      isRequired: isRequired,
      initialValue: initialValue?.toString(),
      hintText: hintText ?? labelText,
      suffixIcon: const Padding(
        padding: EdgeInsets.only(right: 14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'km',
              style: TextStyle(
                color: AppColors.textOnDarkTertiary,
                fontSize: 13,
              ),
            ),
            SizedBox(width: 6),
            ColoredBox(
              color: AppColors.darkBorderPrimary,
              child: SizedBox(width: 1, height: 18),
            ),
            SizedBox(width: 6),
            Icon(Icons.speed, size: 15, color: AppColors.primary),
          ],
        ),
      ),
      onChanged: onChanged,
      keyboardType: TextInputType.number,
      textInputAction: textInputAction,
      autovalidateMode: autovalidateMode,
      validator: effectiveValidators.isEmpty
          ? null
          : FormBuilderValidators.compose(effectiveValidators),
    );
  }
}
