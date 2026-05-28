import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/domain/nothing.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/http/rest_client_functions.dart';
import 'package:rideglory/features/maintenance/data/dto/maintenance_dto.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_list_summary.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_user_list_aggregate.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_vehicle_list_result.dart';
import 'package:rideglory/features/maintenance/domain/repository/maintenance_repository.dart';
import 'package:rideglory/features/maintenance/data/service/maintenance_service.dart';
import 'package:rideglory/features/vehicles/domain/repository/vehicle_repository.dart';

@Injectable(as: MaintenanceRepository)
class MaintenanceRepositoryImpl implements MaintenanceRepository {
  MaintenanceRepositoryImpl(this._maintenanceService, this._vehicleRepository);

  final MaintenanceService _maintenanceService;
  final VehicleRepository _vehicleRepository;

  @override
  Future<Either<DomainException, MaintenanceUserListAggregate>>
  getMaintenancesByUserId({
    List<MaintenanceType>? types,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final vehiclesResult = await _vehicleRepository.getMyVehicles();
    return await vehiclesResult.fold((error) async => Left(error), (
      vehicles,
    ) async {
      final ids = vehicles.map((vehicle) => vehicle.id).whereType<String>().toList();
      final batches = await Future.wait(
        ids.map(
          (vehicleId) => getMaintenancesByVehicleId(
            vehicleId,
            types: types,
            startDate: startDate,
            endDate: endDate,
          ),
        ),
      );
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
      aggregated.sort((a, b) {
        final dateA = a.serviceDate ?? a.createdDate ?? DateTime(0);
        final dateB = b.serviceDate ?? b.createdDate ?? DateTime(0);
        return dateB.compareTo(dateA);
      });
      return Right(
        MaintenanceUserListAggregate(
          items: aggregated,
          summariesByVehicleId: summariesByVehicleId,
        ),
      );
    });
  }

  @override
  Future<Either<DomainException, MaintenanceVehicleListResult>>
  getMaintenancesByVehicleId(
    String vehicleId, {
    List<MaintenanceType>? types,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return executeService(
      function: () async {
        final filter = _buildFilterMap(
          types: types,
          startDate: startDate,
          endDate: endDate,
        );
        final response = await _maintenanceService.getByVehicleId(
          vehicleId,
          filter: filter.isEmpty ? null : filter,
        );
        return MaintenanceVehicleListResult(
          items: List<MaintenanceModel>.from(response.items),
          summary: response.summary.toModel(),
        );
      },
    );
  }

  static Map<String, dynamic> _buildFilterMap({
    List<MaintenanceType>? types,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return {
      if (types != null && types.isNotEmpty)
        'types': types.map(_typeToApi).toList(),
      if (startDate != null) 'startDate': startDate.toUtc().toIso8601String(),
      if (endDate != null) 'endDate': endDate.toUtc().toIso8601String(),
    };
  }

  static String _typeToApi(MaintenanceType type) => switch (type) {
    MaintenanceType.oilChange => 'OIL_CHANGE',
    MaintenanceType.brakeCheck => 'BRAKE_CHECK',
    MaintenanceType.tireChange => 'TIRE_CHANGE',
    MaintenanceType.preventive => 'PREVENTIVE',
    MaintenanceType.airFilter => 'AIR_FILTER',
    MaintenanceType.chainSprocket => 'CHAIN_SPROCKET',
    MaintenanceType.electrical => 'ELECTRICAL',
    MaintenanceType.other => 'OTHER',
  };

  @override
  Future<Either<DomainException, List<MaintenanceModel>>> addMaintenance(
    MaintenanceModel maintenance,
    int? nextKmInterval,
  ) async {
    final vehicleId = maintenance.vehicleId;
    if (vehicleId == null) {
      return const Left(
        DomainException(
          message: 'Vehicle ID is required to create maintenance.',
        ),
      );
    }

    return executeService(
      function: () async {
        final body = _buildCreateBody(maintenance, nextKmInterval);
        final response = await _maintenanceService.create(vehicleId, body);
        return response.toModels();
      },
    );
  }

  static Map<String, dynamic> _buildCreateBody(
    MaintenanceModel maintenance,
    int? nextKmInterval,
  ) {
    return {
      'type': _typeToApi(maintenance.type),
      'mode': maintenance.mode == MaintenanceMode.completed ? 'COMPLETED' : 'SCHEDULED',
      if (maintenance.serviceDate != null)
        'serviceDate': maintenance.serviceDate!.toUtc().toIso8601String(),
      if (maintenance.odometerAtService != null)
        'odometerAtService': maintenance.odometerAtService,
      if (maintenance.workshop != null) 'workshop': maintenance.workshop,
      if (maintenance.notes != null) 'notes': maintenance.notes,
      'nextKmInterval': ?nextKmInterval,
      if (maintenance.nextOdometer != null) 'nextOdometer': maintenance.nextOdometer,
      if (maintenance.nextDate != null)
        'nextDate': maintenance.nextDate!.toUtc().toIso8601String(),
      if (maintenance.cost != null) 'cost': maintenance.cost,
    };
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
          maintenance.toJson(),
        );
        return dto;
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
}
