import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

/// Full-screen overlay shown when an SOS alert is active (Pencil page 19).
class SosActiveOverlay extends StatelessWidget {
  const SosActiveOverlay({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.errorSubtle.withValues(alpha: 0.92),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pulsing SOS icon
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.error.withValues(alpha: 0.20),
                  border: Border.all(color: AppColors.error, width: 3),
                ),
                child: const Center(
                  child: Text(
                    'SOS',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              AppSpacing.gapXxl,
              Text(
                context.l10n.map_sosAlertTitle,
                style: const TextStyle(
                  color: AppColors.textOnDarkPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              AppSpacing.gapMd,
              Text(
                context.l10n.map_sosAlertMessage,
                style: const TextStyle(
                  color: AppColors.textOnDarkSecondary,
                  fontSize: 14,
                  height: 1.55,
                ),
                textAlign: TextAlign.center,
              ),
              AppSpacing.gapXxl,
              AppSpacing.gapXxl,
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onDismiss,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    context.l10n.map_sosDismiss,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
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
