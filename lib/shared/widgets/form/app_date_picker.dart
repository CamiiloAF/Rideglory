import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

class AppDatePicker extends StatelessWidget {
  const AppDatePicker({
    super.key,
    required this.fieldName,
    required this.labelText,
    this.initialValue,
    this.firstDate,
    this.lastDate,
  });

  final String fieldName;
  final String labelText;
  final DateTime? initialValue;
  final DateTime? firstDate;
  final DateTime? lastDate;

  // TODO: Add LABEL
  @override
  Widget build(BuildContext context) {
    return FormBuilderDateTimePicker(
      name: fieldName,
      initialValue: initialValue,
      inputType: InputType.date,
      firstDate: firstDate,
      lastDate: lastDate,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.event),
      ),
    );
  }
}
