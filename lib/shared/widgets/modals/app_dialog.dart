import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/shared/widgets/modals/app_modal.dart';
import 'package:rideglory/shared/widgets/modals/app_modal_action.dart';
import 'package:rideglory/shared/widgets/modals/dialog_type.dart';

enum DialogActionType { primary, secondary, danger }

class DialogAction {
  final String label;
  final VoidCallback onPressed;
  final DialogActionType type;

  const DialogAction({
    required this.label,
    required this.onPressed,
    this.type = DialogActionType.secondary,
  });
}

/// Generic dialog built on the unified [AppModal] design. Accepts an arbitrary
/// list of [DialogAction]s; falls back to a single "accept" button when empty.
class AppDialog extends StatelessWidget {
  final String title;
  final String content;
  final DialogType type;
  final List<DialogAction> actions;
  final IconData? customIcon;
  final Color? customIconColor;

  const AppDialog({
    super.key,
    required this.title,
    required this.content,
    this.type = DialogType.information,
    required this.actions,
    this.customIcon,
    this.customIconColor,
  });

  AppModalActionEmphasis _emphasisFor(DialogActionType actionType) {
    return switch (actionType) {
      DialogActionType.primary => AppModalActionEmphasis.primary,
      DialogActionType.danger => AppModalActionEmphasis.danger,
      DialogActionType.secondary => AppModalActionEmphasis.neutral,
    };
  }

  @override
  Widget build(BuildContext context) {
    final resolvedActions = actions.isEmpty
        ? [
            AppModalAction(
              label: context.l10n.accept,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ]
        : actions
              .map(
                (action) => AppModalAction(
                  label: action.label,
                  onPressed: action.onPressed,
                  emphasis: _emphasisFor(action.type),
                ),
              )
              .toList();

    return AppModal(
      title: title,
      description: content,
      variant: type.variant,
      icon: customIcon,
      iconColor: customIconColor,
      actions: resolvedActions,
    );
  }
}
