import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../design_system/components/app_text_field.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../cubit/vehicle_form_cubit.dart';

/// Fila "Año" + "Cilindraje": ficha técnica opcional de la moto.
///
/// Pencil: e0fmR / tbZKM › Fila (Año, Cilindraje)
class VehicleYearEngineRow extends StatelessWidget {
  const VehicleYearEngineRow({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<VehicleFormCubit>();
    return Row(
      children: [
        Expanded(
          child: AppTextField(
            label: context.l10n.garage_year_field_label,
            controller: cubit.yearController,
            onChanged: cubit.yearChanged,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppTextField(
            label: context.l10n.garage_engine_cc_field_label,
            controller: cubit.engineCcController,
            onChanged: cubit.engineCcChanged,
            keyboardType: TextInputType.number,
            suffixText: context.l10n.garage_engine_cc_suffix,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
          ),
        ),
      ],
    );
  }
}
