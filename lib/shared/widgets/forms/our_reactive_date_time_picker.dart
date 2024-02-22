import 'package:flutter/material.dart';
import 'package:reactive_date_time_picker/reactive_date_time_picker.dart';

class OurReactiveDateTimePicker extends StatelessWidget {
  const OurReactiveDateTimePicker({
    required this.formControlName,
    final Key? key,
    this.hintText,
    this.type,
  }) : super(key: key);

  final String formControlName;
  final String? hintText;

  final ReactiveDatePickerFieldType? type;

  @override
  Widget build(final BuildContext context) {
    return ReactiveDateTimePicker(
      formControlName: formControlName,
      type: type ?? ReactiveDatePickerFieldType.date,
      style: const TextStyle(fontSize: 18, color: Colors.black),
      decoration: InputDecoration(
        hintText: hintText,
      ),
    );
  }
}
