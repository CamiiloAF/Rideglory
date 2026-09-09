import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../design_system/components/app_secondary_button.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/models/vehicle.dart';
import '../cubit/vehicle_form_cubit.dart';

/// Archivar/restaurar: no está en el frame aprobado de `tbZKM` (solo tiene
/// "Eliminar moto"), pero el alcance de la fase lo pide explícitamente, así
/// que se agrega con el botón secundario del sistema — ver informe.
class VehicleArchiveButton extends StatelessWidget {
  const VehicleArchiveButton({required this.vehicle, super.key});

  final Vehicle vehicle;

  Future<void> _toggleArchive(BuildContext context) async {
    final cubit = context.read<VehicleFormCubit>();
    if (vehicle.isArchived) {
      await cubit.unarchive();
    } else {
      await cubit.archive();
    }
    if (context.mounted) context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AppSecondaryButton(
      label: vehicle.isArchived
          ? context.l10n.garage_unarchive_vehicle_button
          : context.l10n.garage_archive_vehicle_button,
      icon: LucideIcons.archive,
      onPressed: () => _toggleArchive(context),
    );
  }
}
