import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/tecnomecanica/domain/models/tecnomecanica_model.dart';
import 'package:rideglory/features/tecnomecanica/domain/repository/tecnomecanica_repository.dart';
import 'package:rideglory/features/tecnomecanica/domain/usecases/save_tecnomecanica_usecase.dart';

class MockTecnomecanicaRepository extends Mock
    implements TecnomecanicaRepository {}

void main() {
  late MockTecnomecanicaRepository mockRepository;
  late SaveTecnomecanicaUseCase useCase;

  setUp(() {
    mockRepository = MockTecnomecanicaRepository();
    useCase = SaveTecnomecanicaUseCase(mockRepository);
  });

  final tecnomecanica = TecnomecanicaModel(
    id: '',
    vehicleId: 'v1',
    cdaName: 'CDA Bogotá',
    startDate: DateTime(2026, 1, 1),
    expiryDate: DateTime(2027, 1, 1),
  );

  test('camino feliz — delega en el repositorio y retorna el modelo guardado', () async {
    final saved = tecnomecanica.copyWith(id: 'rtm-1');
    when(
      () => mockRepository.saveTecnomecanica(
        vehicleId: 'v1',
        tecnomecanica: tecnomecanica,
      ),
    ).thenAnswer((_) async => Right(saved));

    final result = await useCase(vehicleId: 'v1', tecnomecanica: tecnomecanica);

    expect(result.isRight(), isTrue);
    result.fold(
      (_) => fail('Expected Right'),
      (data) => expect(data.id, 'rtm-1'),
    );
    verify(
      () => mockRepository.saveTecnomecanica(
        vehicleId: 'v1',
        tecnomecanica: tecnomecanica,
      ),
    ).called(1);
  });

  test('camino de error — propaga el Left del repositorio', () async {
    const error = DomainException(message: 'No se pudo guardar');
    when(
      () => mockRepository.saveTecnomecanica(
        vehicleId: 'v1',
        tecnomecanica: tecnomecanica,
      ),
    ).thenAnswer((_) async => const Left(error));

    final result = await useCase(vehicleId: 'v1', tecnomecanica: tecnomecanica);

    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) => expect(failure, error),
      (_) => fail('Expected Left'),
    );
  });
}
