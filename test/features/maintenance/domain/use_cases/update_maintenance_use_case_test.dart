import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/domain/repository/maintenance_repository.dart';
import 'package:rideglory/features/maintenance/domain/use_cases/update_maintenance_use_case.dart';

class MockMaintenanceRepository extends Mock implements MaintenanceRepository {}

class FakeMaintenanceModel extends Fake implements MaintenanceModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeMaintenanceModel());
  });

  late MockMaintenanceRepository mockRepository;
  late UpdateMaintenanceUseCase useCase;

  final maintenance = MaintenanceModel(
    id: 'm1',
    vehicleId: 'v1',
    type: MaintenanceType.brakeCheck,
    mode: MaintenanceMode.completed,
    serviceDate: DateTime(2026, 6, 1),
  );

  setUp(() {
    mockRepository = MockMaintenanceRepository();
    useCase = UpdateMaintenanceUseCase(mockRepository);
  });

  test('camino feliz — retorna el registro actualizado', () async {
    final updated = maintenance.copyWith(workshop: 'Taller Central');
    when(
      () => mockRepository.updateMaintenance(maintenance),
    ).thenAnswer((_) async => Right(updated));

    final result = await useCase(maintenance);

    expect(result.isRight(), isTrue);
    result.fold((_) => fail('Expected Right'), (data) => expect(data, updated));
    verify(() => mockRepository.updateMaintenance(maintenance)).called(1);
  });

  test('camino de error — propaga el DomainException del repositorio', () async {
    const error = DomainException(message: 'No se pudo actualizar');
    when(
      () => mockRepository.updateMaintenance(maintenance),
    ).thenAnswer((_) async => const Left(error));

    final result = await useCase(maintenance);

    expect(result.isLeft(), isTrue);
    result.fold((left) => expect(left, error), (_) => fail('Expected Left'));
  });
}
