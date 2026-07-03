import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/shared/helpers/document_downloader.dart';

/// Sección superior del formulario de SOAT que gestiona el documento adjunto.
///
/// Muestra uno de tres estados, todos con el mismo lenguaje visual (card
/// `darkCard` + borde `darkBorderPrimary` + radio 16):
/// - **Archivo local seleccionado** (`localImagePath != null`): preview +
///   footer con acciones Cambiar / Eliminar.
/// - **Documento remoto existente** (`remoteDocumentUrl != null`): preview
///   tappable que abre el archivo, con acción Reemplazar.
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
    if (localImagePath != null) {
      return _LocalDocumentCard(
        path: localImagePath!,
        onChange: onPickImage,
        onRemove: onRemoveLocalImage,
      );
    }
    if (remoteDocumentUrl != null) {
      return _RemoteDocumentCard(
        url: remoteDocumentUrl!,
        onReplace: onPickImage,
      );
    }
    return _EmptyDocumentSlot(onTap: onPickImage);
  }
}

// ── Card base ─────────────────────────────────────────────────────────────────

/// Contenedor común del documento adjunto: preview opcional arriba y footer con
/// metadatos + acciones, todo dentro de una card coherente con la app.
class _DocumentCard extends StatelessWidget {
  const _DocumentCard({this.preview, required this.footer});

  final Widget? preview;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [?preview, footer],
      ),
    );
  }
}

class _DocumentFooter extends StatelessWidget {
  const _DocumentFooter({
    required this.isPdf,
    required this.title,
    required this.subtitle,
    required this.actions,
  });

  final bool isPdf;
  final String title;
  final String subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primarySubtle,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textOnDarkPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textOnDarkTertiary,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ...actions,
        ],
      ),
    );
  }
}

class _DocIconAction extends StatelessWidget {
  const _DocIconAction({
    required this.icon,
    required this.color,
    required this.onTap,
    this.loading = false,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.darkTertiary,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.darkBorderPrimary),
          ),
          child: loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              : Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Stack(
        fit: StackFit.expand,
        children: [
          child,
          // Borde inferior sutil para separar el preview del footer.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0x661E1E24)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Archivo local recién seleccionado ──────────────────────────────────────────

class _LocalDocumentCard extends StatelessWidget {
  const _LocalDocumentCard({
    required this.path,
    required this.onChange,
    required this.onRemove,
  });

  final String path;
  final VoidCallback onChange;
  final VoidCallback onRemove;

  bool get _isPdf => path.toLowerCase().endsWith('.pdf');

  @override
  Widget build(BuildContext context) {
    return _DocumentCard(
      preview: _isPdf
          ? null
          : _ImagePreview(child: Image.file(File(path), fit: BoxFit.cover)),
      footer: _DocumentFooter(
        isPdf: _isPdf,
        title: context.l10n.soat_doc_attached_title,
        subtitle: path.split('/').last,
        actions: [
          _DocIconAction(
            icon: Icons.swap_horiz_rounded,
            color: AppColors.primary,
            onTap: onChange,
          ),
          const SizedBox(width: 8),
          _DocIconAction(
            icon: Icons.delete_outline_rounded,
            color: AppColors.error,
            onTap: onRemove,
          ),
        ],
      ),
    );
  }
}

// ── Documento remoto existente ──────────────────────────────────────────────────

class _RemoteDocumentCard extends StatefulWidget {
  const _RemoteDocumentCard({required this.url, required this.onReplace});

  final String url;
  final VoidCallback onReplace;

  @override
  State<_RemoteDocumentCard> createState() => _RemoteDocumentCardState();
}

class _RemoteDocumentCardState extends State<_RemoteDocumentCard> {
  bool _loading = false;

  bool get _isPdf => DocumentDownloader.isPdfUrl(widget.url);
  String get _fileName => DocumentDownloader.fileNameFromUrl(widget.url);

  Future<void> _open() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await DocumentDownloader.openRemote(widget.url, _fileName);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _DocumentCard(
      preview: _isPdf
          ? null
          : GestureDetector(
              onTap: _loading ? null : _open,
              child: _ImagePreview(
                child: Image.network(
                  widget.url,
                  fit: BoxFit.cover,
                  loadingBuilder: (ctx, child, progress) => progress == null
                      ? child
                      : const ColoredBox(
                          color: AppColors.darkTertiary,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                  errorBuilder: (ctx, error, stack) => const ColoredBox(
                    color: AppColors.darkTertiary,
                    child: Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 36,
                        color: AppColors.textOnDarkTertiary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
      footer: _DocumentFooter(
        isPdf: _isPdf,
        title: _fileName,
        subtitle: context.l10n.soat_doc_tap_to_open,
        actions: [
          _DocIconAction(
            icon: Icons.open_in_new_rounded,
            color: AppColors.primary,
            loading: _loading,
            onTap: _open,
          ),
          const SizedBox(width: 8),
          _DocIconAction(
            icon: Icons.swap_horiz_rounded,
            color: AppColors.textOnDarkSecondary,
            onTap: widget.onReplace,
          ),
        ],
      ),
    );
  }
}

// ── Sin documento ───────────────────────────────────────────────────────────────

class _EmptyDocumentSlot extends StatelessWidget {
  const _EmptyDocumentSlot({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.darkBorderPrimary),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primarySubtle,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.add_photo_alternate_outlined,
                size: 20,
                color: AppColors.primary,
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
                      fontWeight: FontWeight.w600,
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
