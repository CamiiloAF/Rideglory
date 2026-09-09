import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radii.dart';

/// Campo de formulario único de la app: label, caja con icono opcional,
/// texto de ayuda y error accionable.
///
/// Nunca uses `TextField`/`FormBuilderTextField` crudo si necesitas un
/// campo de texto: usa este.
///
/// Pencil: bsWHG
class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.label,
    this.controller,
    this.icon,
    this.suffixText,
    this.helperText,
    this.errorText,
    this.keyboardType,
    this.inputFormatters,
    this.obscureText = false,
    this.enabled = true,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.onSuffixTap,
    this.trailingIcon,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final IconData? icon;
  final String? suffixText;
  final String? helperText;
  final String? errorText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final VoidCallback? onSuffixTap;

  /// Ícono al final de la caja (ej. `chevron-down` en un campo que abre un
  /// selector, como fecha). No reemplaza [suffixText]: pueden combinarse.
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final hasError = errorText != null && errorText!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 7),
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadii.sm),
            border: Border.all(
              color: hasError ? colors.errorText : colors.borderStrong,
            ),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 19, color: colors.textSecondary),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  readOnly: readOnly,
                  onTap: onTap,
                  onChanged: onChanged,
                  obscureText: obscureText,
                  keyboardType: keyboardType,
                  inputFormatters: inputFormatters,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.text,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (suffixText != null) ...[
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: onSuffixTap,
                  child: Text(
                    suffixText!,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
              if (trailingIcon != null) ...[
                const SizedBox(width: 8),
                Icon(trailingIcon, size: 18, color: colors.textSecondary),
              ],
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.errorText,
            ),
          ),
        ] else if (helperText != null) ...[
          const SizedBox(height: 6),
          Text(
            helperText!,
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
        ],
      ],
    );
  }
}
