import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:rideglory/shared/widgets/form/app_text_field_label.dart';

class AppDatePicker extends StatelessWidget {
  const AppDatePicker({
    super.key,
    required this.fieldName,
    required this.labelText,
    this.initialValue,
    this.firstDate,
    this.lastDate,
    this.isRequired = false,
    this.hint,
    this.prefixIcon,
  });

  final String fieldName;
  final String labelText;
  final String? hint;
  final DateTime? initialValue;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool isRequired;
  final Widget? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        AppTextFieldLabel(labelText: labelText, isRequired: isRequired),
        FormBuilderDateTimePicker(
          name: fieldName,
          initialValue: initialValue,
          inputType: InputType.date,
          firstDate: firstDate,
          lastDate: lastDate,
          decoration: InputDecoration(
            hintText: hint ?? labelText,
            border: const OutlineInputBorder(),
            prefixIcon: prefixIcon ?? const Icon(Icons.event),
          ),
        ),
      ],
    );
  }
}
