import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:rideglory/shared/widgets/form/app_text_field_label.dart';

class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.name,
    this.labelText,
    this.validator,
    required this.items,
    this.isRequired = false,
    this.prefixIcon,
  });

  final String name;
  final String? labelText;
  final FormFieldValidator<T>? validator;
  final List<DropdownMenuItem<T>> items;
  final bool isRequired;
  final Widget? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (labelText != null)
          AppTextFieldLabel(labelText: labelText!, isRequired: isRequired),

        FormBuilderDropdown<T>(
          name: name,
          decoration: InputDecoration(
            hintText: labelText,
            border: const OutlineInputBorder(),
            prefixIcon: prefixIcon,
          ),
          validator: validator,
          items: items,
        ),
      ],
    );
  }
}
