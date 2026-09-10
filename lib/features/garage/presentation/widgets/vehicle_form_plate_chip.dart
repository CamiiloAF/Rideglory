import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../cubit/vehicle_form_cubit.dart';
import '../cubit/vehicle_form_state.dart';

/// Chip con la placa ya confirmada y un enlace para volver a corregirla.
///
/// Pencil: e0fmR › chip superior
class VehicleFormPlateChip extends StatelessWidget {
  const VehicleFormPlateChip({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final cubit = context.read<VehicleFormCubit>();
    return BlocBuilder<VehicleFormCubit, VehicleFormState>(
      buildWhen: (previous, current) => previous.plate != current.plate,
      builder: (context, state) {
        return Container(
          width: double.infinity,
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: colors.accentSoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.checkCircle2, size: 18, color: colors.text),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  state.plate,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.text,
                  ),
                ),
              ),
              TextButton(
                onPressed: cubit.changePlate,
                child: Text(
                  context.l10n.garage_change_plate_button,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.text,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
