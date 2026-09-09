import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../design_system/components/app_text_field.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../cubit/vehicle_form_cubit.dart';

/// "Línea": texto libre, no hay catálogo de modelos por marca en Colombia.
///
/// Pencil: e0fmR / tbZKM › Campo Línea
class VehicleModelField extends StatelessWidget {
  const VehicleModelField({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<VehicleFormCubit>();
    return AppTextField(
      label: context.l10n.garage_model_field_label,
      controller: cubit.modelController,
      onChanged: cubit.modelChanged,
    );
  }
}
