import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class InfoDialog {
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String content,
    String? buttonLabel,
    DialogType type = DialogType.information,
  }) {
    final resolvedButtonLabel = buttonLabel ?? context.l10n.accept;
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
                        Icon(type.icon, color: type.color, size: 28),
                        AppSpacing.hGapMd,
                        Expanded(
                          child: Text(
                            title,
                            style: dialogContext.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.gapLg,
                    // Content
                    Text(
                      content,
                      style: dialogContext.bodyMedium?.copyWith(height: 1.5),
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
                child: AppButton(
                  label: resolvedButtonLabel,
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  variant: AppButtonVariant.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
