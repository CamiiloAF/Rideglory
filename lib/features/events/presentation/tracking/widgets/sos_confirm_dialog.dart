import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

/// SOS confirmation bottom sheet / dialog (Pencil page 20).
class SosConfirmDialog {
  static Future<bool?> show({required BuildContext context}) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _SosConfirmSheet(sheetContext: sheetContext),
    );
  }
}

class _SosConfirmSheet extends StatelessWidget {
  const _SosConfirmSheet({required this.sheetContext});

  final BuildContext sheetContext;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.darkBorderPrimary),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.darkBorderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              AppSpacing.gapXxl,
              // SOS icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.errorSubtle,
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.6),
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Text(
                    'SOS',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              AppSpacing.gapLg,
              Text(
                context.l10n.map_sosConfirmTitle,
                style: const TextStyle(
                  color: AppColors.textOnDarkPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              AppSpacing.gapMd,
              Text(
                context.l10n.map_sosConfirmMessage,
                style: const TextStyle(
                  color: AppColors.textOnDarkSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              AppSpacing.gapXxl,
              // Send SOS button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    context.l10n.map_sosSend,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              AppSpacing.gapMd,
              // Cancel button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop(false),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textOnDarkSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    context.l10n.cancel,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
