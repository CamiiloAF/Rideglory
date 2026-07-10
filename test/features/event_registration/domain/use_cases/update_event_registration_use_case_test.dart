import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/event_registration/domain/repository/event_registration_repository.dart';
import 'package:rideglory/features/event_registration/domain/use_cases/update_event_registration_use_case.dart';

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
  late UpdateEventRegistrationUseCase useCase;

  setUp(() {
    mockRepository = MockEventRegistrationRepository();
    useCase = UpdateEventRegistrationUseCase(mockRepository);
  });

  group('UpdateEventRegistrationUseCase', () {
    test(
      'delegates to repository.updateRegistration and returns Right on success',
      () async {
        when(
          () => mockRepository.updateRegistration(
            _registration,
            saveToProfile: false,
          ),
        ).thenAnswer((_) async => Right(_registration));

        final result = await useCase(_registration);

        expect(result, Right(_registration));
        verify(
          () => mockRepository.updateRegistration(
            _registration,
            saveToProfile: false,
          ),
        ).called(1);
      },
    );

    test('forwards saveToProfile flag to the repository', () async {
      when(
        () => mockRepository.updateRegistration(
          _registration,
          saveToProfile: true,
        ),
      ).thenAnswer((_) async => Right(_registration));

      await useCase(_registration, saveToProfile: true);

      verify(
        () => mockRepository.updateRegistration(
          _registration,
          saveToProfile: true,
        ),
      ).called(1);
    });

    test('returns Left when repository fails', () async {
      when(
        () => mockRepository.updateRegistration(
          _registration,
          saveToProfile: false,
        ),
      ).thenAnswer(
        (_) async =>
            const Left(DomainException(message: 'Error al actualizar')),
      );

      final result = await useCase(_registration);

      expect(result.isLeft(), isTrue);
      result.fold(
        (error) => expect(error.message, 'Error al actualizar'),
        (_) => fail('Expected Left'),
      );
    });
  });
}
