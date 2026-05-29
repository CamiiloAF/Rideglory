import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

/// Renders a single [AppModalAction] following the Pencil modal design:
/// pill-shaped (radius 24), 50px tall, full width.
///
/// The primary/danger (affirmative) action is rendered directly here so the
/// exact per-variant [primaryFill] and [primaryLabelColor] from the Pencil
/// spec can be honored (e.g. near-black `#0D0D0F` label on the bright info /
/// warning / success fills, white label only on destructive). The neutral
/// action is a filled tertiary-surface button with a subtle border.
class AppModalActionButton extends StatelessWidget {
  final AppModalAction action;

  /// Fill color of the affirmative button (ignored for neutral actions).
  final Color primaryFill;

  /// Label color of the affirmative button (ignored for neutral actions).
  final Color primaryLabelColor;

  const AppModalActionButton({
    super.key,
    required this.action,
    required this.primaryFill,
    required this.primaryLabelColor,
  });

  @override
  Widget build(BuildContext context) {
    const double buttonHeight = 50;
    const double radius = 24;
    final cs = context.colorScheme;

    final isNeutral = action.emphasis == AppModalActionEmphasis.neutral;
    final fill = isNeutral ? AppColors.darkTertiary : primaryFill;
    final labelColor = isNeutral ? cs.onSurface : primaryLabelColor;
    final fontWeight = isNeutral ? FontWeight.w600 : FontWeight.w700;

    return SizedBox(
      height: buttonHeight,
      width: double.infinity,
      child: Material(
        color: fill,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: action.isLoading ? null : action.onPressed,
          borderRadius: BorderRadius.circular(radius),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: isNeutral ? Border.all(color: cs.outline) : null,
            ),
            alignment: Alignment.center,
            child: action.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: AppLoadingIndicator(
                      variant: AppLoadingIndicatorVariant.inline,
                      color: labelColor,
                    ),
                  )
                : Text(
                    action.label,
                    style: context.labelLarge?.copyWith(
                      color: labelColor,
                      fontSize: 15,
                      fontWeight: fontWeight,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
