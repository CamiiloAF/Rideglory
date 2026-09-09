import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../design_system/components/app_secondary_button.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../cubit/vehicle_form_cubit.dart';

/// "Eliminar moto": borra la moto (y en cascada sus documentos) tras
/// confirmar. Rojo de error, nunca el naranja/amarillo de marca.
///
/// Pencil: tbZKM › Eliminar moto
class VehicleDeleteButton extends StatelessWidget {
  const VehicleDeleteButton({super.key});

  Future<void> _confirmAndDelete(BuildContext context) async {
    final colors = Theme.of(context).extension<AppColors>()!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.garage_delete_confirm_title),
        content: Text(dialogContext.l10n.garage_delete_confirm_body),
        actions: [
          TextButton(
            onPressed: () => dialogContext.pop(false),
            child: Text(dialogContext.l10n.garage_delete_cancel),
          ),
          TextButton(
            onPressed: () => dialogContext.pop(true),
            child: Text(
              dialogContext.l10n.garage_delete_confirm_action,
              style: TextStyle(color: colors.errorText),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final deleted = await context.read<VehicleFormCubit>().delete();
    if (deleted && context.mounted) context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AppSecondaryButton(
      label: context.l10n.garage_delete_vehicle_button,
      icon: LucideIcons.trash2,
      destructive: true,
      onPressed: () => _confirmAndDelete(context),
    );
  }
}
