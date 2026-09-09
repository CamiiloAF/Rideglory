import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../design_system/components/app_primary_button.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/models/vehicle_document.dart';

/// Documento sin subir todavía: invita a subirlo.
///
/// Pencil: dB4Au
class DocumentNotUploadedView extends StatelessWidget {
  const DocumentNotUploadedView({required this.vehicleId, required this.kind, super.key});

  final String vehicleId;
  final DocumentKind kind;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final kindLabel =
        kind == DocumentKind.soat ? context.l10n.documents_soat_title : context.l10n.documents_rtm_title;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.filePlus2, size: 44, color: colors.textSecondary),
            const SizedBox(height: 16),
            Text(
              context.l10n.documents_not_uploaded_title(kindLabel),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: colors.text),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.documents_not_uploaded_body,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
            const SizedBox(height: 24),
            AppPrimaryButton(
              label: context.l10n.documents_upload_button(kindLabel),
              icon: LucideIcons.upload,
              onPressed: () => context.pushNamed(
                AppRoutes.documentUpload,
                pathParameters: {'kind': kind.name},
                extra: vehicleId,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              context.l10n.documents_privacy_note,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
