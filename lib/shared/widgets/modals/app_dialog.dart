import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/shared/widgets/form/app_button.dart';
import 'package:rideglory/shared/widgets/modals/dialog_type.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

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

class AppDialog extends StatelessWidget {
  final String title;
  final String content;
  final DialogType type;
  final List<DialogAction> actions;
  final IconData? customIcon;
  final Color? customIconColor;
  final bool isDismissible;

  const AppDialog({
    super.key,
    required this.title,
    required this.content,
    this.type = DialogType.information,
    required this.actions,
    this.customIcon,
    this.customIconColor,
    this.isDismissible = false,
  });

  Color _getIconColor() {
    if (customIconColor != null) return customIconColor!;
    return type.color;
  }

  IconData _getIcon() {
    if (customIcon != null) return customIcon!;
    return type.icon;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(_getIcon(), color: _getIconColor(), size: 28),
          AppSpacing.hGapMd,
          Expanded(
            child: Text(
              title,
              style: context.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Text(content, style: context.bodyMedium?.copyWith(height: 1.5)),
      actions: _buildActions(context),
      actionsPadding: const EdgeInsets.all(16),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    if (actions.isEmpty) {
      return [
        AppButton(
          label: context.l10n.accept,
          onPressed: () => Navigator.of(_getContext()).pop(),
          variant: AppButtonVariant.primary,
          isFullWidth: false,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ];
    }

    return actions.map((action) {
      final isPrimary = action.type == DialogActionType.primary;
      final isDanger = action.type == DialogActionType.danger;
      final variant = isDanger
          ? AppButtonVariant.danger
          : AppButtonVariant.primary;
      final style = isPrimary || isDanger
          ? AppButtonStyle.filled
          : AppButtonStyle.outlined;

      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: AppButton(
            label: action.label,
            onPressed: action.onPressed,
            variant: variant,
            style: style,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      );
    }).toList();
  }

  BuildContext _getContext() {
    throw UnimplementedError('Use ConfirmationDialog or InfoDialog instead');
  }
}
