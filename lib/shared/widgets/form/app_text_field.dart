import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

class AppTextField extends StatelessWidget {
  final String name;
  final String labelText;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;
  final String? initialValue;
  final int? maxLines;
  final TextInputType? keyboardType;
  final bool enabled;
  final bool isRequired;
  final String? hintText;
  final void Function(String?)? onChanged;

  const AppTextField({
    super.key,
    required this.name,
    required this.labelText,
    this.prefixIcon,
    this.validator,
    this.initialValue,
    this.maxLines = 1,
    this.keyboardType,
    this.enabled = true,
    this.isRequired = false,
    this.hintText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              labelText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEF4444),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        FormBuilderTextField(
          name: name,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
            hintText: hintText ?? labelText,
          ),
          initialValue: initialValue,
          maxLines: maxLines,
          keyboardType: keyboardType,
          enabled: enabled,
          onChanged: onChanged,
          validator: validator != null
              ? FormBuilderValidators.compose([validator!])
              : null,
        ),
      ],
    );
  }
}
