import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/soat/domain/repository/soat_repository.dart';
import 'package:rideglory/features/soat/domain/usecases/delete_soat_usecase.dart';

class MockSoatRepository extends Mock implements SoatRepository {}

void main() {
  late MockSoatRepository mockRepository;
  late DeleteSoatUseCase useCase;

  setUp(() {
    mockRepository = MockSoatRepository();
    useCase = DeleteSoatUseCase(mockRepository);
  });

  test('camino feliz — delega el vehicleId en el repository y retorna Right(unit)', () async {
    when(() => mockRepository.deleteSoat('vehicle-1')).thenAnswer(
      (_) async => const Right(unit),
    );

    final result = await useCase('vehicle-1');

    expect(result.isRight(), isTrue);
    result.fold((_) => fail('Expected Right'), (value) {
      expect(value, unit);
    });
    verify(() => mockRepository.deleteSoat('vehicle-1')).called(1);
  });

  test('camino de error — retorna Left cuando el repository falla', () async {
    when(() => mockRepository.deleteSoat('vehicle-1')).thenAnswer(
      (_) async =>
          const Left(DomainException(message: 'No se pudo eliminar el SOAT')),
    );

    final result = await useCase('vehicle-1');

    expect(result.isLeft(), isTrue);
    result.fold(
      (error) => expect(error.message, 'No se pudo eliminar el SOAT'),
      (_) => fail('Expected Left'),
    );
  });
}
