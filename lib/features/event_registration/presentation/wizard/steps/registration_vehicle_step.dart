import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/save_to_profile_checkbox.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/vehicle_selector_empty.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/vehicle_selector_field.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/vehicle_selector_loading.dart';
import 'package:rideglory/features/event_registration/presentation/wizard/registration_step_header.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';

class RegistrationVehicleStep extends StatelessWidget {
  const RegistrationVehicleStep({super.key, required this.onCreateVehicle});

  final VoidCallback onCreateVehicle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RegistrationStepHeader(
          icon: Icons.two_wheeler_outlined,
          title: context.l10n.registration_stepVehicleTitle,
          subtitle: context.l10n.registration_stepVehicleSubtitle,
        ),
        AppSpacing.gapLg,
        BlocBuilder<VehicleCubit, ResultState<List<VehicleModel>>>(
          builder: (context, state) {
            return state.when(
              initial: () => const VehicleSelectorLoading(),
              loading: () => const VehicleSelectorLoading(),
              data: (vehicles) {
                final available = vehicles
                    .where((vehicle) => !vehicle.isArchived)
                    .toList();
                if (available.isEmpty) {
                  return VehicleSelectorEmpty(onCreate: onCreateVehicle);
                }
                return VehicleSelectorField(availableVehicles: available);
              },
              empty: () => VehicleSelectorEmpty(onCreate: onCreateVehicle),
              error: (_) => VehicleSelectorEmpty(onCreate: onCreateVehicle),
            );
          },
        ),
        AppSpacing.gapLg,
        const SaveToProfileCheckbox(),
      ],
    );
  }
}
