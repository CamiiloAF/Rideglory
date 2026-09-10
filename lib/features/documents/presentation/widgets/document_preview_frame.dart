import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_radii.dart';
import '../../../../l10n/l10n_extensions.dart';

/// Vista previa del archivo: la imagen si es foto, o un ícono genérico si
/// es PDF (Flutter no renderiza PDFs sin un plugin adicional).
class DocumentPreviewFrame extends StatelessWidget {
  const DocumentPreviewFrame({required this.bytes, super.key});

  final Uint8List bytes;

  bool get _looksLikeImage {
    if (bytes.length < 4) return false;
    final isJpeg = bytes[0] == 0xFF && bytes[1] == 0xD8;
    final isPng = bytes[0] == 0x89 && bytes[1] == 0x50;
    return isJpeg || isPng;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: _looksLikeImage
          ? Image.memory(bytes, fit: BoxFit.contain)
          : Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.fileText,
                    size: 48,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.documents_pdf_preview_label,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
