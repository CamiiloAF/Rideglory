import 'package:flutter/material.dart';
import 'package:rideglory/shared/widgets/form/app_text_field.dart';

/// Password text field widget with toggle visibility functionality
class AppPasswordTextField extends StatefulWidget {
  final String name;
  final String? labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final void Function(String?)? onFieldSubmitted;
  final bool enabled;
  final bool isRequired;
  final AutovalidateMode? autovalidateMode;
  final FocusNode? focusNode;

  const AppPasswordTextField({
    super.key,
    required this.name,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
    this.enabled = true,
    this.isRequired = false,
    this.autovalidateMode,
    this.focusNode,
  });

  @override
  State<AppPasswordTextField> createState() => _AppPasswordTextFieldState();
}

class _AppPasswordTextFieldState extends State<AppPasswordTextField> {
  bool _isObscured = true;

  void _togglePasswordVisibility() {
    setState(() {
      _isObscured = !_isObscured;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      name: widget.name,
      labelText: widget.labelText,
      hintText: widget.hintText,
      prefixIcon: widget.prefixIcon ?? Icons.lock_rounded,
      suffixIcon: IconButton(
        icon: Icon(
          _isObscured ? Icons.visibility_off : Icons.visibility,
          size: 20,
        ),
        onPressed: _togglePasswordVisibility,
      ),
      obscureText: _isObscured,
      validator: widget.validator,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      enabled: widget.enabled,
      isRequired: widget.isRequired,
      autovalidateMode: widget.autovalidateMode,
      focusNode: widget.focusNode,
    );
  }
}
