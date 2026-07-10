import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/maintenance/data/dto/create_maintenance_response_dto.dart';
import 'package:rideglory/features/maintenance/data/dto/maintenance_dto.dart';
import 'package:rideglory/features/maintenance/data/dto/vehicle_maintenances_list_response_dto.dart';
import 'package:rideglory/features/maintenance/data/repository/maintenance_repository_impl.dart';
import 'package:rideglory/features/maintenance/data/service/maintenance_service.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/domain/repository/vehicle_repository.dart';

class MockMaintenanceService extends Mock implements MaintenanceService {}

class MockVehicleRepository extends Mock implements VehicleRepository {}

DioException _dioException() => DioException(
  requestOptions: RequestOptions(path: '/maintenances'),
  type: DioExceptionType.connectionError,
);

void main() {
  late MockMaintenanceService mockService;
  late MockVehicleRepository mockVehicleRepository;
  late MaintenanceRepositoryImpl repository;

  setUp(() {
    mockService = MockMaintenanceService();
    mockVehicleRepository = MockVehicleRepository();
    repository = MaintenanceRepositoryImpl(mockService, mockVehicleRepository);
  });

  const vehicle1 = VehicleModel(id: 'v1', name: 'Moto 1', currentMileage: 12000);
  const vehicle2 = VehicleModel(id: 'v2', name: 'Moto 2', currentMileage: 5000);

  final dtoV1 = MaintenanceDto(
    id: 'm1',
    vehicleId: 'v1',
    type: MaintenanceType.oilChange,
    mode: MaintenanceMode.completed,
    serviceDate: DateTime(2026, 5, 1),
  );

  final dtoV2 = MaintenanceDto(
    id: 'm2',
    vehicleId: 'v2',
    type: MaintenanceType.brakeCheck,
    mode: MaintenanceMode.completed,
    serviceDate: DateTime(2026, 6, 1),
  );

  VehicleMaintenancesListResponseDto responseFor(MaintenanceDto dto) =>
      VehicleMaintenancesListResponseDto(
        items: [dto],
        summary: const MaintenanceListSummaryDto(lastServiceMileage: 12000),
      );

  group('getMaintenancesByVehicleId', () {
    test('camino feliz — mapea items y summary', () async {
      when(
        () => mockService.getByVehicleId('v1', filter: null),
      ).thenAnswer((_) async => responseFor(dtoV1));

      final result = await repository.getMaintenancesByVehicleId('v1');

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected Right'), (page) {
        expect(page.items, hasLength(1));
        expect(page.items.first.id, 'm1');
        expect(page.summary.lastServiceMileage, 12000);
      });
    });

    test('construye el filtro de tipos y fechas para la query', () async {
      when(
        () => mockService.getByVehicleId('v1', filter: any(named: 'filter')),
      ).thenAnswer((_) async => responseFor(dtoV1));

      await repository.getMaintenancesByVehicleId(
        'v1',
        types: [MaintenanceType.oilChange, MaintenanceType.brakeCheck],
        startDate: DateTime.utc(2026, 1, 1),
        endDate: DateTime.utc(2026, 6, 30),
      );

      final captured = verify(
        () => mockService.getByVehicleId('v1', filter: captureAny(named: 'filter')),
      ).captured;
      final filter = captured.single as Map<String, dynamic>;
      expect(filter['types'], ['OIL_CHANGE', 'BRAKE_CHECK']);
      expect(filter['startDate'], '2026-01-01T00:00:00.000Z');
      expect(filter['endDate'], '2026-06-30T00:00:00.000Z');
    });

    test('camino de error — DioException retorna Left', () async {
      when(
        () => mockService.getByVehicleId('v1', filter: null),
      ).thenThrow(_dioException());

      final result = await repository.getMaintenancesByVehicleId('v1');

      expect(result.isLeft(), isTrue);
    });
  });

  group('getMaintenancesByUserId', () {
    test(
      'camino feliz — agrega mantenimientos de todos los vehículos ordenados por fecha desc',
      () async {
        when(
          () => mockVehicleRepository.getMyVehicles(),
        ).thenAnswer((_) async => const Right([vehicle1, vehicle2]));
        when(
          () => mockService.getByVehicleId('v1', filter: null),
        ).thenAnswer((_) async => responseFor(dtoV1));
        when(
          () => mockService.getByVehicleId('v2', filter: null),
        ).thenAnswer((_) async => responseFor(dtoV2));

        final result = await repository.getMaintenancesByUserId();

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Expected Right'), (aggregate) {
          expect(aggregate.items, hasLength(2));
          // dtoV2 (2026-06-01) es más reciente que dtoV1 (2026-05-01)
          expect(aggregate.items.first.id, 'm2');
          expect(aggregate.summariesByVehicleId.keys, {'v1', 'v2'});
        });
      },
    );

    test(
      'camino de error — propaga el error si falla la consulta de vehículos',
      () async {
        const error = DomainException(message: 'No se pudo consultar vehículos');
        when(
          () => mockVehicleRepository.getMyVehicles(),
        ).thenAnswer((_) async => const Left(error));

        final result = await repository.getMaintenancesByUserId();

        expect(result.isLeft(), isTrue);
        result.fold((left) => expect(left, error), (_) => fail('Expected Left'));
      },
    );

    test(
      'camino de error — propaga el error si falla un vehículo individual',
      () async {
        when(
          () => mockVehicleRepository.getMyVehicles(),
        ).thenAnswer((_) async => const Right([vehicle1, vehicle2]));
        when(
          () => mockService.getByVehicleId('v1', filter: null),
        ).thenAnswer((_) async => responseFor(dtoV1));
        when(
          () => mockService.getByVehicleId('v2', filter: null),
        ).thenThrow(_dioException());

        final result = await repository.getMaintenancesByUserId();

        expect(result.isLeft(), isTrue);
      },
    );
  });

  group('addMaintenance', () {
    final maintenance = MaintenanceModel(
      vehicleId: 'v1',
      type: MaintenanceType.oilChange,
      mode: MaintenanceMode.completed,
      serviceDate: DateTime(2026, 6, 1),
      odometerAtService: 12000,
    );

    test('camino feliz — retorna la lista de registros creados', () async {
      when(
        () => mockService.create('v1', any()),
      ).thenAnswer((_) async => CreateMaintenanceResponseDto(created: [dtoV1]));

      final result = await repository.addMaintenance(maintenance, 5000);

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right'),
        (list) => expect(list.single.id, 'm1'),
      );
    });

    test('sin vehicleId — retorna Left sin llamar al servicio', () async {
      final maintenanceWithoutVehicle = MaintenanceModel(
        type: MaintenanceType.oilChange,
        mode: MaintenanceMode.completed,
      );

      final result = await repository.addMaintenance(
        maintenanceWithoutVehicle,
        null,
      );

      expect(result.isLeft(), isTrue);
      verifyNever(() => mockService.create(any(), any()));
    });

    test('camino de error — DioException retorna Left', () async {
      when(
        () => mockService.create('v1', any()),
      ).thenThrow(_dioException());

      final result = await repository.addMaintenance(maintenance, null);

      expect(result.isLeft(), isTrue);
    });
  });

  group('updateMaintenance', () {
    final maintenance = MaintenanceModel(
      id: 'm1',
      vehicleId: 'v1',
      type: MaintenanceType.oilChange,
      mode: MaintenanceMode.completed,
      serviceDate: DateTime(2026, 6, 1),
    );

    test('camino feliz — retorna el registro actualizado', () async {
      when(
        () => mockService.update('v1', 'm1', any()),
      ).thenAnswer((_) async => dtoV1);

      final result = await repository.updateMaintenance(maintenance);

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected Right'), (data) => expect(data.id, 'm1'));
    });

    test('sin vehicleId o id — retorna Left sin llamar al servicio', () async {
      final maintenanceWithoutId = MaintenanceModel(
        vehicleId: 'v1',
        type: MaintenanceType.oilChange,
        mode: MaintenanceMode.completed,
      );

      final result = await repository.updateMaintenance(maintenanceWithoutId);

      expect(result.isLeft(), isTrue);
      verifyNever(() => mockService.update(any(), any(), any()));
    });

    test('camino de error — DioException retorna Left', () async {
      when(
        () => mockService.update('v1', 'm1', any()),
      ).thenThrow(_dioException());

      final result = await repository.updateMaintenance(maintenance);

      expect(result.isLeft(), isTrue);
    });
  });

  group('deleteMaintenance', () {
    final maintenance = MaintenanceModel(
      id: 'm1',
      vehicleId: 'v1',
      type: MaintenanceType.oilChange,
      mode: MaintenanceMode.completed,
    );

    test('camino feliz — retorna Right(Nothing)', () async {
      when(() => mockService.delete('v1', 'm1')).thenAnswer((_) async {});

      final result = await repository.deleteMaintenance(maintenance);

      expect(result.isRight(), isTrue);
      verify(() => mockService.delete('v1', 'm1')).called(1);
    });

    test('sin vehicleId o id — retorna Left sin llamar al servicio', () async {
      final maintenanceWithoutId = MaintenanceModel(
        vehicleId: 'v1',
        type: MaintenanceType.oilChange,
        mode: MaintenanceMode.completed,
      );

      final result = await repository.deleteMaintenance(maintenanceWithoutId);

      expect(result.isLeft(), isTrue);
      verifyNever(() => mockService.delete(any(), any()));
    });

    test('camino de error — DioException retorna Left', () async {
      when(() => mockService.delete('v1', 'm1')).thenThrow(_dioException());

      final result = await repository.deleteMaintenance(maintenance);

      expect(result.isLeft(), isTrue);
    });
  });
}
