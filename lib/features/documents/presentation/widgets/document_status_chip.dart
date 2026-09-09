import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../design_system/components/app_status_chip.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/models/vehicle_document.dart';

/// Chip de vigencia de un documento: vigente, vence pronto o vencido.
class DocumentStatusChip extends StatelessWidget {
  const DocumentStatusChip({required this.document, super.key});

  final VehicleDocument document;

  @override
  Widget build(BuildContext context) {
    final status = document.statusAt(DateTime.now());
    final (label, tone) = switch (status) {
      DocumentStatus.valid => (context.l10n.documents_status_valid, AppStatusTone.success),
      DocumentStatus.expiringSoon => (context.l10n.documents_status_expiring_soon, AppStatusTone.warning),
      DocumentStatus.expired => (context.l10n.documents_status_expired, AppStatusTone.error),
    };
    return AppStatusChip(icon: LucideIcons.checkCircle2, label: label, tone: tone);
  }
}
