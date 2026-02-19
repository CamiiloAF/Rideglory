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
  });

  final String fieldName;
  final String labelText;
  final String? hintText;
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
        FormBuilderDateTimePicker(
          name: fieldName,
          initialValue: initialValue,
          inputType: InputType.date,
          firstDate: firstDate,
          lastDate: lastDate,
          decoration: InputDecoration(
            hintText: hintText,
            label: TextFieldLabel(labelText: labelText, isRequired: isRequired),
            border: const OutlineInputBorder(),
            prefixIcon: prefixIcon ?? const Icon(Icons.event),
          ),
        ),
      ],
    );
  }
}
