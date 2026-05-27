import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

/// End-ride confirmation bottom sheet (Pencil page 21).
class EndRideConfirmDialog {
  static Future<bool?> show({required BuildContext context}) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) =>
          _EndRideConfirmSheet(sheetContext: sheetContext),
    );
  }
}

class _EndRideConfirmSheet extends StatelessWidget {
  const _EndRideConfirmSheet({required this.sheetContext});

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
              // Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primarySubtle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.flag_rounded,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),
              AppSpacing.gapLg,
              Text(
                context.l10n.map_endRideConfirmTitle,
                style: const TextStyle(
                  color: AppColors.textOnDarkPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              AppSpacing.gapMd,
              Text(
                context.l10n.map_endRideConfirmMessage,
                style: const TextStyle(
                  color: AppColors.textOnDarkSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              AppSpacing.gapXxl,
              // Confirm button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.darkBgPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    context.l10n.map_endRideConfirmButton,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              AppSpacing.gapMd,
              // Cancel button
              AppTextButton(
                label: context.l10n.cancel,
                onPressed: () => Navigator.of(sheetContext).pop(false),
                variant: AppTextButtonVariant.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
