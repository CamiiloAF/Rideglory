import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:rideglory/shared/widgets/form/text_field_label.dart';

class AppDatePicker extends StatelessWidget {
  const AppDatePicker({
    super.key,
    required this.fieldName,
    required this.labelText,
    this.initialValue,
    this.firstDate,
    this.lastDate,
    this.isRequired = false,
    this.hintText,
    this.prefixIcon,
    this.inputType,
    this.enabled = true,
    this.focusNode,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  final String fieldName;
  final String labelText;
  final String? hintText;
  final DateTime? initialValue;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool isRequired;
  final Widget? prefixIcon;
  final InputType? inputType;
  final bool enabled;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(DateTime? value)? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFieldLabel(labelText: labelText, isRequired: isRequired),
        FormBuilderDateTimePicker(
          name: fieldName,
          initialValue: initialValue,
          inputType: inputType ?? InputType.date,
          firstDate: firstDate,
          lastDate: lastDate,
          enabled: enabled,
          focusNode: focusNode,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          decoration: InputDecoration(
            hintText: hintText,
            border: const OutlineInputBorder(),
            prefixIcon: prefixIcon,
          ),
        ),
      ],
    );
  }
}
