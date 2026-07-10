import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/tecnomecanica/domain/models/tecnomecanica_model.dart';
import 'package:rideglory/features/tecnomecanica/domain/repository/tecnomecanica_repository.dart';
import 'package:rideglory/features/tecnomecanica/domain/usecases/get_tecnomecanica_usecase.dart';

class MockTecnomecanicaRepository extends Mock
    implements TecnomecanicaRepository {}

void main() {
  late MockTecnomecanicaRepository mockRepository;
  late GetTecnomecanicaUseCase useCase;

  setUp(() {
    mockRepository = MockTecnomecanicaRepository();
    useCase = GetTecnomecanicaUseCase(mockRepository);
  });

  final tecnomecanica = TecnomecanicaModel(
    id: 'rtm-1',
    vehicleId: 'v1',
    cdaName: 'CDA Bogotá',
    startDate: DateTime(2026, 1, 1),
    expiryDate: DateTime(2027, 1, 1),
  );

  test('camino feliz — retorna el RTM del vehículo', () async {
    when(
      () => mockRepository.getTecnomecanica('v1'),
    ).thenAnswer((_) async => Right(tecnomecanica));

    final result = await useCase('v1');

    expect(result.isRight(), isTrue);
    result.fold(
      (_) => fail('Expected Right'),
      (data) => expect(data?.id, 'rtm-1'),
    );
  });

  test('vehículo sin RTM — retorna Right(null)', () async {
    when(
      () => mockRepository.getTecnomecanica('v1'),
    ).thenAnswer((_) async => const Right(null));

    final result = await useCase('v1');

    expect(result.isRight(), isTrue);
    result.fold((_) => fail('Expected Right'), (data) => expect(data, isNull));
  });

  test('camino de error — propaga el Left del repositorio', () async {
    const error = DomainException(message: 'No se pudo cargar el RTM');
    when(
      () => mockRepository.getTecnomecanica('v1'),
    ).thenAnswer((_) async => const Left(error));

    final result = await useCase('v1');

    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) => expect(failure, error),
      (_) => fail('Expected Left'),
    );
  });
}
