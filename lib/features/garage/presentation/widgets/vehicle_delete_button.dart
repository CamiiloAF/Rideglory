import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../design_system/components/app_secondary_button.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../cubit/vehicle_form_cubit.dart';
import 'vehicle_delete_confirm_sheet.dart';

/// "Eliminar moto": borra la moto (y en cascada sus documentos) tras
/// confirmar. Rojo de error, nunca el naranja/amarillo de marca.
///
/// Pencil: tbZKM › Eliminar moto
class VehicleDeleteButton extends StatelessWidget {
  const VehicleDeleteButton({super.key});

  void _openDeleteConfirm(BuildContext context) {
    final cubit = context.read<VehicleFormCubit>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => VehicleDeleteConfirmSheet(
        onConfirm: () async {
          Navigator.of(sheetContext).pop();
          final deleted = await cubit.delete();
          if (deleted && context.mounted) context.pop(true);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppSecondaryButton(
      label: context.l10n.garage_delete_vehicle_button,
      icon: LucideIcons.trash2,
      destructive: true,
      onPressed: () => _openDeleteConfirm(context),
    );
  }
}
