import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/maintenance/constants/maintenance_strings.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/presentation/form/cubit/maintenance_form_cubit.dart';
import 'package:rideglory/shared/widgets/form/app_button.dart';

class SaveMaintenanceButton extends StatelessWidget {
  final VoidCallback onSave;

  const SaveMaintenanceButton({super.key, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MaintenanceFormCubit, ResultState<MaintenanceModel>>(
      builder: (context, state) {
        final isLoading = state is Loading;
        return AppButton(
          label: MaintenanceStrings.saveMaintenance,
          icon: Icons.save,
          variant: AppButtonVariant.primary,
          isLoading: isLoading,
          onPressed: isLoading ? null : onSave,
        );
      },
    );
  }
}
