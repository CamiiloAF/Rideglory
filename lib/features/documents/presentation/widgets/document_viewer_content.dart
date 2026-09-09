import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../design_system/components/app_banner.dart';
import '../../../../design_system/components/app_secondary_button.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/models/vehicle_document.dart';
import 'document_preview_frame.dart';

/// Contenido del visor con archivo, banner sin conexión si aplica, y las
/// acciones de compartir/reemplazar.
///
/// Pencil: tu2U6, P5GIm
class DocumentViewerContent extends StatelessWidget {
  const DocumentViewerContent({
    required this.bytes,
    required this.isOffline,
    required this.vehicleId,
    required this.kind,
    super.key,
  });

  final Uint8List bytes;
  final bool isOffline;
  final String vehicleId;
  final DocumentKind kind;

  Future<void> _share(BuildContext context) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/${kind.name}-$vehicleId.jpg');
    await file.writeAsBytes(bytes, flush: true);
    if (!context.mounted) return;
    await Share.shareXFiles([XFile(file.path)]);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isOffline) ...[
            AppBanner(
              icon: LucideIcons.wifiOff,
              title: context.l10n.documents_offline_banner_title,
              body: context.l10n.documents_offline_banner_body,
            ),
            const SizedBox(height: 14),
          ],
          Expanded(child: DocumentPreviewFrame(bytes: bytes)),
          const SizedBox(height: 12),
          Text(
            context.l10n.documents_saved_locally_note,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
          ),
          const SizedBox(height: 16),
          AppSecondaryButton(
            label: context.l10n.documents_share_button,
            icon: LucideIcons.share2,
            onPressed: () => _share(context),
          ),
          const SizedBox(height: 10),
          AppSecondaryButton(
            label: context.l10n.documents_replace_button,
            icon: LucideIcons.refreshCw,
            onPressed: () => context.pushNamed(
              AppRoutes.documentUpload,
              pathParameters: {'kind': kind.name},
              extra: vehicleId,
            ),
          ),
        ],
      ),
    );
  }
}
