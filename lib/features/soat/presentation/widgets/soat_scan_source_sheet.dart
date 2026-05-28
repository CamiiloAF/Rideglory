import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/soat/domain/models/soat_scan_result.dart';

/// Bottom sheet that lets the user pick where to scan the SOAT document from.
///
/// Returns the chosen [SoatScanSource] via `Navigator.pop`, or `null` if
/// dismissed.
class SoatScanSourceSheet extends StatelessWidget {
  const SoatScanSourceSheet({super.key});

  static Future<SoatScanSource?> show(BuildContext context) {
    return showModalBottomSheet<SoatScanSource>(
      context: context,
      backgroundColor: AppColors.darkBgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const SoatScanSourceSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.darkBorderPrimary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              context.l10n.soat_scan_sheet_title,
              style: const TextStyle(
                color: AppColors.textOnDarkPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            AppButton(
              label: context.l10n.soat_source_camera,
              icon: Icons.camera_alt_outlined,
              // Custom: typed-result pop is required for showModalBottomSheet.
              onPressed: () => context.pop(SoatScanSource.camera),
              variant: AppButtonVariant.secondary,
              style: AppButtonStyle.outlined,
            ),
            const SizedBox(height: 12),
            AppButton(
              label: context.l10n.soat_source_gallery,
              icon: Icons.photo_library_outlined,
              // Custom: typed-result pop is required for showModalBottomSheet.
              onPressed: () => context.pop(SoatScanSource.gallery),
              variant: AppButtonVariant.secondary,
              style: AppButtonStyle.outlined,
            ),
            const SizedBox(height: 12),
            AppButton(
              label: context.l10n.soat_source_pdf,
              icon: Icons.picture_as_pdf_outlined,
              // Custom: typed-result pop is required for showModalBottomSheet.
              onPressed: () => context.pop(SoatScanSource.pdf),
              variant: AppButtonVariant.secondary,
              style: AppButtonStyle.outlined,
            ),
          ],
        ),
      ),
    );
  }
}
