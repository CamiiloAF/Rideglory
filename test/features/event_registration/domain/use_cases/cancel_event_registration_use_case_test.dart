import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/nothing.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/event_registration/domain/repository/event_registration_repository.dart';
import 'package:rideglory/features/event_registration/domain/use_cases/cancel_event_registration_use_case.dart';

class MockEventRegistrationRepository extends Mock
    implements EventRegistrationRepository {}

void main() {
  late MockEventRegistrationRepository mockRepository;
  late CancelEventRegistrationUseCase useCase;

  setUp(() {
    mockRepository = MockEventRegistrationRepository();
    useCase = CancelEventRegistrationUseCase(mockRepository);
  });

  group('CancelEventRegistrationUseCase', () {
    test(
      'delegates to repository.cancelRegistration and returns Right(Nothing) on success',
      () async {
        when(
          () => mockRepository.cancelRegistration('reg-1'),
        ).thenAnswer((_) async => const Right(Nothing()));

        final result = await useCase('reg-1');

        expect(result, const Right(Nothing()));
        verify(() => mockRepository.cancelRegistration('reg-1')).called(1);
      },
    );

    test('returns Left when repository fails', () async {
      when(() => mockRepository.cancelRegistration('reg-1')).thenAnswer(
        (_) async =>
            const Left(DomainException(message: 'No se pudo cancelar')),
      );

      final result = await useCase('reg-1');

      expect(result.isLeft(), isTrue);
      result.fold(
        (error) => expect(error.message, 'No se pudo cancelar'),
        (_) => fail('Expected Left'),
      );
    });
  });
}
