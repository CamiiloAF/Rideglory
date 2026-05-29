import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/shared/widgets/modals/app_modal_action_button.dart';
import 'package:rideglory/shared/widgets/modals/app_modal_icon_circle.dart';

export 'package:rideglory/shared/widgets/modals/app_modal_variant.dart';

/// Centered dialog modal that implements the Pencil `Component/Modal` design
/// (node `VVrFh`) and its four semantic variants (node `ibKDx`).
///
/// Structure (top to bottom):
/// - optional glowing icon circle ([AppModalIconCircle]),
/// - centered title,
/// - optional centered description and/or a custom [child] body,
/// - a vertical stack of pill action buttons.
///
/// The [variant] drives the default icon, icon color, icon circle fill + glow,
/// primary button fill and primary label color. An explicit [icon] / [iconColor]
/// overrides the variant defaults. Use [AppModal.show] to present it over the
/// standard dark scrim. Behavior (callbacks, validation, navigation) lives in
/// the caller's [actions] — this widget only owns presentation.
class AppModal extends StatelessWidget {
  /// Internal gap between the title and the description / between stacked
  /// action buttons. The Pencil spec uses 10 px here (between the standard
  /// 8 px and 12 px tokens), so it is expressed as a literal [SizedBox].
  static const Widget _innerGap = SizedBox(height: 10);

  final String title;
  final String? description;
  final Widget? child;
  final IconData? icon;
  final Color? iconColor;
  final List<AppModalAction> actions;
  final AppModalVariant variant;

  const AppModal({
    super.key,
    required this.title,
    this.description,
    this.child,
    this.icon,
    this.iconColor,
    this.actions = const [],
    this.variant = AppModalVariant.info,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final resolvedIcon = icon ?? variant.icon;
    final resolvedIconColor = iconColor ?? variant.accentColor;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: cs.outline),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55000000),
              blurRadius: 60,
              offset: Offset(0, 20),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppModalIconCircle(
                  icon: resolvedIcon,
                  iconColor: resolvedIconColor,
                  circleFill: variant.circleFill,
                  glowColor: variant.glowColor,
                  glowBlur: variant.glowBlur,
                  glowSpread: variant.glowSpread,
                ),
                AppSpacing.gapXl,
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: context.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (description != null) ...[
                  _innerGap,
                  Text(
                    description!,
                    textAlign: TextAlign.center,
                    style: context.bodyMedium?.copyWith(height: 1.5),
                  ),
                ],
                if (child != null) ...[AppSpacing.gapLg, child!],
                if (actions.isNotEmpty) ...[
                  AppSpacing.gapXl,
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var index = 0; index < actions.length; index++) ...[
                        if (index > 0) _innerGap,
                        AppModalActionButton(
                          action: actions[index],
                          primaryFill: _primaryFill(actions[index]),
                          primaryLabelColor: _primaryLabelColor(actions[index]),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Fill of an affirmative action: a [AppModalActionEmphasis.danger] action is
  /// always destructive-red; otherwise it follows the [variant] accent.
  Color _primaryFill(AppModalAction action) =>
      action.emphasis == AppModalActionEmphasis.danger
      ? AppColors.error
      : variant.accentColor;

  /// Label color of an affirmative action: white on the destructive-red fill,
  /// otherwise the [variant]'s primary label color.
  Color _primaryLabelColor(AppModalAction action) =>
      action.emphasis == AppModalActionEmphasis.danger
      ? AppColors.textOnDarkPrimary
      : variant.primaryLabelColor;

  /// Presents [AppModal] over the standard dark scrim and returns the value the
  /// dialog is popped with.
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? description,
    Widget? child,
    IconData? icon,
    Color? iconColor,
    List<AppModalAction> actions = const [],
    AppModalVariant variant = AppModalVariant.info,
    bool barrierDismissible = false,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: AppColors.darkBgPrimary.withValues(alpha: 0.82),
      builder: (_) => AppModal(
        title: title,
        description: description,
        icon: icon,
        iconColor: iconColor,
        actions: actions,
        variant: variant,
        child: child,
      ),
    );
  }
}
