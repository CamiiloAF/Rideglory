import 'package:flutter/material.dart';

import '../../domain/models/vehicle.dart';
import 'vehicle_add_tile.dart';
import 'vehicle_cell_tile.dart';

/// Grilla 2x2 de la galería: motos activas + la tarjeta de "Agregar moto"
/// al final. Las archivadas no se listan aquí (se gestionan desde la ficha
/// de cada moto).
///
/// Pencil: V02g9, NQnlL
class VehicleGalleryGrid extends StatelessWidget {
  const VehicleGalleryGrid({required this.vehicles, super.key});

  final List<Vehicle> vehicles;

  @override
  Widget build(BuildContext context) {
    final activeVehicles = vehicles.where((vehicle) => !vehicle.isArchived).toList();
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: activeVehicles.length + 1,
      itemBuilder: (context, index) {
        if (index == activeVehicles.length) return const VehicleAddTile();
        return VehicleCellTile(vehicle: activeVehicles[index]);
      },
    );
  }
}
