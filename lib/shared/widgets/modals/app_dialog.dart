import 'package:flutter/material.dart';

enum DialogType { confirmation, information, warning, success, error }

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

    switch (type) {
      case DialogType.confirmation:
        return const Color(0xFF6366F1);
      case DialogType.information:
        return const Color(0xFF6366F1);
      case DialogType.warning:
        return Colors.orange;
      case DialogType.success:
        return const Color(0xFF10B981);
      case DialogType.error:
        return Colors.red;
    }
  }

  IconData _getIcon() {
    if (customIcon != null) return customIcon!;

    switch (type) {
      case DialogType.confirmation:
        return Icons.info_outline_rounded;
      case DialogType.information:
        return Icons.info_outline_rounded;
      case DialogType.warning:
        return Icons.warning_amber_rounded;
      case DialogType.success:
        return Icons.check_circle_outline_rounded;
      case DialogType.error:
        return Icons.error_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(_getIcon(), color: _getIconColor(), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
      content: Text(
        content,
        style: TextStyle(fontSize: 15, height: 1.5, color: Colors.grey[700]),
      ),
      actions: _buildActions(),
      actionsPadding: const EdgeInsets.all(16),
    );
  }

  List<Widget> _buildActions() {
    if (actions.isEmpty) {
      return [
        ElevatedButton(
          onPressed: () => Navigator.of(_getContext()).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: const Text('Aceptar'),
        ),
      ];
    }

    return actions.map((action) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: action.type == DialogActionType.danger
              ? ElevatedButton(
                  onPressed: action.onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(action.label),
                )
              : action.type == DialogActionType.primary
              ? ElevatedButton(
                  onPressed: action.onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(action.label),
                )
              : OutlinedButton(
                  onPressed: action.onPressed,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(action.label),
                ),
        ),
      );
    }).toList();
  }

  BuildContext _getContext() {
    throw UnimplementedError('Use AppDialogHelper instead');
  }
}

class AppDialogHelper {
  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String content,
    String cancelLabel = 'Cancelar',
    String confirmLabel = 'Confirmar',
    DialogActionType confirmType = DialogActionType.primary,
    DialogType dialogType = DialogType.confirmation,
    bool isDismissible = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: isDismissible,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _getIcon(dialogType),
                          color: _getIconColor(dialogType),
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Content
                    Text(
                      content,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              // Actions
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(cancelLabel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              confirmType == DialogActionType.danger
                              ? Colors.red
                              : const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(confirmLabel),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> showInfo({
    required BuildContext context,
    required String title,
    required String content,
    String buttonLabel = 'Aceptar',
    DialogType type = DialogType.information,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _getIcon(type),
                          color: _getIconColor(type),
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Content
                    Text(
                      content,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              // Action
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(buttonLabel),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _getIcon(DialogType type) {
    switch (type) {
      case DialogType.confirmation:
        return Icons.info_outline_rounded;
      case DialogType.information:
        return Icons.info_outline_rounded;
      case DialogType.warning:
        return Icons.warning_amber_rounded;
      case DialogType.success:
        return Icons.check_circle_outline_rounded;
      case DialogType.error:
        return Icons.error_outline_rounded;
    }
  }

  static Color _getIconColor(DialogType type) {
    switch (type) {
      case DialogType.confirmation:
        return const Color(0xFF6366F1);
      case DialogType.information:
        return const Color(0xFF6366F1);
      case DialogType.warning:
        return Colors.orange;
      case DialogType.success:
        return const Color(0xFF10B981);
      case DialogType.error:
        return Colors.red;
    }
  }
}
