import 'package:flutter/material.dart';

import '../../../../core/domain/result_state.dart';
import '../../domain/rider_vehicle_preview.dart';
import 'profile_vehicle_thumbnail.dart';
import 'vehicles_row_skeleton.dart';

/// Fila horizontal de motos en P2. `empty`/`error` no bloquean la ficha del
/// rider entera: solo ocultan la sección (sin motos no es un error).
///
/// Pencil: iFssW
class ProfileVehiclesRow extends StatelessWidget {
  const ProfileVehiclesRow({required this.vehiclesState, super.key});

  final ResultState<List<RiderVehiclePreview>> vehiclesState;

  @override
  Widget build(BuildContext context) {
    return vehiclesState.when(
      initial: () => const VehiclesRowSkeleton(),
      loading: () => const VehiclesRowSkeleton(),
      empty: () => const SizedBox.shrink(),
      error: (error) => const SizedBox.shrink(),
      data: (vehicles) => SizedBox(
        height: 108,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: vehicles.length,
          separatorBuilder: (context, index) => const SizedBox(width: 10),
          itemBuilder: (context, index) =>
              ProfileVehicleThumbnail(vehicle: vehicles[index]),
        ),
      ),
    );
  }
}
