import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../design_system/components/app_switch_tile.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../../../shared/widgets/notification_permission_sheet.dart';
import '../../data/services/document_reminder_scheduler.dart';
import '../../domain/models/vehicle_document.dart';
import '../cubit/document_viewer_cubit.dart';

/// Recordatorio de vencimiento del documento (D6). Activarlo pasa antes por
/// el aviso propio (`NotificationPermissionSheet`): solo si el rider
/// confirma ahí se dispara el permiso del sistema.
class DocumentReminderToggle extends StatelessWidget {
  const DocumentReminderToggle({
    required this.vehicleId,
    required this.document,
    super.key,
  });

  final String vehicleId;
  final VehicleDocument document;

  Future<void> _onChanged(BuildContext context, bool enabled) async {
    final cubit = context.read<DocumentViewerCubit>();
    final l10n = context.l10n;
    if (enabled) {
      final granted = await requestNotificationPermissionWithConsent(
        context,
        requestSystemPermission: () =>
            getIt<DocumentReminderScheduler>().requestPermission(),
      );
      if (!granted || !context.mounted) return;
    }
    final title = document.kind == DocumentKind.soat
        ? l10n.documents_soat_title
        : l10n.documents_rtm_title;
    await cubit.setReminderEnabled(
      vehicleId,
      enabled: enabled,
      vehicleName: vehicleId,
      title: title,
      bodyBuilder: (daysBefore) => l10n.documents_reminder_body(daysBefore),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppSwitchTile(
      label: context.l10n.documents_reminder_toggle_label,
      subtitle: context.l10n.documents_reminder_toggle_subtitle,
      value: document.reminderEnabled,
      onChanged: (enabled) => _onChanged(context, enabled),
    );
  }
}
