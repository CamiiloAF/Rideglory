import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    super.key,
    required this.name,
    required this.title,
    this.initialValue = false,
  });

  final String name;
  final String title;
  final bool initialValue;

  @override
  Widget build(BuildContext context) {
    return FormBuilderCheckbox(
      name: name,
      title: Text(title),
      initialValue: initialValue,
      decoration: const InputDecoration(border: InputBorder.none),
    );
  }
}
