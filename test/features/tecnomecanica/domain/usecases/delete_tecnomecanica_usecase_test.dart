import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/tecnomecanica/domain/repository/tecnomecanica_repository.dart';
import 'package:rideglory/features/tecnomecanica/domain/usecases/delete_tecnomecanica_usecase.dart';

class MockTecnomecanicaRepository extends Mock
    implements TecnomecanicaRepository {}

void main() {
  late MockTecnomecanicaRepository mockRepository;
  late DeleteTecnomecanicaUseCase useCase;

  setUp(() {
    mockRepository = MockTecnomecanicaRepository();
    useCase = DeleteTecnomecanicaUseCase(mockRepository);
  });

  test('camino feliz — delega en el repositorio y retorna Right(unit)', () async {
    when(
      () => mockRepository.deleteTecnomecanica('v1'),
    ).thenAnswer((_) async => const Right(unit));

    final result = await useCase('v1');

    expect(result.isRight(), isTrue);
    verify(() => mockRepository.deleteTecnomecanica('v1')).called(1);
  });

  test('camino de error — propaga el Left del repositorio', () async {
    const error = DomainException(message: 'No se pudo eliminar el RTM');
    when(
      () => mockRepository.deleteTecnomecanica('v1'),
    ).thenAnswer((_) async => const Left(error));

    final result = await useCase('v1');

    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) => expect(failure, error),
      (_) => fail('Expected Left'),
    );
  });
}
