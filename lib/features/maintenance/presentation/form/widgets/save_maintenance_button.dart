import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/features/maintenance/constants/maintenance_strings.dart';
import 'package:rideglory/features/maintenance/presentation/form/cubit/maintenance_form_cubit.dart';
import 'package:rideglory/shared/widgets/form/app_button.dart';

class SaveMaintenanceButton extends StatelessWidget {
  final VoidCallback onSave;

  const SaveMaintenanceButton({super.key, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MaintenanceFormCubit, MaintenanceFormState>(
      builder: (context, state) {
        final isLoading = state.maybeWhen(
          loading: () => true,
          orElse: () => false,
        );
        return AppButton(
          label: MaintenanceStrings.saveMaintenance,
          icon: Icons.check_rounded,
          variant: AppButtonVariant.primary,
          isLoading: isLoading,
          onPressed: isLoading ? null : onSave,
        );
      },
    );
  }
}
