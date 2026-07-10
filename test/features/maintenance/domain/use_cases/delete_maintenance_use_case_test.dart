import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/nothing.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/domain/repository/maintenance_repository.dart';
import 'package:rideglory/features/maintenance/domain/use_cases/delete_maintenance_use_case.dart';

class MockMaintenanceRepository extends Mock implements MaintenanceRepository {}

class FakeMaintenanceModel extends Fake implements MaintenanceModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeMaintenanceModel());
  });

  late MockMaintenanceRepository mockRepository;
  late DeleteMaintenanceUseCase useCase;

  final maintenance = MaintenanceModel(
    id: 'm1',
    vehicleId: 'v1',
    type: MaintenanceType.tireChange,
    mode: MaintenanceMode.completed,
    serviceDate: DateTime(2026, 6, 1),
  );

  setUp(() {
    mockRepository = MockMaintenanceRepository();
    useCase = DeleteMaintenanceUseCase(mockRepository);
  });

  test('camino feliz — retorna Right(Nothing)', () async {
    when(
      () => mockRepository.deleteMaintenance(maintenance),
    ).thenAnswer((_) async => const Right(Nothing()));

    final result = await useCase(maintenance);

    expect(result.isRight(), isTrue);
    verify(() => mockRepository.deleteMaintenance(maintenance)).called(1);
  });

  test('camino de error — propaga el DomainException del repositorio', () async {
    const error = DomainException(message: 'No se pudo borrar');
    when(
      () => mockRepository.deleteMaintenance(maintenance),
    ).thenAnswer((_) async => const Left(error));

    final result = await useCase(maintenance);

    expect(result.isLeft(), isTrue);
    result.fold((left) => expect(left, error), (_) => fail('Expected Left'));
  });
}
