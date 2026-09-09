import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../cubit/garage_gallery_cubit.dart';

/// Celda de "Agregar moto" al final de la galería.
///
/// Pencil: V02g9 › Agregar moto
class VehicleAddTile extends StatelessWidget {
  const VehicleAddTile({super.key});

  Future<void> _openAddVehicle(BuildContext context) async {
    final created = await context.pushNamed<bool>(AppRoutes.vehicleAdd);
    if (created == true && context.mounted) {
      context.read<GarageGalleryCubit>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _openAddVehicle(context),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.borderStrong),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.plus, size: 30, color: colors.text),
            const SizedBox(height: 8),
            Text(
              context.l10n.garage_add_vehicle_button_short,
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: colors.text),
            ),
          ],
        ),
      ),
    );
  }
}
