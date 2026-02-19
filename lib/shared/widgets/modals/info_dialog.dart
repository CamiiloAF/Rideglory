import 'package:flutter/material.dart';
import 'package:rideglory/core/constants/app_strings.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/shared/widgets/form/app_button.dart';
import 'package:rideglory/shared/widgets/modals/dialog_type.dart';

class InfoDialog {
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String content,
    String buttonLabel = AppStrings.accept,
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
                        Icon(type.icon, color: type.color, size: 28),
                        const SizedBox(width: 12),
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
                    const SizedBox(height: 16),
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
                  label: buttonLabel,
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
