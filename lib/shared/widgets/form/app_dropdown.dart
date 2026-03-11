import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:rideglory/shared/widgets/form/text_field_label.dart';

class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.name,
    this.labelText,
    this.validator,
    required this.items,
    this.isRequired = false,
    this.prefixIcon,
    this.onChanged,
  });

  final String name;
  final String? labelText;
  final FormFieldValidator<T>? validator;
  final List<DropdownMenuItem<T>> items;
  final bool isRequired;
  final Widget? prefixIcon;
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: TextFieldLabel(
              labelText: labelText!,
              isRequired: isRequired,
            ),
          ),
        FormBuilderDropdown<T>(
          name: name,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            prefixIcon: prefixIcon,
          ),
          validator: validator,
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
