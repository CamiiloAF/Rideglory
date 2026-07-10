import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/domain/repository/maintenance_repository.dart';
import 'package:rideglory/features/maintenance/domain/use_cases/add_maintenance_use_case.dart';

class MockMaintenanceRepository extends Mock implements MaintenanceRepository {}

class FakeMaintenanceModel extends Fake implements MaintenanceModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeMaintenanceModel());
  });

  late MockMaintenanceRepository mockRepository;
  late AddMaintenanceUseCase useCase;

  final maintenance = MaintenanceModel(
    vehicleId: 'v1',
    type: MaintenanceType.oilChange,
    mode: MaintenanceMode.completed,
    serviceDate: DateTime(2026, 6, 1),
  );

  setUp(() {
    mockRepository = MockMaintenanceRepository();
    useCase = AddMaintenanceUseCase(mockRepository);
  });

  test('camino feliz — retorna la lista de registros creados', () async {
    final created = [maintenance.copyWith(id: 'm1')];
    when(
      () => mockRepository.addMaintenance(maintenance, 5000),
    ).thenAnswer((_) async => Right(created));

    final result = await useCase(maintenance, nextKmInterval: 5000);

    expect(result.isRight(), isTrue);
    result.fold(
      (_) => fail('Expected Right'),
      (list) => expect(list, created),
    );
    verify(() => mockRepository.addMaintenance(maintenance, 5000)).called(1);
  });

  test('camino de error — propaga el DomainException del repositorio', () async {
    const error = DomainException(message: 'No se pudo crear');
    when(
      () => mockRepository.addMaintenance(maintenance, null),
    ).thenAnswer((_) async => const Left(error));

    final result = await useCase(maintenance);

    expect(result.isLeft(), isTrue);
    result.fold((left) => expect(left, error), (_) => fail('Expected Left'));
  });
}
