import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    super.key,
    required this.name,
    required this.title,
    this.initialValue = false,
    this.enabled = true,
  });

  final String name;
  final String title;
  final bool initialValue;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return FormBuilderCheckbox(
      name: name,
      title: Text(title),
      initialValue: initialValue,
      enabled: enabled,
      decoration: const InputDecoration(border: InputBorder.none),
    );
  }
}
