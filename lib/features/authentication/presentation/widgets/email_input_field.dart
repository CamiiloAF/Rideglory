import 'package:flutter/material.dart';

/// Custom email input field widget
class EmailInputField extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final VoidCallback? onChanged;
  final bool enabled;
  final TextInputAction? textInputAction;
  final VoidCallback? onFieldSubmitted;
  final FocusNode? focusNode;

  const EmailInputField({
    super.key,
    required this.controller,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.textInputAction,
    this.onFieldSubmitted,
    this.focusNode,
  });

  @override
  State<EmailInputField> createState() => _EmailInputFieldState();
}

class _EmailInputFieldState extends State<EmailInputField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focused) {
        setState(() => _isFocused = focused);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: _isFocused
              ? [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: .2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: TextFormField(
          controller: widget.controller,
          enabled: widget.enabled,
          keyboardType: TextInputType.emailAddress,
          textInputAction: widget.textInputAction ?? TextInputAction.next,
          focusNode: widget.focusNode,
          validator: widget.validator,
          onChanged: (value) {
            widget.onChanged?.call();
          },
          onFieldSubmitted: (value) {
            widget.onFieldSubmitted?.call();
          },
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: 'Ingrese su correo electrónico',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16),
            prefixIcon: Icon(
              Icons.email_rounded,
              color: _isFocused ? const Color(0xFF6366F1) : Colors.grey[400],
              size: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFEF4444),
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            errorStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[900],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
