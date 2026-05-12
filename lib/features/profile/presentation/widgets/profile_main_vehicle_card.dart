import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';

class ProfileMainVehicleCard extends StatelessWidget {
  const ProfileMainVehicleCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<VehicleCubit, dynamic>(
      builder: (context, state) {
        final vehicleCubit = context.read<VehicleCubit>();
        final mainVehicle = vehicleCubit.currentVehicle;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.profile_mainVehicle,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            if (mainVehicle != null)
              Chip(
                label: Text(
                  mainVehicle.brand != null
                      ? '${mainVehicle.brand} ${mainVehicle.name}'
                      : mainVehicle.name,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                backgroundColor: colorScheme.surfaceContainerHighest,
                side: BorderSide.none,
                avatar: Icon(
                  Icons.two_wheeler_rounded,
                  color: colorScheme.primary,
                  size: 18,
                ),
              )
            else
              Text(
                context.l10n.profile_noVehicle,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
          ],
        );
      },
    );
  }
}
