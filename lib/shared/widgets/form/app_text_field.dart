import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/shared/widgets/form/text_field_label.dart';

class AppTextField extends StatelessWidget {
  final String name;
  final String? labelText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? suffixText;
  final TextStyle? suffixStyle;
  final int? maxLength;
  final String? Function(String?)? validator;
  final String? initialValue;
  final int? maxLines;
  final int? minLines;
  final TextInputType? keyboardType;
  final bool enabled;
  final bool isRequired;
  final String? hintText;
  final String? helperText;
  final void Function(String?)? onChanged;
  final AutovalidateMode? autovalidateMode;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final void Function(String?)? onFieldSubmitted;
  final FocusNode? focusNode;
  final TextCapitalization? textCapitalization;

  const AppTextField({
    super.key,
    required this.name,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.suffixText,
    this.suffixStyle,
    this.maxLength,
    this.validator,
    this.initialValue,
    this.maxLines = 1,
    this.minLines,
    this.keyboardType,
    this.enabled = true,
    this.isRequired = false,
    this.hintText,
    this.helperText,
    this.onChanged,
    this.autovalidateMode,
    this.obscureText = false,
    this.textInputAction,
    this.onFieldSubmitted,
    this.focusNode,
    this.textCapitalization,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null)
          TextFieldLabel(labelText: labelText!, isRequired: isRequired),
        FormBuilderTextField(
          name: name,
          decoration: InputDecoration(
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
            suffixIcon: suffixIcon,
            suffixText: suffixText,
            suffixStyle: suffixStyle,
            hintText: hintText,
            helperText: helperText,
            helperMaxLines: 3,
            counterText: maxLength != null
                ? ''
                : null, // Hide counter when maxLength is set
          ),
          initialValue: initialValue,
          maxLines: maxLines,
          minLines: minLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          enabled: enabled,
          onChanged: onChanged,
          validator: validator != null
              ? FormBuilderValidators.compose([validator!])
              : null,
          autovalidateMode: autovalidateMode,
          obscureText: obscureText,
          textInputAction: textInputAction,
          onSubmitted: onFieldSubmitted,
          focusNode: focusNode,
          textCapitalization:
              textCapitalization ?? TextCapitalization.sentences,
        ),
      ],
    );
  }
}
