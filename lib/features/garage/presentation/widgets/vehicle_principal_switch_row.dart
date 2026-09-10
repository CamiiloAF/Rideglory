import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../design_system/components/app_switch_tile.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../cubit/vehicle_form_cubit.dart';
import '../cubit/vehicle_form_state.dart';

/// "Moto principal": la que se ve primero en la galería y en los
/// selectores. No se puede apagar sin marcar otra como principal.
///
/// Pencil: tbZKM › Moto principal
class VehiclePrincipalSwitchRow extends StatelessWidget {
  const VehiclePrincipalSwitchRow({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final cubit = context.read<VehicleFormCubit>();
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: BlocBuilder<VehicleFormCubit, VehicleFormState>(
        buildWhen: (previous, current) => previous.isMain != current.isMain,
        builder: (context, state) {
          return AppSwitchTile(
            label: context.l10n.garage_main_vehicle_label,
            value: state.isMain,
            onChanged: state.isMain ? null : (_) => cubit.setMain(),
          );
        },
      ),
    );
  }
}
