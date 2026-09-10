import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/models/vehicle_document.dart';
import 'document_status_chip.dart';

/// Fila ancha de un documento (SOAT o RTM) en la ficha de la moto: fecha de
/// vencimiento y chip de estado, o la invitación a subirlo.
///
/// Pencil: derivado de `tbZKM` — el frame aprobado no incluye esta fila
/// (ver informe de cierre), así que se construye con `RecordRow`/tokens del
/// sistema en vez del componente de mantenimiento que sí la tiene.
class DocumentRow extends StatelessWidget {
  const DocumentRow({
    required this.vehicleId,
    required this.kind,
    this.document,
    super.key,
  });

  final String vehicleId;
  final DocumentKind kind;
  final VehicleDocument? document;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final kindLabel = kind == DocumentKind.soat
        ? context.l10n.documents_soat_title
        : context.l10n.documents_rtm_title;
    final document = this.document;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.pushNamed(
        AppRoutes.documentViewer,
        pathParameters: {'kind': kind.name},
        extra: vehicleId,
      ),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.fileText, size: 20, color: colors.text),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    kindLabel,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: colors.text,
                    ),
                  ),
                  Text(
                    document == null
                        ? context.l10n.documents_not_uploaded_short
                        : context.l10n.documents_expires_on(
                            DateFormat(
                              'd MMM yyyy',
                              'es_CO',
                            ).format(document.expiryDate),
                          ),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (document != null) DocumentStatusChip(document: document),
            const SizedBox(width: 6),
            Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
