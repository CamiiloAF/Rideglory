import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/soat/domain/models/soat_model.dart';
import 'package:rideglory/features/soat/domain/repository/soat_repository.dart';
import 'package:rideglory/features/soat/domain/usecases/get_soat_usecase.dart';

class MockSoatRepository extends Mock implements SoatRepository {}

void main() {
  late MockSoatRepository mockRepository;
  late GetSoatUseCase useCase;

  setUp(() {
    mockRepository = MockSoatRepository();
    useCase = GetSoatUseCase(mockRepository);
  });

  final soat = SoatModel(
    id: 'soat-1',
    vehicleId: 'vehicle-1',
    expiryDate: DateTime(2027, 1, 1),
  );

  test('camino feliz — delega en el repository y retorna Right con el SOAT', () async {
    when(() => mockRepository.getSoat('vehicle-1')).thenAnswer(
      (_) async => Right(soat),
    );

    final result = await useCase('vehicle-1');

    expect(result.isRight(), isTrue);
    result.fold((_) => fail('Expected Right'), (value) {
      expect(value, soat);
    });
    verify(() => mockRepository.getSoat('vehicle-1')).called(1);
  });

  test('retorna Right(null) cuando el vehículo no tiene SOAT registrado', () async {
    when(() => mockRepository.getSoat('vehicle-1')).thenAnswer(
      (_) async => const Right(null),
    );

    final result = await useCase('vehicle-1');

    expect(result.isRight(), isTrue);
    result.fold((_) => fail('Expected Right'), (value) {
      expect(value, isNull);
    });
  });

  test('camino de error — retorna Left cuando el repository falla', () async {
    when(() => mockRepository.getSoat('vehicle-1')).thenAnswer(
      (_) async =>
          const Left(DomainException(message: 'No se pudo cargar el SOAT')),
    );

    final result = await useCase('vehicle-1');

    expect(result.isLeft(), isTrue);
    result.fold(
      (error) => expect(error.message, 'No se pudo cargar el SOAT'),
      (_) => fail('Expected Left'),
    );
  });
}
