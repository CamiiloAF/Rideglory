import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:rideglory/shared/widgets/form/text_field_label.dart';

class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.name,
    this.labelText,
    this.hintText,
    this.validator,
    required this.items,
    this.isRequired = false,
    this.prefixIcon,
    this.onChanged,
    this.focusNode,
  });

  final String name;
  final String? labelText;
  final String? hintText;
  final FormFieldValidator<T>? validator;
  final List<DropdownMenuItem<T>> items;
  final bool isRequired;
  final Widget? prefixIcon;
  final ValueChanged<T?>? onChanged;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null)
          TextFieldLabel(
            labelText: labelText!,
            isRequired: isRequired,
          ),
        FormBuilderDropdown<T>(
          name: name,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: hintText,
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
