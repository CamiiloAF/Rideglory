import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/events/domain/repository/event_cover_repository.dart';
import 'package:rideglory/features/events/domain/use_cases/get_generate_cover_use_case.dart';

class MockEventCoverRepository extends Mock
    implements EventCoverRepository {}

void main() {
  group('GetGenerateCoverUseCase', () {
    late GetGenerateCoverUseCase useCase;
    late MockEventCoverRepository mockRepository;

    setUp(() {
      mockRepository = MockEventCoverRepository();
      useCase = GetGenerateCoverUseCase(mockRepository);
    });

    group('generateCover', () {
      const title = 'Moto Tour 2026';
      const eventType = 'road_trip';
      const city = 'Medellín';
      const imageUrl = 'https://images.unsplash.com/photo-123456?auto=format&fit=crop&w=500';

      // TC-4-1: Happy path — repository returns imageUrl
      test(
        'TC-4-1: Happy path — emits Right(imageUrl) when repository succeeds',
        () async {
          // Arrange
          when(
            () => mockRepository.generateCover(
              title: any(named: 'title'),
              eventType: any(named: 'eventType'),
              city: any(named: 'city'),
            ),
          ).thenAnswer((_) async => const Right(imageUrl));

          // Act
          final result = await useCase(
            title: title,
            eventType: eventType,
            city: city,
          );

          // Assert
          expect(result, const Right(imageUrl));
          verify(
            () => mockRepository.generateCover(
              title: title,
              eventType: eventType,
              city: city,
            ),
          ).called(1);
        },
      );

      // TC-4-2: Error path — repository returns DomainException (503 from backend)
      test(
        'TC-4-2: Error handling — emits Left(DomainException) when repository fails',
        () async {
          // Arrange
          const exception = DomainException(
            message: 'No pudimos generar la portada. Sube tu propia imagen.',
          );
          when(
            () => mockRepository.generateCover(
              title: any(named: 'title'),
              eventType: any(named: 'eventType'),
              city: any(named: 'city'),
            ),
          ).thenAnswer((_) async => const Left(exception));

          // Act
          final result = await useCase(
            title: title,
            eventType: eventType,
            city: city,
          );

          // Assert
          expect(result, const Left(exception));
          verify(
            () => mockRepository.generateCover(
              title: title,
              eventType: eventType,
              city: city,
            ),
          ).called(1);
        },
      );
    });
  });
}
