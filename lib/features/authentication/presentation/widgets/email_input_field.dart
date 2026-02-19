import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/authentication/constants/auth_strings.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';

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
                    color: AppColors.primaryShadow(opacity: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: AppColors.shadowLight,
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
            hintText: AuthStrings.enterEmail,
            hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 16),
            prefixIcon: Icon(
              Icons.email_rounded,
              color: _isFocused ? context.primaryColor : AppColors.textTertiary,
              size: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.errorColor, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.errorColor, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            errorStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
              color: context.errorColor,
            ),
          ),
          style: context.bodyLarge,
        ),
      ),
    );
  }
}
