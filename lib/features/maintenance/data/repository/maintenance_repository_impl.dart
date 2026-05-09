import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/domain/nothing.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/extensions/date_extensions.dart';
import 'package:rideglory/core/http/rest_client_functions.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_list_summary.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_user_list_aggregate.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_vehicle_list_result.dart';
import 'package:rideglory/features/maintenance/domain/repository/maintenance_repository.dart';
import 'package:rideglory/features/maintenance/data/service/maintenance_service.dart';
import 'package:rideglory/features/vehicles/domain/repository/vehicle_repository.dart';

@Injectable(as: MaintenanceRepository)
class MaintenanceRepositoryImpl implements MaintenanceRepository {
  MaintenanceRepositoryImpl(
    this._maintenanceService,
    this._vehicleRepository,
  );

  final MaintenanceService _maintenanceService;
  final VehicleRepository _vehicleRepository;

  @override
  Future<Either<DomainException, MaintenanceUserListAggregate>>
      getMaintenancesByUserId() async {
    final vehiclesResult = await _vehicleRepository.getMyVehicles();
    return await vehiclesResult.fold(
      (error) async => Left(error),
      (vehicles) async {
        final ids = vehicles.map((v) => v.id).whereType<String>().toList();
        final batches = await Future.wait(ids.map(getMaintenancesByVehicleId));
        final aggregated = <MaintenanceModel>[];
        final summariesByVehicleId = <String, MaintenanceListSummary>{};
        for (var i = 0; i < batches.length; i++) {
          final batch = batches[i];
          final DomainException? err = batch.fold((l) => l, (_) => null);
          if (err != null) return Left(err);
          final page = batch.getOrElse(() => throw StateError('Expected Right'));
          aggregated.addAll(page.items);
          summariesByVehicleId[ids[i]] = page.summary;
        }
        aggregated.sort((a, b) => b.date.compareTo(a.date));
        return Right(
          MaintenanceUserListAggregate(
            items: aggregated,
            summariesByVehicleId: summariesByVehicleId,
          ),
        );
      },
    );
  }

  @override
  Future<Either<DomainException, MaintenanceVehicleListResult>>
      getMaintenancesByVehicleId(String vehicleId) async {
    return executeService(
      function: () async {
        final response = await _maintenanceService.getByVehicleId(vehicleId);
        return MaintenanceVehicleListResult(
          items: response.items.map((dto) => dto.toModel()).toList(),
          summary: response.summary.toModel(),
        );
      },
    );
  }

  @override
  Future<Either<DomainException, MaintenanceModel>> addMaintenance(
    MaintenanceModel maintenance,
  ) async {
    final vehicleId = maintenance.vehicleId;
    if (vehicleId == null) {
      return const Left(
        DomainException(message: 'Vehicle ID is required to create maintenance.'),
      );
    }

    return executeService(
      function: () async {
        final dto = await _maintenanceService.create(
          vehicleId,
          _writePayload(maintenance),
        );
        return dto.toModel();
      },
    );
  }

  @override
  Future<Either<DomainException, MaintenanceModel>> updateMaintenance(
    MaintenanceModel maintenance,
  ) async {
    final vehicleId = maintenance.vehicleId;
    final id = maintenance.id;
    if (vehicleId == null || id == null) {
      return const Left(
        DomainException(
          message: 'Vehicle ID and maintenance ID are required for update.',
        ),
      );
    }

    return executeService(
      function: () async {
        final dto = await _maintenanceService.update(
          vehicleId,
          id,
          _writePayload(maintenance),
        );
        return dto.toModel();
      },
    );
  }

  @override
  Future<Either<DomainException, Nothing>> deleteMaintenance(
    MaintenanceModel maintenance,
  ) async {
    final vehicleId = maintenance.vehicleId;
    final maintenanceId = maintenance.id;
    if (vehicleId == null || maintenanceId == null) {
      return const Left(
        DomainException(
          message:
              'Vehicle ID and maintenance ID are required to delete maintenance.',
        ),
      );
    }

    return executeService(
      function: () async {
        await _maintenanceService.delete(vehicleId, maintenanceId);
        return const Nothing();
      },
    );
  }

  Map<String, dynamic> _writePayload(MaintenanceModel m) {
    return {
      'name': m.name,
      'type': _maintenanceTypeApi(m.type),
      if (m.notes != null) 'notes': m.notes,
      'date': m.date.toApiIso8601String(),
      'nextMaintenanceDate': m.nextMaintenanceDate.toApiIso8601String(),
      'maintanceMileage': m.maintanceMileage,
      'receiveAlert': m.receiveAlert,
      'receiveMileageAlert': m.receiveMileageAlert,
      'receiveDateAlert': m.receiveDateAlert,
      'nextMaintenanceMileage': m.nextMaintenanceMileage,
      'cost': m.cost,
    }..removeWhere((_, value) => value == null);
  }

  static String _maintenanceTypeApi(MaintenanceType type) => switch (type) {
        MaintenanceType.oilChange => 'OIL_CHANGE',
        MaintenanceType.preventive => 'PREVENTIVE',
      };
}
