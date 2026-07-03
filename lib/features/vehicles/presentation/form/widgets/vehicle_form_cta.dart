import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_form_cubit.dart';

class VehicleFormCta extends StatelessWidget {
  const VehicleFormCta({super.key, required this.onSave});

  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VehicleFormCubit, VehicleFormState>(
      builder: (context, state) {
        return AppButton(
          onPressed: onSave,
          isLoading: state.isLoading,
          label: context.l10n.vehicle_form_save,
        );
      },
    );
  }
}
