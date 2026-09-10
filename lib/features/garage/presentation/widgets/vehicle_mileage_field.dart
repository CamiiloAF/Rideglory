import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/thousands_input_formatter.dart';
import '../../../../design_system/components/app_text_field.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../cubit/vehicle_form_cubit.dart';

/// Kilometraje: punto de partida del odómetro al crear, o corrección
/// manual desde editar (D5).
///
/// Pencil: e0fmR › Kilometraje de hoy · tbZKM › Kilometraje actual
class VehicleMileageField extends StatelessWidget {
  const VehicleMileageField({this.isEditing = false, super.key});

  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<VehicleFormCubit>();
    return AppTextField(
      label: isEditing
          ? context.l10n.garage_mileage_current_label
          : context.l10n.garage_mileage_today_label,
      controller: cubit.mileageController,
      onChanged: cubit.mileageChanged,
      keyboardType: TextInputType.number,
      suffixText: context.l10n.garage_mileage_suffix,
      inputFormatters: [ThousandsInputFormatter()],
      helperText: isEditing
          ? context.l10n.garage_mileage_edit_helper
          : context.l10n.garage_mileage_create_helper,
    );
  }
}
