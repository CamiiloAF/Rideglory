import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/thousands_input_formatter.dart';
import '../../../../design_system/components/app_status_chip.dart';
import '../../../../design_system/components/vehicle_cell.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/models/vehicle.dart';
import '../../domain/models/vehicle_document_alert.dart';
import '../cubit/garage_gallery_cubit.dart';

/// Adapta un [Vehicle] de dominio a la celda visual [VehicleCell] y arma el
/// texto del chip de alerta con `l10n` (el dominio nunca construye strings
/// de UI).
///
/// Pencil: YXXpJ
class VehicleCellTile extends StatelessWidget {
  const VehicleCellTile({required this.vehicle, super.key});

  final Vehicle vehicle;

  Future<void> _openEditVehicle(BuildContext context) async {
    final changed = await context.pushNamed<bool>(AppRoutes.vehicleEdit, extra: vehicle);
    if (changed == true && context.mounted) {
      context.read<GarageGalleryCubit>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final alert = vehicle.documentAlert;
    return VehicleCell(
      name: vehicle.name,
      kilometers: context.l10n.garage_mileage_value(
        ThousandsInputFormatter.format(vehicle.currentMileage) ?? '0',
      ),
      imageUrl: vehicle.imageUrl,
      isMain: vehicle.isMain,
      pendingLabel: alert == null ? null : _alertLabel(context, alert),
      pendingIcon: LucideIcons.alertTriangle,
      pendingTone: alert?.severity == DocumentAlertSeverity.critical
          ? AppStatusTone.error
          : AppStatusTone.warning,
      onTap: () => _openEditVehicle(context),
    );
  }

  String _alertLabel(BuildContext context, VehicleDocumentAlert alert) {
    final kindLabel = alert.kind == DocumentAlertKind.soat
        ? context.l10n.garage_document_kind_soat
        : context.l10n.garage_document_kind_rtm;
    if (alert.severity == DocumentAlertSeverity.critical) {
      return context.l10n.garage_document_alert_expired(kindLabel);
    }
    return context.l10n.garage_document_alert_expiring(kindLabel, alert.daysUntilExpiry);
  }
}
