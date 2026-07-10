import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_list_summary.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_vehicle_list_result.dart';
import 'package:rideglory/features/maintenance/domain/repository/maintenance_repository.dart';
import 'package:rideglory/features/maintenance/domain/use_cases/get_maintenances_by_vehicle_id_use_case.dart';

class MockMaintenanceRepository extends Mock implements MaintenanceRepository {}

void main() {
  late MockMaintenanceRepository mockRepository;
  late GetMaintenancesByVehicleIdUseCase useCase;

  setUp(() {
    mockRepository = MockMaintenanceRepository();
    useCase = GetMaintenancesByVehicleIdUseCase(mockRepository);
  });

  test('camino feliz — retorna items y summary del vehículo', () async {
    final maintenanceItem = MaintenanceModel(
      id: 'm1',
      vehicleId: 'v1',
      type: MaintenanceType.oilChange,
      mode: MaintenanceMode.completed,
      serviceDate: DateTime(2026, 5, 1),
    );
    final expected = MaintenanceVehicleListResult(
      items: [maintenanceItem],
      summary: const MaintenanceListSummary(lastServiceMileage: 12000),
    );
    when(
      () => mockRepository.getMaintenancesByVehicleId('v1'),
    ).thenAnswer((_) async => Right(expected));

    final result = await useCase.execute('v1');

    expect(result.isRight(), isTrue);
    result.fold((_) => fail('Expected Right'), (data) => expect(data, expected));
    verify(() => mockRepository.getMaintenancesByVehicleId('v1')).called(1);
  });

  test('camino de error — propaga el DomainException del repositorio', () async {
    const error = DomainException(message: 'No se pudo consultar');
    when(
      () => mockRepository.getMaintenancesByVehicleId('v1'),
    ).thenAnswer((_) async => const Left(error));

    final result = await useCase.execute('v1');

    expect(result.isLeft(), isTrue);
    result.fold((left) => expect(left, error), (_) => fail('Expected Left'));
  });
}
