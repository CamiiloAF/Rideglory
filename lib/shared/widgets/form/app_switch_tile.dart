import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/shared/widgets/form/app_switch.dart';

/// Form switch row: title (+ optional subtitle) on the left, [AppSwitch] on the
/// right. Backed by a [FormBuilderField] bool so it plugs into existing
/// `FormBuilder` forms. The whole row is tappable.
class AppSwitchTile extends StatelessWidget {
  const AppSwitchTile({
    super.key,
    required this.name,
    required this.title,
    this.subtitle,
    this.initialValue = false,
    this.onChanged,
  });

  final String name;
  final String title;
  final String? subtitle;
  final bool initialValue;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<bool>(
      name: name,
      initialValue: initialValue,
      builder: (field) {
        final on = field.value ?? false;
        void toggle() {
          final next = !on;
          field.didChange(next);
          onChanged?.call(next);
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: toggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textOnDarkPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            color: AppColors.textOnDarkSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Display-only: the row's GestureDetector owns the tap.
                AppSwitch(value: on),
              ],
            ),
          ),
        );
      },
    );
  }
}
