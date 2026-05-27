import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/shared/helpers/document_downloader.dart';

/// Sección superior del formulario de SOAT que gestiona el documento adjunto.
///
/// Muestra uno de tres estados:
/// - **Archivo local seleccionado** (`localImagePath != null`): thumbnail o
///   card PDF con opciones para cambiar o eliminar.
/// - **Documento remoto existente** (`remoteDocumentUrl != null`): preview
///   tappable que abre el archivo con la app predeterminada del SO (con caché).
/// - **Sin documento**: slot vacío que invita a agregar un archivo.
class SoatDocumentSection extends StatelessWidget {
  const SoatDocumentSection({
    super.key,
    required this.localImagePath,
    required this.remoteDocumentUrl,
    required this.onPickImage,
    required this.onRemoveLocalImage,
  });

  final String? localImagePath;
  final String? remoteDocumentUrl;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveLocalImage;

  @override
  Widget build(BuildContext context) {
    // --- 1. Archivo local recién seleccionado ---
    if (localImagePath != null) {
      final isPdf = localImagePath!.toLowerCase().endsWith('.pdf');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isPdf)
            _LocalPdfPreview(path: localImagePath!)
          else
            _LocalImagePreview(path: localImagePath!),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppTextButton(
                label: context.l10n.soat_doc_change,
                onPressed: onPickImage,
              ),
              const SizedBox(width: 16),
              AppTextButton(
                label: context.l10n.delete,
                variant: AppTextButtonVariant.danger,
                onPressed: onRemoveLocalImage,
              ),
            ],
          ),
        ],
      );
    }

    // --- 2. Documento remoto existente ---
    if (remoteDocumentUrl != null) {
      final isPdf = DocumentDownloader.isPdfUrl(remoteDocumentUrl!);
      final fileName = DocumentDownloader.fileNameFromUrl(remoteDocumentUrl!);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isPdf)
            _RemotePdfPreview(url: remoteDocumentUrl!, fileName: fileName)
          else
            _RemoteImagePreview(url: remoteDocumentUrl!, fileName: fileName),
          const SizedBox(height: 8),
          Center(
            child: AppTextButton(
              label: context.l10n.soat_doc_replace,
              onPressed: onPickImage,
              variant: AppTextButtonVariant.muted,
            ),
          ),
        ],
      );
    }

    // --- 3. Sin documento ---
    return GestureDetector(
      onTap: onPickImage,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.darkBorderLight),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.darkTertiary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.add_photo_alternate_outlined,
                size: 20,
                color: AppColors.textOnDarkSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.soat_doc_add_label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textOnDarkPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.soat_doc_add_hint,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textOnDarkTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.textOnDarkTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Vistas de archivo local ───────────────────────────────────────────────────

class _LocalImagePreview extends StatelessWidget {
  const _LocalImagePreview({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 160,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(File(path), fit: BoxFit.cover),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocalPdfPreview extends StatelessWidget {
  const _LocalPdfPreview({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.picture_as_pdf_outlined,
            size: 36,
            color: AppColors.info,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              path.split('/').last,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textOnDarkPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Vistas de documento remoto ────────────────────────────────────────────────

class _RemoteImagePreview extends StatefulWidget {
  const _RemoteImagePreview({required this.url, required this.fileName});

  final String url;
  final String fileName;

  @override
  State<_RemoteImagePreview> createState() => _RemoteImagePreviewState();
}

class _RemoteImagePreviewState extends State<_RemoteImagePreview> {
  bool _loading = false;

  Future<void> _open() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await DocumentDownloader.openRemote(widget.url, widget.fileName);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _loading ? null : _open,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 160,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                widget.url,
                fit: BoxFit.cover,
                loadingBuilder: (ctx, child, progress) => progress == null
                    ? child
                    : Container(
                        color: AppColors.darkCard,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                errorBuilder: (ctx, error, stack) => Container(
                  color: AppColors.darkCard,
                  child: const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 36,
                      color: AppColors.textOnDarkTertiary,
                    ),
                  ),
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.center,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                  ),
                ),
              ),
              if (_loading)
                const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              else
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      context.l10n.soat_doc_tap_to_open,
                      style: const TextStyle(
                        color: AppColors.textOnDarkSecondary,
                        fontSize: 12,
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

class _RemotePdfPreview extends StatefulWidget {
  const _RemotePdfPreview({required this.url, required this.fileName});

  final String url;
  final String fileName;

  @override
  State<_RemotePdfPreview> createState() => _RemotePdfPreviewState();
}

class _RemotePdfPreviewState extends State<_RemotePdfPreview> {
  bool _loading = false;

  Future<void> _open() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await DocumentDownloader.openRemote(widget.url, widget.fileName);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _loading ? null : _open,
      child: Container(
        height: 100,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.info.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.picture_as_pdf_outlined,
              size: 36,
              color: AppColors.info,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.fileName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textOnDarkPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (_loading)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: AppColors.info,
                      ),
                    )
                  else
                    Text(
                      context.l10n.soat_doc_tap_to_open,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textOnDarkTertiary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
