import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/cubit/vehicle_cubit.dart';
import 'package:rideglory/core/domain/models/vehicle_model.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/expandable_fab.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/item_card/modern_maintenance_card.dart';

class MaintenancesPage extends StatefulWidget {
  const MaintenancesPage({super.key});

  @override
  State<MaintenancesPage> createState() => _MaintenancesPageState();
}

class _MaintenancesPageState extends State<MaintenancesPage> {
  @override
  void initState() {
    super.initState();
    // Establecer un vehículo de ejemplo al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vehicleCubit = context.read<VehicleCubit>();
      if (vehicleCubit.currentVehicle == null) {
        vehicleCubit.setVehicle(
          const VehicleModel(
            id: '1',
            name: 'Mi Toyota Corolla',
            brand: 'Toyota',
            model: 'Corolla',
            year: 2020,
            currentMileage: 49800.0,
            distanceUnit: 'KM',
            licensePlate: 'ABC-123',
          ),
        );
      }
    });
  }

  // Datos fake para demostración
  List<MaintenanceModel> get _fakeMaintenances => [
    MaintenanceModel(
      id: '1',
      name: 'Cambio de aceite Mobil 1',
      type: MaintenanceType.oilChange,
      notes: 'Aceite sintético 5W-30, filtro incluido',
      date: DateTime(2026, 1, 15),
      nextMaintenanceDate: DateTime(2026, 4, 15),
      maintanceMileage: 50001,
      distanceUnit: DistanceUnit.kilometers,
      receiveAlert: true,
      nextMaintenanceMileage: 50000,
    ),
    MaintenanceModel(
      id: '2',
      name: 'Revisión general 50k',
      type: MaintenanceType.preventive,
      notes: 'Inspección de frenos, suspensión y sistema eléctrico',
      date: DateTime(2025, 12, 20),
      nextMaintenanceDate: DateTime(2026, 6, 20),
      maintanceMileage: 48500,
      distanceUnit: DistanceUnit.kilometers,
      receiveAlert: true,
      nextMaintenanceMileage: 55000,
    ),
    MaintenanceModel(
      id: '3',
      name: 'Cambio de filtros',
      type: MaintenanceType.preventive,
      notes: 'Filtro de aire, gasolina y cabina',
      date: DateTime(2026, 2, 1),
      nextMaintenanceDate: DateTime(2026, 8, 1),
      maintanceMileage: 49200,
      distanceUnit: DistanceUnit.kilometers,
      receiveAlert: false,
      nextMaintenanceMileage: 60000,
    ),
    MaintenanceModel(
      id: '4',
      name: 'Aceite y alineación',
      type: MaintenanceType.oilChange,
      notes: 'Aceite semi-sintético + balanceo y alineación',
      date: DateTime(2025, 11, 10),
      maintanceMileage: 47800,
      distanceUnit: DistanceUnit.kilometers,
      receiveAlert: true,
      nextMaintenanceMileage: 52000,
    ),
    MaintenanceModel(
      id: '5',
      name: 'Servicio de transmisión',
      type: MaintenanceType.preventive,
      notes: 'Cambio de aceite de transmisión automática',
      date: DateTime(2025, 10, 5),
      nextMaintenanceDate: DateTime(2026, 10, 5),
      maintanceMileage: 46000,
      distanceUnit: DistanceUnit.kilometers,
      receiveAlert: true,
      nextMaintenanceMileage: 70000,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text('Mantenimientos')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _fakeMaintenances.length,
        itemBuilder: (context, index) {
          final maintenance = _fakeMaintenances[index];
          return ModernMaintenanceCard(maintenance: maintenance);
        },
      ),
      floatingActionButton: const ExpandableFab(),
    );
  }
}
