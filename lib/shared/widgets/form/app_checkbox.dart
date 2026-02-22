import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    super.key,
    required this.name,
    required this.title,
    this.initialValue,
    this.enabled = true,
    this.customTitle,
    this.onChanged,
  });

  final String name;
  final String title;
  final bool? initialValue;
  final ValueChanged<bool?>? onChanged;
  final bool enabled;
  final Widget? customTitle;

  @override
  Widget build(BuildContext context) {
    return FormBuilderCheckbox(
      name: name,
      title: customTitle ?? Text(title),
      initialValue: initialValue,
      enabled: enabled,
      onChanged: onChanged,
    );
  }
}
