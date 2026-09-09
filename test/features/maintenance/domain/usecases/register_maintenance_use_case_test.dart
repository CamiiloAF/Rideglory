import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/maintenance/domain/maintenance.dart';
import 'package:rideglory/features/maintenance/domain/maintenance_repository.dart';
import 'package:rideglory/features/maintenance/domain/register_maintenance_params.dart';
import 'package:rideglory/features/maintenance/domain/usecases/register_maintenance_use_case.dart';

class _MockMaintenanceRepository extends Mock
    implements MaintenanceRepository {}

void main() {
  late _MockMaintenanceRepository repository;
  late RegisterMaintenanceUseCase useCase;

  setUpAll(() {
    registerFallbackValue(
      RegisterMaintenanceParams(
        vehicleId: 'v1',
        type: 'Cambio de aceite',
        serviceDate: DateTime(2026),
        odometer: 0,
      ),
    );
  });

  setUp(() {
    repository = _MockMaintenanceRepository();
    useCase = RegisterMaintenanceUseCase(repository);
  });

  final params = RegisterMaintenanceParams(
    vehicleId: 'v1',
    type: 'Cambio de aceite',
    serviceDate: DateTime(2026, 8, 12),
    odometer: 18450,
  );

  test(
    'delegates to the repository and returns its result on success',
    () async {
      final maintenance = Maintenance(
        id: 'm1',
        vehicleId: 'v1',
        vehicleDisplayName: 'Yamaha MT-03',
        type: 'Cambio de aceite',
        serviceDate: params.serviceDate,
        odometer: params.odometer,
      );
      when(
        () => repository.registerMaintenance(params),
      ).thenAnswer((_) async => Right(maintenance));

      final result = await useCase(params);

      expect(result, Right(maintenance));
      verify(() => repository.registerMaintenance(params)).called(1);
    },
  );

  test('propagates a DomainException on failure', () async {
    const error = DomainException(message: 'postgrest_error: 42501');
    when(
      () => repository.registerMaintenance(params),
    ).thenAnswer((_) async => const Left(error));

    final result = await useCase(params);

    expect(result, const Left(error));
  });
}
