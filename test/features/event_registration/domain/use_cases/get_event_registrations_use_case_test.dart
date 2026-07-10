import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/event_registration/domain/repository/event_registration_repository.dart';
import 'package:rideglory/features/event_registration/domain/use_cases/get_event_registrations_use_case.dart';

class MockEventRegistrationRepository extends Mock
    implements EventRegistrationRepository {}

final _registration = EventRegistrationModel(
  id: 'reg-1',
  eventId: 'event-1',
  eventName: 'Ruta Mágica',
  userId: 'user-1',
  fullName: 'Carlos García',
  identificationNumber: '123456789',
  birthDate: DateTime(1990, 5, 15),
  phone: '3001234567',
  email: 'carlos@example.com',
  residenceCity: 'Medellín',
  eps: 'Sura',
  bloodType: BloodType.oPositive,
  emergencyContactName: 'Ana García',
  emergencyContactPhone: '3009876543',
);

void main() {
  late MockEventRegistrationRepository mockRepository;
  late GetEventRegistrationsUseCase useCase;

  setUp(() {
    mockRepository = MockEventRegistrationRepository();
    useCase = GetEventRegistrationsUseCase(mockRepository);
  });

  group('GetEventRegistrationsUseCase', () {
    test(
      'delegates to repository.getRegistrationsByEvent and returns Right list on success',
      () async {
        when(
          () => mockRepository.getRegistrationsByEvent('event-1'),
        ).thenAnswer((_) async => Right([_registration]));

        final result = await useCase('event-1');

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Expected Right'), (value) {
          expect(value, [_registration]);
        });
        verify(
          () => mockRepository.getRegistrationsByEvent('event-1'),
        ).called(1);
      },
    );

    test('returns Left when repository fails', () async {
      when(() => mockRepository.getRegistrationsByEvent('event-1')).thenAnswer(
        (_) async =>
            const Left(DomainException(message: 'No autorizado')),
      );

      final result = await useCase('event-1');

      expect(result.isLeft(), isTrue);
      result.fold(
        (error) => expect(error.message, 'No autorizado'),
        (_) => fail('Expected Left'),
      );
    });
  });
}
