import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/design_system/foundation/theme/app_colors.dart';
import 'package:rideglory/shared/widgets/form/text_field_label.dart';

class AppTextField extends StatefulWidget {
  final String name;
  final String? labelText;
  final IconData? prefixIcon;
  final String? prefixText;
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
  final bool readonly;

  const AppTextField({
    super.key,
    required this.name,
    this.labelText,
    this.prefixIcon,
    this.prefixText,
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
    this.readonly = false,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _isFocused ? AppColors.darkInputIcon : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null)
          TextFieldLabel(
            labelText: widget.labelText!,
            isRequired: widget.isRequired,
          ),
        FormBuilderTextField(
          name: widget.name,
          decoration: InputDecoration(
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, color: iconColor)
                : null,
            prefixText: widget.prefixText,
            suffixIcon: widget.suffixIcon,
            suffixIconColor: iconColor,
            prefixIconColor: iconColor,
            suffixText: widget.suffixText,
            suffixStyle: widget.suffixStyle,
            hintText: widget.hintText,
            helperText: widget.helperText,
            helperMaxLines: 3,
            counterText: widget.maxLength != null ? '' : null,
          ),
          initialValue: widget.initialValue,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          maxLength: widget.maxLength,
          keyboardType: widget.keyboardType,
          enabled: widget.enabled,
          readOnly: widget.readonly,
          onChanged: widget.onChanged,
          validator: widget.validator != null
              ? FormBuilderValidators.compose([widget.validator!])
              : null,
          autovalidateMode: widget.autovalidateMode,
          obscureText: widget.obscureText,
          textInputAction: widget.textInputAction,
          onSubmitted: widget.onFieldSubmitted,
          focusNode: _focusNode,
          textCapitalization:
              widget.textCapitalization ?? TextCapitalization.sentences,
        ),
      ],
    );
  }
}
