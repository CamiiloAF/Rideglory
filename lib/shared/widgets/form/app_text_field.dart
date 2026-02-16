import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/shared/widgets/form/app_text_field_label.dart';

class AppTextField extends StatelessWidget {
  final String name;
  final String? labelText;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;
  final String? initialValue;
  final int? maxLines;
  final int? minLines;
  final TextInputType? keyboardType;
  final bool enabled;
  final bool isRequired;
  final String? hintText;
  final void Function(String?)? onChanged;
  final AutovalidateMode? autovalidateMode;

  const AppTextField({
    super.key,
    required this.name,
    this.labelText,
    this.prefixIcon,
    this.validator,
    this.initialValue,
    this.maxLines = 1,
    this.minLines,
    this.keyboardType,
    this.enabled = true,
    this.isRequired = false,
    this.hintText,
    this.onChanged,
    this.autovalidateMode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null)
          AppTextFieldLabel(labelText: labelText!, isRequired: isRequired),

        FormBuilderTextField(
          name: name,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
            hintText: hintText ?? labelText,
          ),
          initialValue: initialValue,
          maxLines: maxLines,
          minLines: minLines,
          keyboardType: keyboardType,
          enabled: enabled,
          onChanged: onChanged,
          validator: validator != null
              ? FormBuilderValidators.compose([validator!])
              : null,
          autovalidateMode: autovalidateMode,
        ),
      ],
    );
  }
}
