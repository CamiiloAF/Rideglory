import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_list_summary.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_user_list_aggregate.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_vehicle_list_result.dart';
import 'package:rideglory/features/maintenance/domain/repository/maintenance_repository.dart';
import 'package:rideglory/features/maintenance/domain/use_cases/get_maintenance_list_use_case.dart';

class MockMaintenanceRepository extends Mock implements MaintenanceRepository {}

void main() {
  late MockMaintenanceRepository mockRepository;
  late GetMaintenanceListUseCase useCase;

  final maintenanceItem = MaintenanceModel(
    id: 'm1',
    vehicleId: 'v1',
    type: MaintenanceType.oilChange,
    mode: MaintenanceMode.completed,
    serviceDate: DateTime(2026, 5, 1),
  );

  setUp(() {
    mockRepository = MockMaintenanceRepository();
    useCase = GetMaintenanceListUseCase(mockRepository);
  });

  group('con vehicleId', () {
    test(
      'camino feliz — consulta solo ese vehículo y envuelve el summary en el mapa',
      () async {
        final vehicleResult = MaintenanceVehicleListResult(
          items: [maintenanceItem],
          summary: const MaintenanceListSummary(lastServiceMileage: 12000),
        );
        when(
          () => mockRepository.getMaintenancesByVehicleId(
            'v1',
            types: any(named: 'types'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer((_) async => Right(vehicleResult));

        final result = await useCase.execute(vehicleId: 'v1');

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Expected Right'), (aggregate) {
          expect(aggregate.items, [maintenanceItem]);
          expect(aggregate.summariesByVehicleId['v1']?.lastServiceMileage, 12000);
        });
        verifyNever(() => mockRepository.getMaintenancesByUserId());
      },
    );

    test('camino de error — propaga el DomainException', () async {
      const error = DomainException(message: 'No se pudo consultar');
      when(
        () => mockRepository.getMaintenancesByVehicleId(
          'v1',
          types: any(named: 'types'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).thenAnswer((_) async => const Left(error));

      final result = await useCase.execute(vehicleId: 'v1');

      expect(result.isLeft(), isTrue);
      result.fold((left) => expect(left, error), (_) => fail('Expected Left'));
    });
  });

  group('sin vehicleId', () {
    test('camino feliz — delega en getMaintenancesByUserId', () async {
      final aggregate = MaintenanceUserListAggregate(
        items: [maintenanceItem],
        summariesByVehicleId: {
          'v1': const MaintenanceListSummary(lastServiceMileage: 12000),
        },
      );
      when(
        () => mockRepository.getMaintenancesByUserId(
          types: any(named: 'types'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).thenAnswer((_) async => Right(aggregate));

      final result = await useCase.execute();

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected Right'), (data) => expect(data, aggregate));
      verifyNever(() => mockRepository.getMaintenancesByVehicleId(any()));
    });

    test('camino de error — propaga el DomainException', () async {
      const error = DomainException(message: 'No se pudo consultar');
      when(
        () => mockRepository.getMaintenancesByUserId(
          types: any(named: 'types'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).thenAnswer((_) async => const Left(error));

      final result = await useCase.execute();

      expect(result.isLeft(), isTrue);
      result.fold((left) => expect(left, error), (_) => fail('Expected Left'));
    });
  });
}
