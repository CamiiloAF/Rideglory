import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../design_system/components/app_primary_button.dart';
import '../../../../design_system/components/app_text_field.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../cubit/vehicle_form_cubit.dart';
import '../cubit/vehicle_form_state.dart';

/// Paso 1 del alta: "¿Cuál es la placa?" — lo único necesario para empezar.
///
/// Pencil: KIdCH (vacío/válido), ruRle (formato inválido)
class VehicleFormPlateStep extends StatelessWidget {
  const VehicleFormPlateStep({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final cubit = context.read<VehicleFormCubit>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.garage_plate_question,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: colors.text),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.garage_plate_hint,
            style: TextStyle(fontSize: 13.5, color: colors.textSecondary),
          ),
          const SizedBox(height: 24),
          BlocBuilder<VehicleFormCubit, VehicleFormState>(
            buildWhen: (previous, current) => previous.plateInvalid != current.plateInvalid,
            builder: (context, state) {
              return AppTextField(
                label: context.l10n.garage_plate_field_label,
                controller: cubit.plateController,
                onChanged: cubit.plateChanged,
                keyboardType: TextInputType.text,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9 ]')),
                  LengthLimitingTextInputFormatter(7),
                ],
                errorText: state.plateInvalid ? context.l10n.garage_plate_invalid_error : null,
                helperText: state.plateInvalid ? null : context.l10n.garage_plate_helper,
              );
            },
          ),
          const Spacer(),
          BlocBuilder<VehicleFormCubit, VehicleFormState>(
            buildWhen: (previous, current) => previous.canContinueFromPlate != current.canContinueFromPlate,
            builder: (context, state) {
              return AppPrimaryButton(
                label: context.l10n.garage_continue_button,
                onPressed: state.canContinueFromPlate ? cubit.continueFromPlate : null,
              );
            },
          ),
        ],
      ),
    );
  }
}
