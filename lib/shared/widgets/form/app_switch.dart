import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';

/// The single, canonical switch visual for the whole app: a 44x26 pill toggle.
///
/// - ON: accent fill with a **dark** knob (`darkBgPrimary`), per the
///   dark-on-primary rule.
/// - OFF: `darkBgSecondary` fill with a border and a muted knob.
///
/// Pass [onChanged] to make it interactive; pass `null` to render it as a
/// read-only state indicator (e.g. inside a row whose parent handles the tap).
/// Use [AppSwitchTile] for the common title (+ subtitle) + switch row.
class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final on = value;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onChanged == null ? null : () => onChanged!(!on),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 44,
        height: 26,
        padding: const EdgeInsets.all(3),
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(
          color: on ? AppColors.primary : AppColors.darkBgSecondary,
          borderRadius: BorderRadius.circular(13),
          border: on ? null : Border.all(color: AppColors.darkBorderPrimary),
        ),
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on ? AppColors.darkBgPrimary : AppColors.textOnDarkSecondary,
          ),
        ),
      ),
    );
  }
}
