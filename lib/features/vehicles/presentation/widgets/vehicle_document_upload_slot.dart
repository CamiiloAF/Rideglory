import 'package:flutter/material.dart';
import 'package:rideglory/design_system/foundation/theme/app_colors.dart';
import 'package:rideglory/features/vehicles/presentation/widgets/vehicle_document_icon_slot.dart';
import 'package:rideglory/features/vehicles/presentation/widgets/vehicle_document_upload_button.dart';

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
    this.onTap,
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

  /// Llamado al tocar el slot cuando ya tiene datos ([_hasDocument] es true).
  final VoidCallback? onTap;

  bool get _hasDocument => localPath != null || hasData;

  String _displaySubtitle() {
    if (!_hasDocument) return subtitle;
    if (localPath != null) return localPath!.split('/').last;
    return dataLabel ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorderPrimary),
      ),
      child: Row(
        children: [
          VehicleDocumentIconSlot(
            hasDocument: _hasDocument,
            localPath: localPath,
          ),
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
            VehicleDocumentUploadButton(onTap: onUploadTap),
        ],
      ),
    );

    if (_hasDocument && onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}
