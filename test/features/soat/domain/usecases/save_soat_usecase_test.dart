import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/soat/domain/models/soat_model.dart';
import 'package:rideglory/features/soat/domain/repository/soat_repository.dart';
import 'package:rideglory/features/soat/domain/usecases/save_soat_usecase.dart';

class MockSoatRepository extends Mock implements SoatRepository {}

void main() {
  late MockSoatRepository mockRepository;
  late SaveSoatUseCase useCase;

  setUp(() {
    mockRepository = MockSoatRepository();
    useCase = SaveSoatUseCase(mockRepository);
  });

  final soat = SoatModel(
    id: 'soat-1',
    vehicleId: 'vehicle-1',
    expiryDate: DateTime(2027, 1, 1),
    insurer: 'Seguros XX',
  );

  test('camino feliz — delega vehicleId y soat al repository y retorna Right', () async {
    when(
      () => mockRepository.saveSoat(vehicleId: 'vehicle-1', soat: soat),
    ).thenAnswer((_) async => Right(soat));

    final result = await useCase(vehicleId: 'vehicle-1', soat: soat);

    expect(result.isRight(), isTrue);
    result.fold((_) => fail('Expected Right'), (value) {
      expect(value, soat);
    });
    verify(
      () => mockRepository.saveSoat(vehicleId: 'vehicle-1', soat: soat),
    ).called(1);
  });

  test('camino de error — retorna Left cuando el repository falla', () async {
    when(
      () => mockRepository.saveSoat(vehicleId: 'vehicle-1', soat: soat),
    ).thenAnswer(
      (_) async =>
          const Left(DomainException(message: 'No se pudo guardar el SOAT')),
    );

    final result = await useCase(vehicleId: 'vehicle-1', soat: soat);

    expect(result.isLeft(), isTrue);
    result.fold(
      (error) => expect(error.message, 'No se pudo guardar el SOAT'),
      (_) => fail('Expected Left'),
    );
  });
}
