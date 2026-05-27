import 'dart:io';
import 'package:flutter/material.dart';
import 'package:rideglory/design_system/foundation/theme/app_colors.dart';

class VehicleDocumentUploadSlot extends StatelessWidget {
  const VehicleDocumentUploadSlot({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onUploadTap,
    this.localPath,
    this.hasData = false,
    this.dataLabel,
    this.onClear,
  });

  final String title;
  final String subtitle;
  final VoidCallback onUploadTap;
  final String? localPath;

  /// Fuerza el estado "documento agregado" aunque [localPath] sea nulo.
  /// Útil cuando el SOAT fue ingresado manualmente sin adjuntar archivo.
  final bool hasData;

  /// Texto que se muestra como subtítulo cuando [hasData] es `true` pero
  /// [localPath] es nulo (no hay archivo local para mostrar el nombre).
  final String? dataLabel;

  final VoidCallback? onClear;

  bool get _hasDocument => localPath != null || hasData;

  String _displaySubtitle() {
    if (!_hasDocument) return subtitle;
    if (localPath != null) return localPath!.split('/').last;
    return dataLabel ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorderPrimary),
      ),
      child: Row(
        children: [
          _IconSlot(hasDocument: _hasDocument, localPath: localPath),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textOnDarkPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _displaySubtitle(),
                  style: TextStyle(
                    fontSize: 11,
                    color: _hasDocument
                        ? AppColors.primary
                        : AppColors.textOnDarkTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (_hasDocument && onClear != null)
            GestureDetector(
              onTap: onClear,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.darkTertiary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: AppColors.textOnDarkSecondary,
                ),
              ),
            )
          else
            _UploadButton(onTap: onUploadTap),
        ],
      ),
    );
  }
}

class _IconSlot extends StatelessWidget {
  const _IconSlot({required this.hasDocument, this.localPath});

  final bool hasDocument;
  final String? localPath;

  @override
  Widget build(BuildContext context) {
    if (hasDocument && localPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Image.file(
            File(localPath!),
            fit: BoxFit.cover,
            errorBuilder: (ctx, e, s) => const _DefaultIconSlot(hasDocument: true),
          ),
        ),
      );
    }
    return _DefaultIconSlot(hasDocument: hasDocument);
  }
}

class _DefaultIconSlot extends StatelessWidget {
  const _DefaultIconSlot({required this.hasDocument});

  final bool hasDocument;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: hasDocument ? AppColors.primarySubtle : AppColors.darkTertiary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.description_outlined,
        size: 20,
        color: hasDocument
            ? AppColors.primary
            : AppColors.textOnDarkSecondary,
      ),
    );
  }
}

class _UploadButton extends StatelessWidget {
  const _UploadButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.darkTertiary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.darkBorderLight),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.upload, size: 14, color: AppColors.textOnDarkSecondary),
            SizedBox(width: 6),
            Text(
              'Subir',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textOnDarkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
