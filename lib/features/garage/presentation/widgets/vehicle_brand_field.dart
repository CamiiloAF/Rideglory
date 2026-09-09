import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../design_system/components/app_text_field.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../cubit/vehicle_form_cubit.dart';

/// Campo de marca: solo lectura, abre el buscador (SEL) al tocarlo.
///
/// Pencil: e0fmR / tbZKM › Campo Marca
class VehicleBrandField extends StatelessWidget {
  const VehicleBrandField({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<VehicleFormCubit>();
    return AppTextField(
      label: context.l10n.garage_brand_field_label,
      controller: cubit.brandController,
      readOnly: true,
      onTap: () async {
        final selected = await context.pushNamed<String>(AppRoutes.brandPicker);
        if (selected != null) cubit.brandSelected(selected);
      },
    );
  }
}
