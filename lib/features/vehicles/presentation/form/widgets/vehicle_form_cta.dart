import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_form_cubit.dart';

class VehicleFormCta extends StatelessWidget {
  const VehicleFormCta({
    super.key,
    required this.onSave,
    required this.onDelete,
  });

  final VoidCallback onSave;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VehicleFormCubit, VehicleFormState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppButton(
              onPressed: onSave,
              isLoading: state.isLoading,
              label: context.l10n.vehicle_form_save,
            ),
            if (state.isEditing) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: state.isLoading ? null : onDelete,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.delete_outline,
                      size: 14,
                      color: AppColors.textOnDarkTertiary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      context.l10n.vehicle_form_delete_vehicle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textOnDarkTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
