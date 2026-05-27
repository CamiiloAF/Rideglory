import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class SignupTermsCheckbox extends StatelessWidget {
  const SignupTermsCheckbox({
    super.key,
    required this.accepted,
    required this.onChanged,
  });

  final bool accepted;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!accepted),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: accepted,
              onChanged: (value) => onChanged(value ?? false),
              activeColor: AppColors.primary,
              side: const BorderSide(color: AppColors.darkBorderPrimary, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.l10n.auth_terms_text,
              style: context.textTheme.bodySmall?.copyWith(
                color: AppColors.textOnDarkSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
