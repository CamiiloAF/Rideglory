import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

/// Contenido del bottom sheet "Agregar documento" del formulario de SOAT.
///
/// Devuelve la opción elegida vía `Navigator.pop`:
/// - `1` = Galería
/// - `2` = Archivo PDF
class SoatAddDocumentSheet extends StatelessWidget {
  const SoatAddDocumentSheet({super.key});

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
              context.l10n.soat_add_doc_sheet_title,
              style: const TextStyle(
                color: AppColors.textOnDarkPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            _SoatAddDocumentOption(
              icon: Icons.photo_library_outlined,
              label: context.l10n.soat_source_gallery,
              subtitle: context.l10n.soat_add_doc_gallery_subtitle,
              // Custom: typed-result pop is required for showModalBottomSheet.
              onTap: () => context.pop(1),
            ),
            const SizedBox(height: 10),
            _SoatAddDocumentOption(
              icon: Icons.picture_as_pdf_outlined,
              label: context.l10n.soat_source_pdf,
              subtitle: context.l10n.soat_add_doc_pdf_subtitle,
              // Custom: typed-result pop is required for showModalBottomSheet.
              onTap: () => context.pop(2),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoatAddDocumentOption extends StatelessWidget {
  const _SoatAddDocumentOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.darkTertiary,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.darkBorderPrimary),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primarySubtle,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.textOnDarkPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textOnDarkTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.textOnDarkTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
